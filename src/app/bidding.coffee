trader = require './trader'

module.exports =
  bid: (model) ->
    newBid =
      id: model.id()
      type: model.get('_bidding.type')
      user: trader.userID(model)
      origAmount: +model.get('_bidding.amount')
      amount: +model.get('_bidding.amount')
      price: +model.get('_bidding.price')
      stock: model.get('_bidding.stock')
    model.push('_bidsList', newBid)
    console.log 'bidding'
