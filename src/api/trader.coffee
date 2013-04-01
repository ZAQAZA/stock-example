derby = require 'derby'
market = require './market_init'


controller =
  index: (page, model) ->

    market.subscribe model, ->
      trader.subscribe model, ->
      userId = model.get('_userId')
      if userId
        model.subscribe "users.#{userId}", (err, user) ->
          if Object.keys(user.get('auth')).length != 0
            console.log('ofri ' + user.get('auth'))
            model.ref '_user', "users.#{userId}"
          page.render 'index'
      else
        page.render 'index'

module.exports = controller

# import ready callback
require './ready'

# import view functions
require './viewFunctions'
