_ = require 'underscore'

module.exports = (app) ->

  keepChartAlive = (model, chart) ->
    model.on 'change', '_page.stockPrices.*.price', (id) ->
      price = model.get("_page.stockPrices.#{id}.price.value")
      chart.addPrice +new Date(), price if price

  app.enter '/stock/:id', (model) ->
    require('./chart.coffee').render _.partial(keepChartAlive, model)
