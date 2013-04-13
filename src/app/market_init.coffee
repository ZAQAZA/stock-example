market = ->
    stocks: initStocks()
    requests: initBids()

module.exports =
  subscribe: (model, userID, renderCallback) ->
    marketObj = market()
    model.subscribe 'stocks', (err, stocks) ->
      model.subscribe 'bids', (err, bids) ->
        model.subscribe 'ids', (err, ids) ->

          model.setNull('stocks.elt', marketObj.stocks.elt)
          model.setNull('stocks.msft', marketObj.stocks.msft)
          model.set '_stocksIds', collectionIDs(stocks.get())
          model.ref '_stocks', stocks
          model.refList '_stocksList', stocks, '_stocksIds'

          ids.setNull 'bids.ids', []
          model.refList '_bidsList', bids, 'ids.bids.ids'

          initUser model, userID
          renderCallback()

initUser = (model, userID) ->
  model.setNull('users.'+userID+'.stockHoldings', initStockHoldings())
  model.setNull('users.'+userID+'.balance', 1000000)
  model.ref '_holdings', 'users.'+userID+'.stockHoldings'
  model.ref '_balance', 'users.'+userID+'.balance'

initStocks = ->
  elt:
    id: 'elt'
    name: 'Elit'
    price: '1.1'
  msft:
    id: 'msft'
    name: 'Microsoft'
    price: '2.1'

collectionIDs = (collection) ->
  (s for s of collection)

initBids = ->
  a1a1a1a1:
    id: 'a1a1a1a1'
    type: 'sell'
    user: '4239141e-5a1f-4d98-bbe0-67c48dfc4e84'
    origAmount: 50
    amount: 50
    price: 1.2
    stock: 'elt'
  b2b2b2b2:
    id: 'b2b2b2b2'
    type: 'buy'
    user: '4239141e-5a1f-4d98-bbe0-67c48dfc4e84'
    origAmount: 10
    amount: 10
    price: 0.9
    stock: 'msft'
  c3c3c3c3:
    id: 'c3c3c3c3'
    type: 'sell'
    user: '4239141e-5a1f-4d98-bbe0-67c48dfc4e84'
    origAmount: 80
    amount: 80
    price: 0.3
    stock: 'msft'

initStockHoldings = ->
  [
      stock: 'elt'
      amount: 100
    ,
      stock: 'msft'
      amount: 100
  ]
