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

withAllUsers = (model, callback) ->
  inventoryQuery = model.query 'holdings', {}
  bidsQuery = model.query 'bids', {}
  usersQuery = model.query 'auths', {}
  model.subscribe usersQuery, bidsQuery, inventoryQuery, (err) ->
    throw err if err
    usersQuery.ref '_page.users'
    bidsQuery.ref '_page.bids'
    inventoryQuery.ref '_page.inventory'
    callback()

withUser = (model, callback) ->
  model.set '_page.registered', true
  userId = model.get "_session.userId"
  unless userId
    callback()
    return
  $user = model.at "auths.#{userId}"
  $username = $user.at "local.username"
  $balance = $user.at "balance"
  inventoryQuery = model.query "holdings",
    user: userId
  bidsQuery = model.query "bids",
    creator: userId
  model.subscribe $user, bidsQuery, inventoryQuery, (err) ->
    throw err if err
    $balance.setNull '', 1000.0
    model.ref "_page.user.local", $user.at "local"
    model.ref "_page.user.name", $username
    model.ref "_page.user.balance", $balance
    inventoryQuery.ref "_page.user.inventory"
    bidsQuery.ref "_page.user.bids"
    callback()

withStocks = (model, callback) ->
  stocksQuery = model.query 'stocks', {}
  stocksQuery.subscribe (err) ->
    throw err if err
    stocksQuery.ref '_page.stocks'
    callback()

# ROUTES #

app.get '/', (page, model) ->
  withContexts model, ->
    page.render 'home'
  , [withUser]

app.get '/stocks', (page, model) ->
  withContexts model, ->
    page.render 'stocks'
  , [withUser, withStocks]

app.get '/inventory', (page, model) ->
  withContexts model, ->
    page.render 'inventory'
  , [withUser, withStocks]

app.enter '/inventory', (model) ->
  $('select').selectpicker()

app.get '/admin', (page, model) ->
  withContexts model, ->
    page.render 'admin'
  , [withAllUsers, withUser, withStocks ]

app.get '/list', (page, model, params, next) ->
  # This value is set on the server in the `createUserId` middleware
  userId = model.get '_session.userId'

  # Create a scoped model, which sets the base path for all model methods
  user = model.at 'users.' + userId

  # Create a mongo query that gets the current user's items
  itemsQuery = model.query 'items', {userId}

  # Get the inital data and subscribe to any updates
  model.subscribe user, itemsQuery, (err) ->
    return next err if err

    # Create references that can be used in templates or controller methods
    model.ref '_page.user', user
    itemsQuery.ref '_page.items'

    user.increment 'visits'
    page.render 'list'

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

app.fn 'list.add', (e, el) ->
  newItem = @model.del '_page.newItem'
  return unless newItem
  newItem.userId = @model.get '_session.userId'
  @model.add 'items', newItem

app.fn 'list.remove', (e) ->
  id = e.get ':item.id'
  @model.del 'items.' + id

app.fn 'login.toggle', (e) ->
  @model.set '_page.registered', !(@model.get '_page.registered')

app.fn 'stocks.add', (e, el) ->
  newItem = @model.del '_page.newStock'
  return unless newItem
  newItem.creator = @model.get '_session.userId'
  @model.add 'stocks', newItem

app.fn 'stocks.remove', (e) ->
  id = e.get ':stock.id'
  @model.del 'stocks.' + id

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
  id = e.get ':stock.id'
  @model.del 'holdings.' + id

app.fn 'bids.add', (e) ->
  $model = @model
  newItem = $model.del '_page.newBid'
  return unless newItem
  find_id_by_name = (name) ->
    for stock in $model.get '_page.stocks'
      return stock.id if stock.name is name
  newItem['stock'] = find_id_by_name $('.bid-stock-select').val()
  newItem['amountLeft'] = newItem.amount
  newItem['creator'] = $model.get '_session.userId'
  $model.add "bids", newItem

app.fn 'bid.remove', (e) ->
  id = e.get ':bid.id'
  @model.del 'bids.' + id

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
