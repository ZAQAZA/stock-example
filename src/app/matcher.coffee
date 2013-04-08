
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
  if execute bid, matchedBid
    update store, b for b in [bid, matchedBid]

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

execute = (bid1, bid2) ->
  amount = min bid1.amount, bid2.amount
  bid1.amount -= amount
  bid2.amount -= amount
  amount > 0

update = (store, bid) ->
  store.set 'bids.'+bid.id, bid

min = (a,b) ->
  if a<=b then a else b

