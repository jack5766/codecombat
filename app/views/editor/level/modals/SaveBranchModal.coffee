ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/modal/save-branch-modal'
DeltaView = require 'views/editor/DeltaView'
deltasLib = require 'core/deltas'
Branch = require 'models/Branch'
Branches = require 'collections/Branches'
LevelComponents = require 'collections/LevelComponents'
LevelSystems = require 'collections/LevelSystems'


module.exports = class SaveBranchModal extends ModalView
  id: 'save-branch-modal'
  template: template
  modalWidthPercent: 99
  events:
    'click #save-branch-btn': 'onClickSaveBranchButton'
    'click #branches-list-group .list-group-item': 'onClickBranch'
    

  initialize: (options = {}) ->
    # Should be given all loaded, up to date systems and components with existing changes
    { @components, @systems } = options
    
    # Create a list of components and systems we'll be saving a branch for
    @componentsWithChanges = new LevelComponents(@components.filter((c) -> c.hasLocalChanges()))
    @systemsWithChanges = new LevelSystems(@systems.filter((c) -> c.hasLocalChanges()))
    
    # Load existing branches
    @branches = new Branches()
    @branches.fetch({url: '/db/branches'})
    .then(=>
      
      # Load any patch target we don't already have
      fetches = []
      for branch in @branches.models
        for patch in branch.get('patches')
          collection = if patch.target.collection is 'level_component' then @components else @systems
          model = collection.get(patch.target.id)
          if not model
            model = new collection.model({ _id: patch.target.id })
            fetches.push(model.fetch())
            model.once 'sync', -> @markToRevert()
            collection.add(model)
      return $.when(fetches...)
      
    ).then(=>
      
      # Go through each branch and make clones of patch targets, with patches applied, so we can show the deltas
      for branch in @branches.models
        branch.components = new Backbone.Collection()
        branch.systems = new Backbone.Collection()
        for patch in branch.get('patches')
          patch.id = _.uniqueId()
          if patch.target.collection is 'level_component'
            allModels = @components
            changedModels = branch.components
          else
            allModels = @systems
            changedModels = branch.systems
          model = allModels.get(patch.target.id).clone(false)
          model.markToRevert()
          model.applyDelta(patch.delta)
          changedModels.add(model)
      @render()
    )

  afterRender: ->
    super()
    
    # insert all the Delta views for the systems/components which will form the branch
    changeEls = @$el.find('.component-changes-stub')
    for changeEl in changeEls
      componentId = $(changeEl).data('component-id')
      component = @componentsWithChanges.find((c) -> c.id is componentId)
      @insertDeltaView(component, changeEl)

    changeEls = @$el.find('.system-changes-stub')
    for changeEl in changeEls
      systemId = $(changeEl).data('system-id')
      system = @systemsWithChanges.find((c) -> c.id is systemId)
      
  insertDeltaView: (model, changeEl, headModel) ->
    try
      deltaView = new DeltaView({model: model, headModel, skipPaths: deltasLib.DOC_SKIP_PATHS})
      @insertSubView(deltaView, $(changeEl))
      return deltaView
    catch e
      console.error 'Couldn\'t create delta view:', e
        
  renderSelectedBranch: ->
    # insert delta subviews for the selected branch, including the 'headComponent' which shows
    # what, if any, conflicts the existing branch has with the client's local changes
    
    @removeSubView(view) for view in @selectedBranchDeltaViews if @selectedBranchDeltaViews
    @selectedBranchDeltaViews = []
    @renderSelectors('#selected-branch-col')
    changeEls = @$el.find('#selected-branch-col .component-changes-stub')
    for changeEl in changeEls
      componentId = $(changeEl).data('component-id')
      component = @selectedBranch.components.get(componentId)
      targetComponent = @components.find((c) -> c.get('original') is component.get('original') and c.get('version').isLatestMajor)
      preBranchSave = component.clone()
      preBranchSave.markToRevert()
      componentDiff = targetComponent.clone()
      preBranchSave.set(componentDiff.attributes)
      @selectedBranchDeltaViews.push(@insertDeltaView(preBranchSave, changeEl))

    changeEls = @$el.find('#selected-branch-col .system-changes-stub')
    for changeEl in changeEls
      systemId = $(changeEl).data('system-id')
      system = @selectedBranch.systems.get(systemId)
      targetSystem = @systems.find((c) -> c.get('original') is system.get('original') and c.get('version').isLatestMajor)
      headSystem = system.clone(false)
      headSystem.markToRevert()
      headSystem.set(targetSystem.attributes)
      @selectedBranchDeltaViews.push(@insertDeltaView(system, changeEl, headSystem))

  onClickBranch: (e) ->
    $(e.currentTarget).closest('.list-group').find('.active').removeClass('active')
    $(e.currentTarget).addClass('active')
    branchCid = $(e.currentTarget).data('branch-cid')
    @selectedBranch = if branchCid then @branches.get(branchCid) else null
    @renderSelectedBranch()

  onClickSaveBranchButton: (e) ->
    selectedBranch = @$('#branches-list-group .active')
    branchCid = selectedBranch.data('branch-cid')
    if branchCid
      branch = @branches.get(branchCid)
    else
      name = selectedBranch.find('input').val()
      if not name
        return noty text: 'Name required', layout: 'topCenter', type: 'error', killer: false
      slug = _.string.slugify(name)
      if @branches.findWhere({slug})
        return noty text: 'Name taken', layout: 'topCenter', type: 'error', killer: false
      branch = new Branch({name})
    
    patches = []
    for component in @componentsWithChanges.models
      patches.push(component.makePatch().toJSON())
    for system in @systemsWithChanges.models
      patches.push(system.makePatch().toJSON())
    branch.set({patches})
    jqxhr = branch.save()
    button = $(e.currentTarget)
    if not jqxhr
      return button.text('Save Failed')
      
    button.attr('disabled', true).text('Saving...')
    Promise.resolve(jqxhr)
    .then =>
      @hide()
    .catch =>
      button.attr('disabled', false).text('Save Failed')
    
