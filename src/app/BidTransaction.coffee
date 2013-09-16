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
    exeCreators = _.chain(@operations()).map((op) -> op()).flatten().value()
    async.parallel exeCreators, callback

  # The operations needed to complete a transaction
  # All operations take (model, bid1, bid2)
  # and return a set of executables creators
  operations: => [
    @updateBids
    @updateBalances
    @updateHoldings
  ]

  duplicateCreator: (creator) =>
    [async.apply(creator, @bid1), async.apply(creator, @bid2)]

  updateBids: =>
    @duplicateCreator (bid, callback) =>
      callback null, =>
        bid.amountLeft -= @values.amount
        bid.save(@model)

  updateBalances: =>
    @duplicateCreator (bid, callback) =>
      sum = if bid.type is 'sell' then @values.sum else -@values.sum
      $user = @model.at "auths.#{bid.user}"
      $user.fetch (err) ->
        return callback(err) if err
        callback null, ->
          $user.increment "balance", sum

  updateHoldings: =>
    @duplicateCreator (bid, callback) =>
      delta = if bid.type is 'buy' then @values.amount else -@values.amount
      $holdingQuery = @model.query 'holdings',
        user: bid.user
        stock: bid.stock
      $holdingQuery.fetch (err) =>
        return callback(err) if err
        holdings = $holdingQuery.get()
        if holdings.length
          id = holdings[0].id
          callback null, =>
            @model.increment "holdings.#{id}.amount", delta
        else
          callback(new Error('negative amount and no holding found!')) if delta < 0
          callback null, =>
            @model.add 'holdings',
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

module.exports = BidTransaction

