#Temp module for enabing store hooks, until derby team will do it inn racer core

module.exports = (store) ->
  store.hook = (method, pattern, fn) ->
    store.shareClient.use 'after submit', (shareRequest, next) ->
      {opData} = shareRequest
      if opData.del || opData.create
        collectionName = pattern
        return next() unless collectionName is shareRequest.collection
      else # opData.op
        firstDot = pattern.indexOf('.')
        if firstDot is -1
          return next() unless patternToRegExp(pattern).test collectionName
        else
          collectionName = pattern.slice(0, firstDot)
          return next() unless collectionName is shareRequest.collection
      {snapshot, docName, backend} = shareRequest
      session = shareRequest.agent.connectSession
      switch method
        when 'del'
          return next() unless opData.del
          fn docName, shareRequest.prev.data, session, backend
        when 'create'
          return next() unless opData.create
          fn docName, shareRequest.snapshot.data, session, backend
        when 'change'
          for op in opData.op
            {p: segments} = op
            if op.si || op.sd
              # Omit the position in the string
              segments = segments.slice(0, -1)
            relPath = segments.join('.')
            fullPath = collectionName + '.' + docName + '.' + relPath
            regExp = patternToRegExp(pattern)
            matches = regExp.exec fullPath
            if matches
              fn matches.slice(1)..., lookup(segments, snapshot.data), op, session, backend
      next()

  store.onQuery = (collectionName, source, cb) ->
    this.shareClient.use 'query', (shareRequest, next) ->
      return next() unless shareRequest.options.backend is source

      session = shareRequest.agent.connectSession

      shareRequest.query = deepCopy(shareRequest.query)

      # TODO session
      if collectionName is '*'
        cb(shareRequest.collection, shareRequest.query, session, next)
      else
        cb(shareRequest.query, session, next)

patternToRegExp = (pattern) ->
  end = pattern.slice(pattern.length - 2, pattern.length)
  if end is '**'
    pattern = pattern.slice(0, pattern.length - 2)
  else
    end = ''
  pattern = pattern.replace(/\./g, "\\.").replace(/\*/g, "([^.]*)")
  new RegExp(pattern + if end then '.*' else '$')

lookup = (segments, doc) ->
  curr = doc
  for part in segments when curr isnt undefined
    curr = curr[part]
  return curr