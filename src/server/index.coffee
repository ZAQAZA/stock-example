http = require 'http'
path = require 'path'
express = require 'express'
derby = require 'derby'
racer = require 'racer'
auth = require 'derby-auth'
app = require '../app'
matcher = require '../app/matcher'
serverError = require './serverError'
io = racer.io

## SERVER CONFIGURATION ##

expressApp = express()
server = module.exports = http.createServer expressApp
module.exports.expressApp = expressApp

derby.use require('racer-db-mongo')

if process.env.NODE_ENV is 'development'
  racer.use(racer.logPlugin)
  derby.use(derby.logPlugin)

store = module.exports.pvStore = derby.createStore
  listen: server
  db:
    type: 'Mongo'
    uri: 'mongodb://localhost/stock-example'
    #uri: 'mongodb://nodejitsu:4c5fdb57ef0874339e8fa287e59ad2ff@linus.mongohq.com:10070/nodejitsudb1088662345'
    safe: true

auth.store store
matcher.subscribe store

store.query.expose 'bids', 'all', () ->
  this.where('amount').gt(-1);

ONE_YEAR = 1000 * 60 * 60 * 24 * 365
root = path.dirname path.dirname __dirname
publicPath = path.join root, 'public'

# Authentication setup
strategies =
  facebook:
    strategy: require("passport-facebook").Strategy
    conf:
      clientID: 'aaa' #process.env.FACEBOOK_KEY
      clientSecret: 'aaa' #process.env.FACEBOOK_SECRET

options =
  domain: process.env.BASE_URL || 'http://localhost:3000'

expressApp
  .use(express.favicon())
  # Gzip static files and serve from memory
  .use(express.static publicPath)
  # Gzip dynamically rendered content
  .use(express.compress())

  # Uncomment to add form data parsing support
  .use(express.bodyParser())
  .use(express.methodOverride())

  # Uncomment and supply secret to add Derby session handling
  # Derby session middleware creates req.session and socket.io sessions
  .use(express.cookieParser())
  .use(store.sessionMiddleware
    secret: process.env.SESSION_SECRET || 'session secret'
    cookie: {maxAge: ONE_YEAR}
  )

  # Adds req.getModel method
  .use(store.modelMiddleware())
  # Adds auth
  .use(auth.middleware(strategies, options))
  # Creates an express middleware from the app's routes
  .use(app.router())
  .use(expressApp.router)
  .use(serverError root)

routes = require './routes'

queries = require './queries'

# Infinite stack trace
Error.stackTraceLimit = Infinity

io.configure 'production', ->
  io.set "transports", ["websocket", "xhr-polling", "jsonp-polling", "htmlfile"]
