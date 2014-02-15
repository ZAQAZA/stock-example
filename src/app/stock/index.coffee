_ = require 'underscore'

module.exports = (app) ->

  keepChartAlive = (model, chart) ->
    model.on 'change', '_page.stockPrices.*.price.value', (id) ->
      price = model.get("_page.stockPrices.#{id}.price.value")
      chart.addPrice +new Date(), price if price

  initialPoints = (model) ->
    (_(model.get('_page.stockTransactions')).map (t) -> [t.timestamp, t.sum/t.amount]).reverse()

  app.enter '/stock/:name', (model) ->
    require('./chart.coffee').render initialPoints(model), _.partial(keepChartAlive, model)
