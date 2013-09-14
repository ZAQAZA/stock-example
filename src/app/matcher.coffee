_ = require('underscore')
Bid = require "./Bid.coffee"

module.exports =
  subscribe: (store) ->
    store.hook 'create', 'bids', (bidId, newBid, op, session, backend) ->
      model = store.createModel()
      newBid = new Bid(newBid)

matcher = (bid) ->
  bid.fetchMatches model, (bids, err) ->
    throw err if err
    bid.fetch model, (bid, err) ->
      throw err if err
      match model, bid, bids

match = (model, bid, bids) ->
  unless bids.length
    console.log 'no match found'
    return
  execute model, bid, _.first(bids), (err) ->
    handleErr err
    match model, bid.reload(model), _.rest(bids)

findMatch = (bids, bid) ->
  match = bids[id] for id of bids when doesMatch(bids[id], bid)
  if match
    console.log 'found match:'
    console.log match
  match

doesMatch = (bid1, bid2) ->
  { sell, buy } = sort bid1, bid2
  ( sell && buy ) &&
    (bid1.amountLeft > 0 && bid2.amountLeft > 0) &&
    (bid1.stock == bid2.stock) &&
    (buy.price >= sell.price)

sort = (bid1, bid2) ->
  sell = bid1 if bid1.type == 'sell'
  sell = bid2 if bid2.type == 'sell'
  buy = bid1 if bid1.type == 'buy'
  buy = bid2 if bid2.type == 'buy'
  sell: sell
  buy: buy

# think about a db transaction.. this entire function
# should execute as atomic operation
execute = (model, bid1, bid2) ->
  {sell, buy} = sort bid1, bid2
  amount = min sell.amountLeft, buy.amountLeft
  sell.amountLeft -= amount
  buy.amountLeft -= amount
  sum = amount * min sell.price, buy.price
  stock = sell.stock
  if amount > 0
    (updateBid model, b) for b in [sell, buy]
    updateBalance model, sell.user, sum
    updateBalance model, buy.user, -sum
    model.subscribe 'holdings', (err) ->
      throw err if err
      updateHolding model, sell.user, stock, -amount
      updateHolding model, buy.user, stock, amount

updateBid = (model, bid) ->
  model.set "bids.#{bid.id}.amountLeft", bid.amountLeft

updateBalance = (model, userID, delta) ->
  $user = model.at "auths.#{userID}"
  $user.subscribe (err) ->
    throw err if err
    $user.increment 'balance', delta

updateHolding = (model, userID, stock, delta) ->
  holdingQuery = model.query 'holdings',
    user: userID
    stock: stock
  holdingQuery.fetch (err) ->
    throw err if err
    holdings = holdingQuery.get()
    if holdings.length
      id = holdings[0].id
      model.increment "holdings.#{id}.amount", delta
    else
      throw new Error('negative amount and no holding found!') if delta < 0
      model.add 'holdings',
        user: userID
        stock: stock
        amount: delta

min = (a,b) ->
  if a<=b then a else b
