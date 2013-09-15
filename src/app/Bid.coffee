_ = require('underscore')
##
# The Bid model
# Used for bids related operations
##
class Bid
  # A static method used as constractor that is also
  # fetchs the bid to the model.
  @fetch: (model, bidId, callback) ->
    $bid = model.at "bids.#{bidId}"
    $bid.fetch (err) ->
      return callback(err, null) if err
      callback null, new Bid($bid.get())

  constructor: (jsonBid) ->
    @id = jsonBid.id
    @stock = jsonBid.stock
    @amount = jsonBid.amount
    @amountLeft = jsonBid.amountLeft
    @price = jsonBid.price
    @type = jsonBid.type
    @user = jsonBid.user

  asJson: ->
    id: @id
    stock: @stock
    amount: @amount
    amountLeft: @amountLeft
    price: @price
    type: @type
    user: @user

  fetch: (model, callback) ->
    $bid = model.at "bids.#{@id}"
    $bid.fetch (err) ->
      return callback(err, null) if err
      callback null, $bid.get()

  reload: (model) ->
    new Bid(model.get "bids.#{@id}")

  save: (model) ->
    model.setDiff "bids.#{@id}", @asJson()

  fetchMatches: (model, callback) =>
    query = model.query 'bids', @matchesQueryObj()
    query.fetch (err) ->
      callback err, _(query.get()).map((b)->new Bid(b))

  matchesQueryObj: ->
    if @type is 'buy'
      $query:
        type: 'sell'
        stock: @stock
        price: {$lte: @price}
        amountLeft: {$gt: 0}
      $orderby:
        price: 1
    else
      $query:
        type: 'buy'
        stock: @stock
        price: {$gte: @price}
        amountLeft: {$gt: 0}
      $orderby:
        price: -1

module.exports = Bid
