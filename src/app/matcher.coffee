
module.exports = 
  subscribe: (store) ->
    store.afterDb 'set', 'bids.*', (txn, newBid, previousDoc, done) ->
      store.get 'bids', (err, bids) ->
        matcher store, bids, newBid
        done()

matcher = (store, bids, bid) ->
  matchedBid = findMatch bids, bid
  unless matchedBid
    console.log 'no match found'
    return
  execute store, bid, matchedBid

findMatch = (bids, bid) ->
  match = bids[id] for id of bids when doesMatch(bids[id], bid)
  if match
    console.log 'found match:'
    console.log match
  match

doesMatch = (bid1, bid2) ->
  { sell, buy } = sort bid1, bid2
  ( sell && buy ) &&
    (bid1.amount > 0 && bid2.amount > 0) &&
    (bid1.stock == bid2.stock) &&
    (buy.price >= sell.price)

sort = (bid1, bid2) ->
  sell = bid1 if bid1.type == 'sell'
  sell = bid2 if bid2.type == 'sell'
  buy = bid1 if bid1.type == 'buy'
  buy = bid2 if bid2.type == 'buy'
  sell: sell
  buy: buy

execute = (store, bid1, bid2) ->
  {sell, buy} = sort bid1, bid2
  amount = min sell.amount, buy.amount
  sell.amount -= amount
  buy.amount -= amount
  sum = amount * min sell.price, buy.price
  stock = sell.stock
  # think about a db transaction.. the following operations should execute together
  if amount > 0
    updateBid store, b for b in [sell, buy]
    updateBalance store, sell.user, sum
    updateBalance store, buy.user, -sum
    updateHolding store, sell.user, stock, -amount
    updateHolding store, buy.user, stock, amount

updateBid = (store, bid) ->
  store.set 'bids.'+bid.id, bid

updateBalance = (store, userID, delta) ->
  balancePath = "users.#{userID}.balance"
  store.get balancePath, (err, b) ->
    store.set balancePath, b+delta

updateHolding = (store, userID, stock, delta) ->
  update = (s) ->
    s.amount += delta
  holdingPath = "users.#{userID}.stockHoldings"
  store.get holdingPath, (err, h) ->
    update s for s in h when s.stock == stock
    store.set holdingPath, h

min = (a,b) ->
  if a<=b then a else b

