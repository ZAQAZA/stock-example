{ view } = require './index'

# View Functions
view.fn 'isRegistered', (user) -> user.balance != undefined
view.fn 'bidClass', (bid) -> if bid.amount > 0 then "bid-live" else "bid-dead"
view.fn 'stockRowClass', (stock) ->
  if stock.change > 0
    "text-success"
  else if stock.change < 0
    "text-error"
  else
    "text-info"
