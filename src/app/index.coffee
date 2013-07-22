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

withUser = (model, callback) ->
  model.set '_page.registered', true
  userId = model.get "_session.userId"
  unless userId
    callback()
    return
  $user = model.at "auths.#{userId}"
  $username = $user.at "local.username"
  $balance = $user.at "balance"
  $inventory = $user.at "stocks"
  bidsQuery = model.query "bids",
    creator: userId
  model.subscribe $user, bidsQuery, (err) ->
    throw err if err
    $balance.setNull '', 1000.0
    model.ref "_page.user.local", $user.at "local"
    model.ref "_page.user.name", $username
    model.ref "_page.user.balance", $balance
    model.ref "_page.user.inventory", $inventory
    bidsQuery.ref "_page.user.bids"
    callback()

withStocks = (model, callback) ->
  stocksQ = model.query 'stocks', {}
  stocksQ.subscribe (err) ->
    throw err if err
    stocksQ.ref '_page.stocks'
    callback()

withBids = (model, callback) ->
  q = model.query 'bids', {}
  q.subscribe (err) ->
    throw err if err
    q.ref '_page.user.bids'
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

app.get '/bids', (page, model) ->
  withContexts model, ->
    page.render 'bids'
  , [withUser, withStocks]

app.enter '/bids', (model) ->
  $('select').selectpicker()

app.get '/admin', (page, model) ->
  withContexts model, ->
    page.render 'admin'
  , [withUser, withStocks]

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
  userId = @model.get '_session.userId'
  inventory = @model.get "auths.#{userId}.stocks"
  for item, i in inventory || []
    toRemove = i if item.stock is id
  removed = @model.remove "auths.#{userId}.stocks", toRemove if toRemove?
  @model.push "auths.#{userId}.stocks",
    stock: id
    amount: if removed then removed[0].amount + 1 else 1

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
