matcher = require "./matcher.coffee"

module.exports =
  subscribe: (store) ->
    store.hook 'create', 'bids', (bidId, newBid, op, session, backend) ->
      model = store.createModel()
      matcher(model)(bidId)
