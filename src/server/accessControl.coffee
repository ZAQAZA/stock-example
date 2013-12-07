module.exports = (store) ->
  ###
  store.allow 'create', 'bids', (docId, newDoc, session) ->
    model = store.createModel()
    console.log '[Bids] CREATE'
    undefined
  ###
