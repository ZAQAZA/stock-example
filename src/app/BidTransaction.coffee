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

  calculateTransactionValues: ->
    {buy, sell} = @sort()
    amount = Math.min buy.amountLeft, sell.amountLeft
    sum = amount * sell.price
    @values = {amount, sum}

  sort: ->
    buy: if @bid1.type is 'buy' then @bid1 else @bid2
    sell: if @bid1.type is 'sell' then @bid1 else @bid2

  collectExecutables: (callback) =>
    async.parallel @operations(), callback

  operations: => _.chain([
    @bidModifier
    @balanceModifier
    @holdingModifier
  ]).map(@modifierToOperation).map(@applyOnBids).flatten().value()

  applyOnBids: (creator) =>
    [async.apply(creator, @bid1), async.apply(creator, @bid2)]

  modifierToOperation: (modifier) =>
    async.apply @generalOperation, modifier

  generalOperation: (modifier, bid, callback) =>
    {fetch, test, modify} = modifier bid
    fetch (err) ->
      err = err || test() # test is not called if fetch returned an err
      callback err, modify # we return the modify function anyway but it shouldn't be executed if err is not null

  ##
  # Modifiers
  # A modifier ...
  ##
  bidModifier: (bid) =>
    fetch: (cb) -> cb()
    test: ->
    modify: =>
      bid.amountLeft -= @values.amount
      bid.save(@model)

  balanceModifier: (bid) =>
    $user = @model.at "auths.#{bid.user}"
    sum = if bid.type is 'sell' then @values.sum else -@values.sum

    fetch: (cb) -> $user.fetch(cb) # wanted to simply pass $user.fetch, but fetch is not bound to this.
    test: ->
      new Error('Not enough cash') if $user.get('balance') + sum < 0
    modify: -> $user.increment "balance", sum

  holdingModifier: (bid) =>
    delta = if bid.type is 'buy' then @values.amount else -@values.amount
    $query = @model.query 'holdings',
      user: bid.user
      stock: bid.stock
    holdings = -> $query.get()

    fetch: (cb) -> $query.fetch(cb)
    test: ->
      return new Error('Negative amount and no holding found!') if holdings().length is 0 and delta < 0
      return new Error('Not enough stocks') if holdings().length and holdings()[0].amount + delta < 0
    modify: =>
      return @model.add 'holdings', { user: bid.user, stock: bid.stock, amount: delta } unless holdings().length
      @model.increment("holdings.#{holdings()[0].id}.amount", delta)

module.exports = BidTransaction

