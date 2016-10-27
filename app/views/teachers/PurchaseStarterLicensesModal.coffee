ModalView = require 'views/core/ModalView'
State = require 'models/State'
utils = require 'core/utils'
Products = require 'collections/Products'

module.exports = class PurchaseStarterLicensesModal extends ModalView
  id: 'purchase-starter-licenses-modal'
  template: require 'templates/teachers/purchase-starter-licenses-modal'
  
  events:
    'input input[name="quantity"]': 'onInputQuantity'
    'change input[name="quantity"]': 'onInputQuantity'

  initialize: (options) ->
    @state = new State({
      quantityToBuy: 10
      pricePerStudent: undefined
      maxQuantity: 75
    })
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')
    @listenTo @products, 'sync change update', ->
      starterLicense = @products.findWhere({ name: 'starter_license' })
      @state.set { pricePerStudent: starterLicense.get('amount')/100 }
    @listenTo @state, 'change', => @renderSelectors('.dollar-value')
    super(options)
  
  onLoaded: ->
    super()
    
  onInputQuantity: (e) ->
    $input = $(e.currentTarget)
    inputValue = parseFloat($input.val()) or 0
    if $input.val() isnt ''
      boundedValue = Math.max(Math.min(inputValue, @state.get('maxQuantity')), 0)
      if boundedValue isnt inputValue
        $input.val(boundedValue)
    @state.set { quantityToBuy: inputValue }
  
  getPricePerStudentString: -> utils.formatDollarValue(@state.get('pricePerStudent'))
  getTotalPriceString: -> utils.formatDollarValue(@state.get('pricePerStudent') * @state.get('quantityToBuy'))
    
