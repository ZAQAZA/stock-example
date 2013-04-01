market = ->
    stocks: initStocks()
    requests: initBids()
    inventory: initInventory()

module.exports =
  subscribe: (model, renderCallback) ->
    marketObj = market()
    model.subscribe 'stocks', (err, stocks) ->
      model.subscribe 'bids', (err, bids) ->
        model.subscribe 'traders', (err, traders) ->
          model.setNull('stocks.elt', marketObj.stocks.elt)
          model.setNull('stocks.msft', marketObj.stocks.msft)
          model.setNull('bids.elt', marketObj.requests.elt)
          model.setNull('bids.msft', marketObj.requests.msft)
          model.setNull('traders.da135fe4-bbd4-418b-9c52-e03f0d3c4909', marketObj.inventory['da135fe4-bbd4-418b-9c52-e03f0d3c4909'])
          model.set '_stocksIds', stocksIDs(stocks.get())
          model.set '_tradersIDs', tradersIDs()
          model.ref '_traders', traders
          model.ref '_stocks', stocks
          model.ref '_bids', bids
          model.refList '_tradersList', traders, '_tradersIDs'
          model.refList '_stocksList', stocks, '_stocksIds'
          model.refList '_bidsList', bids, '_stocksIds'
          renderCallback()

initStocks = ->
  elt:
    id: 'elt'
    name: 'Elit'
    price: '1.1'
  msft:
    id: 'msft'
    name: 'Microsoft'
    price: '2.1'

stocksIDs = (stocks) ->
  (s for s of stocks)

initBids = ->
  sellElt =
    user: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    amount: 50
    price: 1.2
  buyMsft =
    user: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    amount: 10
    price: 0.9
  sellMsft =
    user: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    amount: 80
    price: 0.3
  elt:
    stockID: 'elt'
    buy: []
    sell: [sellElt]
  msft:
    stockID: 'msft'
    buy: [buyMsft]
    sell: [sellMsft]

tradersIDs = ->
  ['da135fe4-bbd4-418b-9c52-e03f0d3c4909']
initInventory = ->
  'da135fe4-bbd4-418b-9c52-e03f0d3c4909':
    id: 'da135fe4-bbd4-418b-9c52-e03f0d3c4909'
    stocks:
        elt: 101
        msft: 202
    balance: 45000
