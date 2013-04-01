
module.exports = 
  userID: (model) ->
    model.get('_userId')
  subscribe: (model, renderCallback) ->
    userId = model.get('_userId')
    if userId
      model.subscribe "users.#{userId}", (err, user) ->
        if Object.keys(user.get('auth')).length != 0
          model.ref '_user', "users.#{userId}"
          renderCallback(true)
          return
    else
      renderCallback(false)
