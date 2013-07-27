
module.exports =
  subscribe: (store) ->
    store.hook 'create', 'bids', (bidId, newBid, op, session, backend) ->
      model = store.createModel()
      model.fetch 'bids', (err) ->
        throw err if err
        bids = model.get 'bids'
        matcher model, bids, newBid

matcher = (model, bids, bid) ->
  matchedBid = findMatch bids, bid
  unless matchedBid
    console.log 'no match found'
    return
  execute model, bid, matchedBid

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

# think about a db transaction.. this entire function should execute as atomic operation
execute = (model, bid1, bid2) ->
  {sell, buy} = sort bid1, bid2
  amount = min sell.amountLeft, buy.amountLeft
  sell.amountLeft -= amount
  buy.amountLeft -= amount
  sum = amount * min sell.price, buy.price
  stock = sell.stock
  if amount > 0
    (updateBid model, b) for b in [sell, buy]
    #updateBalance model, sell.user, sum
    #updateBalance model, buy.user, -sum
    #updateHolding model, sell.user, stock, -amount
    #updateHolding model, buy.user, stock, amount

updateBid = (model, bid) ->
  model.set 'bids.'+bid.id, bid

updateBalance = (model, userID, delta) ->
  balancePath = "users.#{userID}.balance"
  model.get balancePath, (err, b) ->
    model.set balancePath, b+delta

updateHolding = (model, userID, stock, delta) ->
  update = (s) ->
    s.amount += delta
  holdingPath = "users.#{userID}.stockHoldings"
  model.get holdingPath, (err, h) ->
    update s for s in h when s.stock == stock
    model.set holdingPath, h

min = (a,b) ->
  if a<=b then a else b
  ###
