
module.exports =
  run: (store) ->
    model = store.createModel()
    currentPrice = 1
    randomChange = ->
      Math.round((Math.random()*50 - 25) * 10) / 1000
    setInterval ->
      model.add 'transactions',
        seller:'auto'
        buyer: 'auto'
        amount: 1
        sum: currentPrice + randomChange()
        stock: "08e2ae54-27dd-43f0-8344-3612bb3d1c3c"
        timestamp: +new Date()
    ,5000
