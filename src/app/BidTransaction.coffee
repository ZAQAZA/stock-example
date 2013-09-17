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
    @collectExecutables (err, executables) =>
      @executables = executables
      callback err, @

  execute: =>
    _(@executables).each (exe) -> exe()

  collectExecutables: (callback) =>
    async.parallel @operations(), callback

  operations: => _.chain([
    @bidModifier
    @balanceModifier
    @holdingModifier
  ]).map(@modifierToOperation).map(@applyOnBids).flatten().value()

  applyOnBids: (creator) =>
    [async.apply(creator, @bid1), async.apply(creator, @bid2)]

  modifierToOperation: (modifier) ->
    async.apply generalOperation, modifier

  generalOperation: (modifier, bid, callback) =>
    {test, fetch, modify} = modifier bid
    err = preTest()
    return callback err if err
    fetch (err) ->
      callback err, ->
        modify()

  bidModifier: (bid) =>
    test: ->
    fetch: (cb) -> cb()
    modify: =>
      bid.amountLeft -= @values.amount
      bid.save(@model)

  balanceModifier: (bid) =>
    $user = @model.at "auths.#{bid.user}"
    sum = if bid.type is 'sell' then @values.sum else -@values.sum
    test: ->
    fetch: $user.fetch
    modify: -> $user.increment "balance", sum

  holdingModifier: (bid) =>
    delta = if bid.type is 'buy' then @values.amount else -@values.amount
    $query = @model.query 'holdings',
      user: bid.user
      stock: bid.stock
    test: ->
    fetch: (cb) ->
      $query.fetch (err) ->
        cb(err) if err
        cb(new Error('negative amount and no holding found!')) if $query.get().length and delta < 0
    modify: =>
      return @model.increment("holdings.#{holdings[0].id}.amount", delta) if $query.get().length
      @model.add 'holdings', { user: bid.user, stock: bid.stock, amount: delta }

  calculateTransactionValues: ->
    {buy, sell} = @sort()
    amount = Math.min buy.amountLeft, sell.amountLeft
    sum = amount * sell.price
    @values = {amount, sum}

  sort: ->
    buy: if @bid1.type is 'buy' then @bid1 else @bid2
    sell: if @bid1.type is 'sell' then @bid1 else @bid2

module.exports = BidTransaction

