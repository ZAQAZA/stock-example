{ view } = require './index'

# View Functions
view.fn 'isRegistered', (user) -> user.balance != undefined
view.fn 'bidClass', (bid) -> if bid.amount > 0 then "bid-live" else "bid-dead"
