factories = require 'test/app/factories'
SaveBranchModal = require 'views/editor/level/modals/SaveBranchModal'
LevelComponents = require 'collections/LevelComponents'
LevelSystems = require 'collections/LevelSystems'

makeBranch = (attrs={}, {systems, components}) ->
  branch = new Branch(attrs)
  patches = []
  for component in components.models
    patches.push(component.makePatch().toJSON())
  for system in systems.models
    patches.push(system.makePatch().toJSON())
  branch.set({patches})
  return branch

describe 'SaveBranchModal', ->
  it 'saves a new branch with ', (done) ->
    
    # a couple that don't have changes
    component = factories.makeLevelComponent({name: 'Unchanged Component'})
    system = factories.makeLevelSystem({name: 'Unchanged System'})
    
    # a couple with changes
    changedComponent = factories.makeLevelComponent({name: 'Changed Component'})
    changedSystem = factories.makeLevelSystem({name: 'Changed System'})
    changedComponent.markToRevert()
    changedComponent.set('description', 'new description')
    changedSystem.markToRevert()
    changedSystem.set('description', 'also a new description')
    
    # a component with history
    componentV0 = factories.makeLevelComponent({
      name: 'Versioned Component'
      version: {
        major: 0
        minor: 0
        isLatestMajor: false
        isLatestMinor: false
      }
    })
    componentV1 = factories.makeLevelComponent({
      name: 'Versioned Component', 
      original: componentV0.get('original'),
      description:'Recent description change'
      version: {
        major: 0
        minor: 1
        isLatestMajor: true
        isLatestMinor: true
      }
    })
    componentV0Changed = componentV0.clone()
    componentV0Changed.markToRevert()
    componentV0Changed.set({name: 'Unconflicting change', description: 'Conflicting change'})
    
    modal = new SaveBranchModal({ 
      components: new LevelComponents([component, changedComponent, componentV1]),
      systems: new LevelSystems([changedSystem, system])
    })
    jasmine.demoModal(modal)
    jasmine.Ajax.requests.mostRecent().respondWith({
      status: 200,
      responseText: JSON.stringify([
        { 
          name: 'First Branch',
          patches: [
            componentV0Changed.makePatch().toJSON()
          ]
        }
      ])
    })
    _.defer =>
      componentRequest = jasmine.Ajax.requests.mostRecent()
      expect(componentRequest.url).toBe(componentV0.url())
      componentRequest.respondWith({
        status: 200,
        responseText: JSON.stringify(componentV0.toJSON())
      })
#      modal.$('#branches-list-group input').val('Branch Name')
#      modal.$('#save-branch-btn').click()
#      saveBranchRequest = jasmine.Ajax.requests.mostRecent()
#      console.log 'save branch request', saveBranchRequest
      done()
