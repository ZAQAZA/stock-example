_ = require('underscore')

app = require('derby').createApp(module)
  .use(require '../../ui/index.coffee')
  .use(require 'derby-auth/components/index.coffee')

(require 'derby-ui-boot') app,
  styles: __dirname + '/../../bootstrap-css/bootstrap.min'

# TODO should consider replacing this with async.waterfull
withContexts = (model, contexts, callback) ->
  if contexts.length is 0
    callback()
    return
  contexts[0] model, ->
    withContexts model, contexts[1..contexts.length-1], callback

loggedInUser = (model) ->
  model.get "_session.userId"

withUser = (model, callback) ->
  model.set '_page.registered', true
  userId = loggedInUser model
  unless userId
    callback()
    return
  $user = model.at "auths.#{userId}"
  $username = $user.at "local.username"
  $balance = $user.at "balance"
  model.subscribe $user, (err) ->
    throw err if err
    $balance.setNull '', 1000.0
    model.ref "_page.user.local", $user.at "local"
    model.ref "_page.user.name", $username
    model.ref "_page.user.balance", $balance
    callback()

withUserCollection = (collection, queryObj={}, alias=collection) ->
  (model, callback) ->
    query = model.query collection, _.extend(queryObj, {user: loggedInUser model})
    query.subscribe (err) ->
      throw err if err
      query.ref "_page.user.#{alias}"
      callback()

withAllCollection = (collection, alias=collection, limit) ->
  (model, callback) ->
    queryObj =
      $orderby:
        timestamp: -1
      $limit: limit
    queryObj = {} unless limit
    itemsQuery = model.query collection, queryObj
    itemsQuery.subscribe (err) ->
      throw err if err
      itemsQuery.ref "_page.#{alias}"
      callback()

withStock = (name, model, callback) ->
  query = model.query 'stocks', {name}
  query.fetch (err) ->
    throw err if err
    stockId = query.get()[0].id
    stock = model.at "stocks.#{stockId}"
    stock.subscribe ->
      model.ref "_page.stock", stock
      startStockPrice model, stock.get()
      withStocksTransactions model, [stock.get()], callback

withStocksTransactions = (model, stocks, callback) ->
  contexts = _(stocks).map (stock) ->
    id = stock.id
    (model, cb) ->
      query = model.query 'transactions',
        stock: id
        $orderby:
          timestamp: -1
        $limit: 3
      query.subscribe (err) ->
        throw err if err
        query.ref "_page.transactions.#{id}"
        cb()
  withContexts model, contexts, callback

startStockPrice = (model, stock) ->
  model.start 'stockPrice', "_page.stockPrices.#{stock.id}.price", "_page.transactions.#{stock.id}"

startAllStockPrices = (model) ->
  _(model.get "_page.stocks").each _.partial(startStockPrice, model)

nicePriceChange = (model) ->
  model.on 'change', '_page.stockPrices.*.price', (id) ->
    model.set "_page.stockPrices.#{id}.status", 'changed'
    setTimeout ->
      model.set "_page.stockPrices.#{id}.status", null
    , 5000

### It used to be filters, but it had problems now it's queries
# maybe we'll try filters again when it becomes more stable.
withAllCollection = (collection, alias) ->
  (model, callback) ->
    items = model.filter collection, 'all'
    model.subscribe collection, (err) ->
      throw err if err
      items.ref "_page.#{alias || collection}"
      callback()
###

withUserHoldings = withUserCollection 'holdings', {}, 'inventory'
withUserActiveBids = withUserCollection 'bids', {amountLeft: {$gt: 0}}
withUserDeadBids = withUserCollection 'bids', {amountLeft: 0}, 'deadBids'
withAllUserCollections = [withUser, withUserHoldings, withUserActiveBids, withUserDeadBids]

withAllStocks = withAllCollection 'stocks'
withAllHoldings = withAllCollection 'holdings', 'inventory'
withAllBids = withAllCollection 'bids'
withAllUsers = withAllCollection 'auths', 'users'
withAllTransactions = withAllCollection 'transactions', 'transactions', 5

withAll = [withUser, withAllStocks, withAllHoldings, withAllBids, withAllUsers, withAllTransactions]

# REACTIVE FUNCTIONS #

app.on 'model', (model) ->
  model.fn 'all', ->
    true

  model.fn 'pluckNames', (items) ->
    _(items).map (item) ->
      text: item.name
      value: item.id

  model.fn 'stockPrice', (stockTransactions) ->
    return unless stockTransactions?.length is 3
    lastTransaction = _(stockTransactions).max (transaction) -> transaction?.timestamp
    value: lastTransaction.sum / lastTransaction.amount
    timestamp: lastTransaction.timestamp

  model.fn 'exercisableBalance', (userBids, balance) ->
    sum = (bid) -> bid.amountLeft * bid.price
    balance - _.chain(userBids).filter((b) -> b.type is "buy").reduce(((s, b) -> s + sum(b)), 0).value()

# ROUTES #

app.get '/', (page, model) ->
  withContexts model, [withUser], ->
    page.render 'home'

app.get '/stocks', (page, model) ->
  withContexts model, [withUser, withAllStocks], ->
    withStocksTransactions model, model.get('_page.stocks'), ->
      startAllStockPrices model
      page.render 'stocks'

app.get '/stock/:name', (page, model, params) ->
  withContexts model, [withUser, _.partial(withStock, params.name)], ->
    page.render 'stock'

app.get '/inventory', (page, model) ->
  withContexts model, withAllUserCollections.concat(withAllStocks), ->
    model.start 'pluckNames', '_page.stocksNames', 'stocks'
    model.start 'exercisableBalance', '_page.user.exercisableBalance', '_page.user.bids', '_page.user.balance'
    page.render 'inventory'

app.get '/admin', (page, model) ->
  withContexts model, withAll, ->
    page.render 'admin'

myAlert = (log, obj) ->
  cache = []
  log JSON.stringify obj, (key, value) ->
    if (typeof value is 'object' and value isnt null)
      return if (cache.indexOf(value) isnt -1)
      cache.push(value)
    return value
  , 4
  cache = null

# CONTROLLER FUNCTIONS #

app.fn 'login.toggle', (e) ->
  @model.set '_page.registered', !(@model.get '_page.registered')

app.fn 'stocks.add', (e, el) ->
  newItem = @model.del '_page.newStock'
  return unless newItem
  newItem.creator = @model.get '_session.userId'
  @model.add 'stocks', newItem

app.fn 'stocks.remove', (e) ->
  stock = e.get ':stock'
  @model.del 'stocks.' + stock.id

app.fn 'user.stocks.add', (e, el) ->
  id = e.get ':stock.id'
  model = @model
  userId = model.get '_session.userId'
  inventory = model.get "_page.user.inventory"
  holdingQuery = model.query 'holdings',
    user: userId
    stock: id
  model.subscribe holdingQuery, (err) ->
    throw err if err
    holdings = holdingQuery.get()
    if holdings.length
      model.increment "holdings.#{holdings[0].id}.amount"
    else
      model.add "holdings",
        user: userId
        stock: id
        amount: 1

app.fn 'user.stocks.remove', (e) ->
  holding = e.get ':stock'
  @model.del 'holdings.' + holding.id

app.fn 'bids.add', (e) ->
  $model = @model
  newItem = $model.del '_page.newBid'
  return unless newItem
  if newItem.type is 'illegal'
    alert 'You cannot bid anymore!'
    return
  newItem['amountLeft'] = newItem.amount
  newItem['user'] = $model.get '_session.userId'
  $model.add "bids", newItem

app.fn 'bid.remove', (e) ->
  bid = e.get ':bid'
  @model.del 'bids.' + bid.id

app.fn 'bids.buy', (e) ->
  illegal = =>
    amount = @model.get '_page.newBid.amount'
    price = @model.get '_page.newBid.price'
    exe = @model.get '_page.user.exercisableBalance'
    amount*price > exe
  @model.set '_page.newBid.type', 'buy'
  @model.set '_page.newBid.type', 'illegal' if illegal()

app.fn 'bids.sell', (e) ->
  @model.set '_page.newBid.type', 'sell'

app.fn 'transaction.remove', (e) ->
  transaction = e.get ':transaction'
  @model.del 'transactions.' + transaction.id

# VIEW FUNCTIONS #

app.view.fn 'priceHandler',
  get: (price) -> price?.toFixed(2)
  set: (price) ->
    [if isNaN(parseFloat price) then 0 else parseFloat price]

app.view.fn 'amountHandler',
  get: (amount) -> amount
  set: (amount) ->
    [if isNaN(parseInt amount) then 0 else parseInt amount]

app.view.fn 'stockRowClass', (stock) ->
  if stock.change > 0
    "text-success"
  else if stock.change < 0
    "text-error"
  else
    "text-info"

app.view.fn 'changeHandler', (change) ->
  if change then change else 0.0

# READY FUNCTION #

app.enter '/inventory', (model) ->
  $ ->
    $('.dead-bids-toggle').click (e) ->
      $('.dead-bids-list').slideToggle()
      e.preventDefault()

app.enter '/stocks', nicePriceChange

require('./stock/index.coffee')(app)
