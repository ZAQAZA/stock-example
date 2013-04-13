derby = require 'derby'
market = require './market_init'
trader = require './trader'


controller =
  index: (page, model) ->

    trader.subscribe model, (userID) ->
      if userID
        market.subscribe model, userID, ->
          page.render 'index'
      else
        page.render 'index'

  add_bid: (page, model) ->
    alert 'adding bid'
    page.render 'user'

module.exports = controller

# import ready callback
require './ready'

# import view functions
require './viewFunctions'
