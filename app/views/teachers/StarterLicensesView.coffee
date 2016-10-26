RootView = require 'views/core/RootView'
State = require 'models/State'

module.exports = class StarterLicensesView extends RootView
  id: 'starter-licenses-view'
  template: require 'templates/teachers/starter-licenses-view'

  events:
    {}

  initialize: (options) ->
    @state = new State({
      pricePerStudent: 1000
    })
