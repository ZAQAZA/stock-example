module.exports =
  subscribe: (model, userID, renderCallback) ->
    userPath = 'users.' + userID
    model.subscribe 'ids.stocks.ids', 'ids.bids.ids', (err, stocksIds, bidsIds) ->
        model.subscribe 'stocks', (err, stocks) ->
          model.subscribe 'bids', (err, bids) ->
            model.subscribe userPath, (err, user) ->

              initMarketIfEmpty model
              initUser model, userID

              model.refList '_stocks', stocks, stocksIds
              model.refList '_bids', bids, bidsIds
              model.refList '_userHoldings', user.at('stockHoldings'), userPath + '.ids.holdings'
              model.ref '_user', user

              renderCallback()

initMarketIfEmpty = (model) ->
  unless Object.keys(model.get('stocks')).length
    stocks = initStocks()
    model.setNull 'stocks.elt', stocks.elt
    model.setNull 'stocks.msft', stocks.msft
    model.setNull 'stocks.teva', stocks.teva
    model.setNull 'stocks.emc', stocks.emc
    model.setNull 'stocks.smng', stocks.smng
    model.setNull 'stocks.ibm', stocks.ibm
    model.setNull 'stocks.appl', stocks.appl
    model.set 'ids.stocks.ids', collectionIDs(model.get('stocks'))
    model.set 'ids.bids.ids', collectionIDs(model.get('bids'))

initUser = (model, userID) ->
  unless model.get('users.'+userID+'.stockHoldings') && Object.keys(model.get('users.'+userID+'.stockHoldings')).length
    model.setNull('users.'+userID+'.stockHoldings', initStockHoldings())
    model.set 'users.'+userID+'.ids.holdings', collectionIDs(model.get('users.'+userID+'.stockHoldings'))
    model.setNull('users.'+userID+'.balance', parseFloat(1000.0))


initStocks = ->
  elt:
    id: 'elt'
    name: 'Elit'
    price: 1.1
    change: -0.4
  msft:
    id: 'msft'
    name: 'Microsoft'
    price: 2.1
    change: 0.2
  teva:
    id: 'teva'
    name: 'Teva Inc.'
    price: 4.2
    change: -1.4
  emc:
    id: 'emc'
    name: 'EMC2'
    price: 11.7
    change: 3.6
  smng:
    id: 'smng'
    name: 'Samanage'
    price: 0.3
    change: 0.0
  ibm:
    id: 'ibm'
    name: 'IBM'
    price: 6.33
    change: 4.0
  appl:
    id: 'appl'
    name: 'Apple Inc.'
    price: 13.8
    change: 2.1

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
  h00001:
    id: 'h00001'
    stock: 'elt'
    amount: 100
  h00002:
    id: 'h00002'
    stock: 'msft'
    amount: 100
