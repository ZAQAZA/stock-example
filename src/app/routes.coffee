{ get, post } = require './index'
controller = require './controller'

## ROUTES ##

get '/', controller.index
get '/add_bid', controller.add_bid
