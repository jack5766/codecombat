RootView = require 'views/core/RootView'
State = require 'models/State'
Products = require 'collections/Products'
PurchaseStarterLicensesModal = require 'views/teachers/PurchaseStarterLicensesModal'
TeachersContactModal = require 'views/teachers/TeachersContactModal'

module.exports = class StarterLicensesView extends RootView
  id: 'starter-licenses-view'
  template: require 'templates/teachers/starter-licenses-view'

  events:
    'click .purchase-btn': 'onClickPurchaseButton'
    'click .contact-us-btn': 'onClickContactUsButton'

  initialize: (options) ->
    @state = new State({
      dollarsPerStudent: undefined
    })
    @products = new Products()
    @supermodel.trackRequest @products.fetch()
    @listenTo @products, 'sync', ->
      centsPerStudent = @products.getByName('starter_license')?.get('amount')
      @state.set {
        dollarsPerStudent: centsPerStudent/100
      }
    @listenTo @state, 'change', ->
      @render()

  onClickPurchaseButton: ->
    @openModalView(new PurchaseStarterLicensesModal())

  onClickContactUsButton: ->
    window.tracker?.trackEvent 'Classes Starter Licenses Upsell Contact Us', category: 'Teachers', ['Mixpanel']
    @openModalView(new TeachersContactModal())
