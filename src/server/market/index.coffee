matcher = require "./matcher.coffee"
exercisable = require "./exercisable.coffee"

module.exports =
  subscribe: (store) ->
    store.hook 'create', 'bids', (bidId, newBid, op, session, backend) ->
      model = store.createModel()
#      updateExercisableBalance model, bidId, (err) ->
#       throw err if err
      matcher(model)(bidId)

updateExercisableBalance = (model, bidId, callback) ->
  Bid.fetch model, bidId, (err, bid) ->
    throw err if err
    $user = model.at "auths.#{bid.user}"
    sum = if bid.type is 'sell' then @values.sum else -@values.sum

    fetch: (cb) -> $user.fetch(cb) # wanted to simply pass $user.fetch, but fetch is not bound to this.
