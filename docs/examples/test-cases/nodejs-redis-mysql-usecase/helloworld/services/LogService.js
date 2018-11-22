const log4js = require('log4js');
log4js.configure({
  appenders: { helloworld: { type: 'file', filename: 'helloworld.log' } },
  categories: { default: { appenders: ['helloworld'], level: 'debug' } },
  pm2: true
});

const logger = log4js.getLogger('helloworld');

module.exports = logger;