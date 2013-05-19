if (process.env.NODE_ENV === 'production') {
  require('./src/bootstrap').listen(3001);
} else {
  //require('derby').run(__dirname + '/src/bootstrap', 3000);
  // ofri - i commented the above for debugging - the above is using the 'up' module which interfers with the debugger
  require('./src/bootstrap').listen(3001);
}
