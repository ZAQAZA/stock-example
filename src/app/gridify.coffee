gridify = (array) ->
  empty = (arr) ->
    arr.length == 0
  full = (arr) ->
    arr.length == 3
  ids = []
  subIds = []
  collect = (id) ->
    subIds.push id
    if full(subIds)
      ids.push(subIds)
      subIds = []
  collect id for id in array
  if !empty(subIds) then ids.push(subIds)
  ids

module.exports =
  makeStocksGrid: (model) ->
    ids = gridify collectionIDs model.get('stocks')
    model.set '_ids', ids
    stocks = model.at('stocks')
    createRow = (i, row) ->
      model.refList '_stocksRow.'+i, stocks, model.at('_ids.'+i)
    createRow i, row for row, i in ids

collectionIDs = (collection) ->
  (s for s of collection)

