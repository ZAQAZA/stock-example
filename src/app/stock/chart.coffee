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
      selected: 0

  series = ->
    series: [
      name: "Price"
      data: (->
        data = []
        time = (new Date()).getTime()
        i = -60
        while i <= 0
          data.push [
            time + i * 1000
            (Math.random())
          ]
          i++
        data
      )()
    ]

  chartWrapper = (chart) ->
    addPrice: (time, price) ->
      chart.series[0].addPoint [time, price], true, true

  render: (ready) ->
    $ ->
      $("#chart-container").highcharts "StockChart", (_.extend {}, general(), chart(ready), range(), series())


