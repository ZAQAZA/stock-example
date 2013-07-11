# Setup default env variables
conf = require('nconf')
conf.argv().file({ file: __dirname + "/config.json" }).env()

port = if conf.get('NODE_ENV') is 'production' then '80' else conf.get('PORT')
require('derby').run __dirname + '/src/server/index.coffee', port

###
#look at this for debugg
if (conf.get('NODE_ENV') === 'production' || conf.get('NODE_ENV') === 'debug') {
    require('./src/server').listen(conf.get('PORT'));
} else {
    require('derby').run(__dirname + '/src/server', conf.get('PORT'));
}
###

