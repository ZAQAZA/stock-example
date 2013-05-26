derby = require 'derby'
market = require './market_init'
trader = require './trader'
gridify = require './gridify'

marketContext = (model, callback) ->
  trader.subscribe model, (userID) ->
    if userID
      market.subscribe model, userID, ->
        callback()
    else
      callback()



controller =
  portal: (page, model) ->
    marketContext model, () ->
      model.set '_registered', true
      model.set '_room', 'portal'
      page.render 'portal'

  stocks: (page, model) ->
    marketContext model, () ->
      gridify.makeStocksGrid model
      model.set '_room', 'stocks'
      page.render 'portal'

  admin: (page, model) ->
    marketContext model, () ->
      model.set '_room', 'admin'
      page.render 'admin'

module.exports = controller

# import ready callback
require './ready'

# import view functions
require './viewFunctions'
