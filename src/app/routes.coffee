{ get, post } = require './index'
controller = require './controller'

## ROUTES ##

get '/', controller.portal
get '/admin', controller.admin
get '/stocks', controller.stocks
