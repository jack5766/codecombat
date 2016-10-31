ModalView = require 'views/core/ModalView'
State = require 'models/State'
utils = require 'core/utils'
Products = require 'collections/Products'
Prepaids = require 'collections/Prepaids'
stripeHandler = require 'core/services/stripe'

module.exports = class PurchaseStarterLicensesModal extends ModalView
  id: 'purchase-starter-licenses-modal'
  template: require 'templates/teachers/purchase-starter-licenses-modal'
  
  maxQuantityStarterLicenses: 75
  i18nData: -> {
    @maxQuantityStarterLicenses,
    starterLicenseLengthMonths: 6,
    quantityAlreadyPurchased: @state.get('quantityAlreadyPurchased')
  }
  
  events:
    'input input[name="quantity"]': 'onInputQuantity'
    'change input[name="quantity"]': 'onInputQuantity'
    'click .pay-now-btn': 'onClickPayNowButton'

  initialize: (options) ->
    @listenTo stripeHandler, 'received-token', @onStripeReceivedToken
    @state = new State({
      quantityToBuy: 10
      pricePerStudent: undefined
      quantityAlreadyPurchased: undefined
      quantityAllowedToPurchase: undefined
    })
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')
    @listenTo @products, 'sync change update', ->
      starterLicense = @products.findWhere({ name: 'starter_license' })
      @state.set { pricePerStudent: starterLicense.get('amount')/100 }
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)
    @listenTo @prepaids, 'sync change update', ->
      starterLicenses = new Prepaids(@prepaids.where({ type: 'starter_license' }))
      @state.set {
        quantityAlreadyPurchased: starterLicenses.totalMaxRedeemers()
        quantityAllowedToPurchase: @maxQuantityStarterLicenses - starterLicenses.totalMaxRedeemers()
      }
    @listenTo @state, 'change', => @renderSelectors('.render')
    super(options)
  
  onLoaded: ->
    super()
    
  getPricePerStudentString: -> utils.formatDollarValue(@state.get('pricePerStudent'))
  getTotalPriceString: -> utils.formatDollarValue(@state.get('pricePerStudent') * @state.get('quantityToBuy'))
  
  boundedValue: (value) ->
    Math.max(Math.min(value, @maxQuantityStarterLicenses - @state.get('quantityAlreadyPurchased')), 0)
    
  onInputQuantity: (e) ->
    $input = $(e.currentTarget)
    inputValue = parseFloat($input.val()) or 0
    boundedValue = inputValue
    if $input.val() isnt ''
      boundedValue = @boundedValue(inputValue)
      if boundedValue isnt inputValue
        $input.val(boundedValue)
    @state.set { quantityToBuy: boundedValue }
    
  onClickPayNowButton: ->
    @state.set({
      purchaseProgress: undefined
      purchaseProgressMessage: undefined
    })
    
    application.tracker?.trackEvent 'Started course prepaid purchase', {
      price: @state.get('pricePerStudent'), students: @state.get('quantityToBuy')
    }
    stripeHandler.open
      amount: @state.get('quantityToBuy') * @state.get('pricePerStudent') * 100
      description: "Starter course access for #{@state.get('quantityToBuy')} students"
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
    
  onStripeReceivedToken: (e) ->
    @state.set({ purchaseProgress: 'purchasing' })
    @render?()

    data =
      maxRedeemers: @state.get('quantityToBuy')
      type: 'starter_license'
      stripe:
        token: e.token.id
        timestamp: new Date().getTime()

    $.ajax({
      url: '/db/starter-license-prepaid',
      data: data,
      method: 'POST',
      context: @
      success: ->
        application.tracker?.trackEvent 'Finished starter license purchase', {price: @state.get('pricePerStudent'), seats: @state.get('quantityToBuy')}
        @state.set({ purchaseProgress: 'purchased' })
        application.router.navigate('/teachers/licenses', { trigger: true })

      error: (jqxhr, textStatus, errorThrown) ->
        application.tracker?.trackEvent 'Failed starter license purchase', status: textStatus
        if jqxhr.status is 402
          @state.set({
            purchaseProgress: 'error'
            purchaseProgressMessage: arguments[2]
          })
        else
          @state.set({
            purchaseProgress: 'error'
            purchaseProgressMessage: "#{jqxhr.status}: #{jqxhr.responseText}"
          })
        @render?()
    })
