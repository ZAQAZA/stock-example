
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
          model.set '_usersIds', collectionIDs(users.get())
          model.refList '_users', users, "_usersIds"
          renderCallback(userId)
          return
    else
      renderCallback(false)

collectionIDs = (collection) ->
  (s for s of collection)

