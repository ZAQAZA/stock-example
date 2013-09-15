_ = require('underscore')
async = require('async')
##
# The BidTransaction class
# Used to execute a transaction between two users in a transaction manner.
# The transaction first make all tests that are blocking, then performs
# the actual transaction in a non blocking way.
##
class BidTransaction
  @create: (model, bid1, bid2, callback) ->
    new BidTransaction model, bid1, bid2, (err, transaction) ->
      callback err, transaction

  # An async constructor
  # This means you can only use the object inside the callback!
  constructor: (@model, @bid1, @bid2, callback) ->
    @calculateTransactionValues()
    @collectExecutables (err, executables) ->
      @executables = executables
      callback err, @

  execute: ->
    _(@executables).each (exe) -> exe()

  # The operations needed to complete a transaction
  # All operations take (model, bid1, bid2)
  # and return a set of executables creators
  operations: [
    @updateBids
    @updateBalance
    @updateHolding
  ]

  collectExecutables: (callback) ->
    exeCreators = _(@operations).map((op) -> op()).flatten()
    async.parallel exeCreators, callback

  duplicateCreator: (creator) ->
    [async.apply(creator, @bid1), async.apply(creator, @bid2)]

  updateBid: ->
    @duplicateCreator (bid, callback) ->
      callback null, ->
        bid.amountLeft -= @values.amount
        bid.save(model)

  updateBalance: ->
    @duplicateCreator (bid, callback) ->
      sum = if bid.type is 'sell' then @values.sum else -@values.sum
      $user = @model.at "auths.#{bid.user}"
      $user.fetch (err) ->
        return callback(err) if err
        callback null, ->
          $user.increment "balance", sum

  updateHolding: ->
    @duplicateCreator (bid, callback) ->
      delta = if bid.type is 'buy' then @values.amount else -@values.amount
      $holdingQuery = @model.query 'holdings',
        user: bid.user
        stock: bid.stock
      $holdingQuery.fetch (err) ->
        return callback(err) if err
        holdings = $holdingQuery.get()
        if holdings.length
          id = holdings[0].id
          callback null, ->
            model.increment "holdings.#{id}.amount", delta
        else
          callback(new Error('negative amount and no holding found!')) if delta < 0
          callback null, ->
            model.add 'holdings',
              user: bid.user
              stock: bid.stock
              amount: delta

  calculateTransactionValues: ->
    {buy, sell} = @sort()
    amount = Math.min buy.amountLeft, sell.amountLeft
    sum = amount * sell.price
    @values = {amount, sum}

  sort: ->
    buy: if @bid1.type is 'buy' then @bid1 else @bid2
    sell: if @bid1.type is 'sell' then @bid1 else @bid2



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

module.exports = BidTransaction

