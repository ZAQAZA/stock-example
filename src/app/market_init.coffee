market = ->
    stocks: initStocks()
    requests: initBids()
    inventory: initInventory()

module.exports =
  subscribe: (model, userID, renderCallback) ->
    marketObj = market()
    model.subscribe 'stocks', (err, stocks) ->
      model.subscribe 'bids', (err, bids) ->
        model.subscribe 'traders', (err, traders) ->
          model.setNull('stocks.elt', marketObj.stocks.elt)
          model.setNull('stocks.msft', marketObj.stocks.msft)
          model.setNull('bids.a1a1a1a1', marketObj.requests.a1a1a1a1)
          model.setNull('bids.b2b2b2b2', marketObj.requests.b2b2b2b2)
          model.setNull('bids.c3c3c3c3', marketObj.requests.c3c3c3c3)
          model.setNull('traders.da135fe4-bbd4-418b-9c52-e03f0d3c4909', marketObj.inventory['da135fe4-bbd4-418b-9c52-e03f0d3c4909'])
          model.set '_stocksIds', collectionIDs(stocks.get())
          model.set '_bidsIds', collectionIDs(bids.get())
          model.set '_tradersIDs', tradersIDs()
          model.ref '_traders', traders
          model.ref '_stocks', stocks
          model.refList '_tradersList', traders, '_tradersIDs'
          model.refList '_stocksList', stocks, '_stocksIds'
          model.refList '_bidsList', bids, '_bidsIds'
          initUser model, userID
          renderCallback()

initUser = (model, userID) ->
  initialTrader =
    id: userID
    stocks: {}
    balance: 1000000
  model.setNull 'traders.'+userID, initialTrader

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
    user: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    origAmount: 50
    amount: 50
    price: 1.2
    stock: 'elt'
  b2b2b2b2:
    id: 'b2b2b2b2'
    type: 'buy'
    user: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    origAmount: 10
    amount: 10
    price: 0.9
    stock: 'msft'
  c3c3c3c3:
    id: 'c3c3c3c3'
    type: 'sell'
    user: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    origAmount: 80
    amount: 80
    price: 0.3
    stock: 'msft'

tradersIDs = ->
  ['da135fe4-bbd4-418b-9c52-e03f0d3c4909']

initInventory = ->
  'da135fe4-bbd4-418b-9c52-e03f0d3c4909':
    id: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    stocks:
        elt: 101
        msft: 202
    balance: 45000
