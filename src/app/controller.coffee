derby = require 'derby'
market = require './market_init'
trader = require './trader'


controller =
  index: (page, model) ->

    market.subscribe model, ->
      trader.subscribe model, (userExist) ->
        page.render 'index'

module.exports = controller

# import ready callback
require './ready'

# import view functions
require './viewFunctions'
