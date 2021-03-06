express = require 'express'
coffeeify = require 'coffeeify'
derby = require 'derby'
racerBrowserChannel = require 'racer-browserchannel'
liveDbMongo = require 'livedb-mongo'
MongoStore = require('connect-mongo')(express)
app = require '../app'
serverError = require './serverError'
mongoskin = require 'mongoskin'
publicDir = require('path').join __dirname + '/../../public'
conf = require 'nconf'
hooker = require './hook'
racerAccess = require 'racer-access'
market = require './market'
maker = require './maker'
access = require './accessControl'

expressApp = module.exports = express()

# Get Redis configuration
if process.env.REDISCLOUD_URL
  redisUrl = require('url').parse(process.env.REDISCLOUD_URL)
  redis = require('redis').createClient(redisUrl.port, redisUrl.hostname)
  redis.auth(redisUrl.auth.split(":")[1])
else if conf.get('REDIS_HOST')
  redis = require("redis").createClient conf.get('REDIS_PORT'), conf.get('REDIS_HOST')
  redis.auth conf.get('REDIS_PASSWORD')
else
  redis = require("redis").createClient()
redis.select conf.get('REDIS_DB')

# Get Mongo configuration
mongoUrl = if conf.get('NODE_ENV') is "production" then conf.get('MONGOHQ_URL') else conf.get('MONGO_URL_LOCAL')
mongo = liveDbMongo(mongoUrl + '?auto_reconnect', safe: true)

# The store creates models and syncs data
store = derby.createStore
  db:
    db: mongo
    redis: redis

store.on 'bundle', (browserify) ->
  browserify.transform coffeeify

derby.use racerAccess
access store
hooker store
market.subscribe store
maker.run store

###
(1)
Setup a hash of strategies you'll use - strategy objects and their configurations
Note, API keys should be stored as environment variables (eg, process.env.FACEBOOK_KEY) or you can use nconf to store
them in config.json, which we're doing here
###
auth = require('derby-auth')
strategies =
  facebook:
    strategy: require("passport-facebook").Strategy
    conf:
      clientID: conf.get('fb:appId')
      clientSecret: conf.get('fb:appSecret')

  linkedin:
    strategy: require("passport-linkedin").Strategy
    conf:
      consumerKey: conf.get('linkedin:apiKey')
      consumerSecret: conf.get('linkedin:apiSecret')

  github:
    strategy: require("passport-github").Strategy
    conf:
      clientID: conf.get('github:appId')
      clientSecret: conf.get('github:appSecret')
      # You can optionally pass in per-strategy configuration options (consult Passport documentation)
      callbackURL: "http://127.0.0.1:3000/auth/github/callback"

  twitter:
    strategy: require("passport-twitter").Strategy
    conf:
      consumerKey: conf.get('twit:consumerKey')
      consumerSecret: conf.get('twit:consumerSecret')
      callbackURL: "http://127.0.0.1:3000/auth/twitter/callback"

###
(1.5)
Optional parameters passed into auth.middleware(). Most of these will get sane defaults, so it's not entirely necessary
to pass in this object - but I want to show you here to give you a feel. @see derby-auth/middeware.coffee for options
###
options =
  passport:
    failureRedirect: '/'
    successRedirect: '/'
    #usernameField: 'email'
  site:
    domain: if conf.get('NODE_ENV') is "production" then conf.get('REMOTE_DOMAIN') else conf.get('LOCAL_DOMAIN')
    name: 'My Site'
    email: 'admin@mysite.com'
  smtp:
    service: 'Gmail'
    user: 'admin@mysite.com'
    pass: 'abc'
###
(2)
Initialize the store. This will add utility accessControl functions (see store.coffee for more details), as well
as the basic specific accessControl for the `auth` collection, which you can use as boilerplate for your own `users`
collection or what have you.
###
auth.store(store, mongo, strategies)

expressApp
    .use(express.favicon())
    .use(express.compress())
    .use(app.scripts(store))
    .use(express['static'](publicDir))
    .use(express.cookieParser())
    .use(express.session({
        secret: conf.get('SESSION_SECRET') || 'SOME SECRET SECRET'
        store: new MongoStore({
            url: mongoUrl
            safe: true
        })
    }))
    .use(express.bodyParser())
    .use(express.methodOverride())
    .use(racerBrowserChannel(store))
    .use(store.modelMiddleware())

    # (3)
    # derbyAuth.middleware is inserted after modelMiddleware and before the app router to pass server accessible data to a model
    # Pass in {store} (sets up accessControl & queries), {strategies} (see above), and options
    .use(auth.middleware(strategies, options))

    .use(app.router())
    .use(expressApp.router)
    .use(serverError())

expressApp.all "*", (req, res, next) -> next("404: #{req.url}")

