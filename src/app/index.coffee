app = require('derby').createApp(module)
  .use(require 'derby-ui-boot')
  .use(require '../../ui/index.coffee')
  .use(require 'derby-auth/components/index.coffee')

withContexts = (model, callback, contexts) ->
  if contexts.length is 0
    callback()
    return
  contexts[0] model, ->
    withContexts model, callback, contexts[1..contexts.length-1]

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

withUserCollection = (collection, alias) ->
  (model, callback) ->
    query = model.query collection,
      user: loggedInUser model
    query.subscribe (err) ->
      throw err if err
      query.ref "_page.user.#{alias || collection}"
      callback()

withAllCollection = (collection, alias) ->
  (model, callback) ->
    itemsQuery = model.query collection, {}
    itemsQuery.subscribe (err) ->
      throw err if err
      itemsQuery.ref "_page.#{alias || collection}"
      callback()

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

withUserHoldings = withUserCollection 'holdings', 'inventory'
withUserBids = withUserCollection 'bids'
withAllUserCollections = [withUser, withUserHoldings, withUserBids]

withAllStocks = withAllCollection 'stocks'
withAllHoldings = withAllCollection 'holdings', 'inventory'
withAllBids = withAllCollection 'bids'
withAllUsers = withAllCollection 'auths', 'users'

withAll = [withUser, withAllStocks, withAllHoldings, withAllBids, withAllUsers]

# REACTIVE FUNCTIONS #

app.on 'model', (model) ->
  model.fn 'all', ->
    true

# ROUTES #

app.get '/', (page, model) ->
  withContexts model, ->
    page.render 'home'
  , [withUser]

app.get '/stocks', (page, model) ->
  withContexts model, ->
    page.render 'stocks'
  , [withUser, withAllStocks]

app.get '/inventory', (page, model) ->
  withContexts model, ->
    page.render 'inventory'
  , withAllUserCollections.concat withAllStocks

app.enter '/inventory', (model) ->
  $('select').selectpicker()

app.get '/admin', (page, model) ->
  withContexts model, ->
    page.render 'admin'
  , withAll

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
  find_id_by_name = (name) ->
    for stock in $model.get '_page.stocks'
      return stock.id if stock.name is name
  newItem['stock'] = find_id_by_name $('.bid-stock-select').val()
  newItem['amountLeft'] = newItem.amount
  newItem['user'] = $model.get '_session.userId'
  $model.add "bids", newItem

app.fn 'bid.remove', (e) ->
  bid = e.get ':bid'
  @model.del 'bids.' + bid.id

app.fn 'bids.buy', (e) ->
  @model.set '_page.newBid.type', 'buy'

app.fn 'bids.sell', (e) ->
  @model.set '_page.newBid.type', 'sell'

# VIEW FUNCTIONS #

app.view.fn 'priceHandler',
  get: (price) -> price
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

app.ready (model) ->
