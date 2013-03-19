market = ->
    stocks: initStocks()
    requests: initBids()
    inventory: initInventory()

module.exports =
  init: (model) ->
    marketObj = market()
    model.setNull('stocks.elt', marketObj.stocks.elt)
    model.setNull('stocks.msft', marketObj.stocks.msft)
    model.setNull('bids.elt', marketObj.requests.elt)
    model.setNull('bids.msft', marketObj.requests.msft)
    model.setNull('traders.da135fe4-bbd4-418b-9c52-e03f0d3c4909', marketObj.inventory['da135fe4-bbd4-418b-9c52-e03f0d3c4909'])

  subscribe: (model, renderCallback) ->
    model.subscribe 'stocks', (err, stocks) ->
      model.subscribe 'bids', (err, bids) ->
        model.subscribe 'traders', (err, traders) ->
          model.set '_stocksIds', stocksIDs(initStocks())
          model.refList '_stocks', 'stocks', '_stocksIds'
          model.ref '_bids', bids
          model.ref '_traders', traders
          renderCallback()

  ofri: 'ofri'

initStocks = ->
  elt:
    id: 'elt'
    name: 'Elit'
    price: '1.1'
  msft:
    id: 'msft'
    name: 'Microsoft'
    price: '2.7'

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
    buy: []
    sell: [sellElt]
  msft:
    buy: [buyMsft]
    sell: [sellMsft]

initInventory = ->
  'da135fe4-bbd4-418b-9c52-e03f0d3c4909':
    stocks:
        elt: 101
        msft: 202
    ballance: 45000
