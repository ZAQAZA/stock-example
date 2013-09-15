_ = require('underscore')
Bid = require "./Bid.coffee"
BidTransaction = require "./BidTransaction.coffee"

module.exports =
  subscribe: (store) ->
    store.hook 'create', 'bids', (bidId, newBid, op, session, backend) ->
      model = store.createModel()
      matcher(model).runOn(bidId)

matcher = (model) ->

  match = (bid, bids) ->
    return unless bids.length
    execute bid, _.first(bids), (err) ->
      return (handleErr err) if err
      match bid.reload(model), _.rest(bids)

  execute = (newBid, oldBid, callback) ->
    BidTransaction.create model, newBid, oldBid, (err, transaction) ->
      return callback(err) if err
      callback null, transaction.execute()

  runOn: (bidId) ->
    Bid.fetch model, bidId, (err, bid) ->
      throw err if err
      bid.fetchMatches model, (err, bids) ->
        throw err if err
        console.log 'no matches found' unless bids.length
        match bid, bids

