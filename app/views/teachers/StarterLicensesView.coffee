RootView = require 'views/core/RootView'
State = require 'models/State'
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
      pricePerStudent: 1000
    })
    @purchaseStarterLicensesModal = new PurchaseStarterLicensesModal

  onClickPurchaseButton: ->
    @openModalView(@purchaseStarterLicensesModal)

  onClickContactUsButton: ->
    window.tracker?.trackEvent 'Classes Starter Licenses Upsell Contact Us', category: 'Teachers', ['Mixpanel']
    @openModalView(new TeachersContactModal())
