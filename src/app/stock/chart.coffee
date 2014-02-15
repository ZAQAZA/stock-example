_ = require 'underscore'

module.exports = do ->
  Highcharts.setOptions
    global:
      useUTC: false

  general = ->
    credits:
      enabled: false
    exporting:
      enabled: false

  chart = (ready) ->
    chart:
      events:
        load: ->
          ready chartWrapper(@)

  range = ->
    rangeSelector:
      buttons: [
        count: 1
        type: "minute"
        text: "1M"
      ,
        count: 5
        type: "minute"
        text: "5M"
      ,
        type: "all"
        text: "All"
      ]
      inputEnabled: false
      selected: 1

  series = (initialPoints) ->
    series: [
      name: "Price"
      data: initialPoints
    ]

  chartWrapper = (chart) ->
    addPrice: (time, price) ->
      chart.series[0].addPoint [time, price], true, true

  render: (initialPoints, ready) ->
    $ ->
      $("#chart-container").highcharts "StockChart", (_.extend {}, general(), chart(ready), range(), series(initialPoints))


