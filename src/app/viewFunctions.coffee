{ view } = require './index'

# View Functions
view.fn 'traderBalance', (trader) -> trader.balance
view.fn 'bidClass', (bid) -> if bid.amount > 0 then "bid-live" else "bid-dead"
