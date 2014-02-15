_ = require('underscore')

randomChange = ->
  Math.round((Math.random()*50 - 25) * 10) / 1000

randomInterval = ->
  Math.random()*3 * 1000

createMaker = (model, stockId) ->

  currentPrice = (cb) ->
    query = model.query 'transactions',
      stock: stockId
      $orderby:
        timestamp: -1
      $limit: 1
    query.fetch ->
      return cb(1) unless query.get().length > 0
      cb(query.get()[0].sum / query.get()[0].amount)

  make = ->
    currentPrice (price) ->
      model.add 'transactions',
        seller:'auto'
        buyer: 'auto'
        amount: 1
        sum: Math.abs(price + randomChange())
        stock: stockId
        timestamp: +new Date()
      setTimeout make, randomInterval()

  make()

fetchStocks = (model, cb) ->
  model.fetch 'stocks', ->
    cb(model.get('stocks'))

module.exports =
  run: (store) ->
    model = store.createModel()
    fetchStocks model, (stocks) ->
      _.chain(stocks).map((s) -> s.id).each (id) ->
        createMaker model, id
