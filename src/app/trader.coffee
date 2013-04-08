
module.exports = 
  bootstrap: (model) ->
    'dd'
  userID: (model) ->
    model.get('_userId')
  subscribe: (model, renderCallback) ->
    userId = model.get('_userId')
    if userId
      model.subscribe "users", (err, users) ->
        if Object.keys(users.get("#{userId}.auth")).length != 0
          model.ref '_user', "users.#{userId}"
          renderCallback(userId)
          return
    else
      renderCallback(false)
