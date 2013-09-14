_ = require('underscore')
Bid = require "./Bid.coffee"

module.exports =
  subscribe: (store) ->
    store.hook 'create', 'bids', (bidId, newBid, op, session, backend) ->
      model = store.createModel()
      matcher bidId

matcher = (bidId) ->
  Bid.fetch model, (err, bid) ->
    throw err if err
    bid.fetchMatches model, (err, bids) ->
      throw err if err
      console.log 'no matches found' unless bids.length
      match model, bid, bids

match = (model, bid, bids) ->
  unless bids.length
    return
  execute model, bid, _.first(bids), (err) ->
    return (handleErr err) if err
    match model, bid.reload(model), _.rest(bids)

execute = (model, newBid, oldBid, callback) ->
  BidTransaction.create model, newBid, oldBid, (err, transaction) ->
    return callback(err) if err
    callback null, transaction.execute()

handleErr = (err) ->
  throw err if err
