var express = require('express')
var app = express()

// Require the filsystem extension for writing the log
var fs = require('fs')

// Read config file
var data = fs.readFileSync('config.json'),
    config

try {
  config = JSON.parse(data)
} catch (err) {
  console.log('There has been an error parsing the config file.')
  throw err
}

// Add log wrapper
var LogService = require('./services/LogService')
  , ls = new LogService(config.LOG_FILE)

// Add MQTT Service
var MQTTService = require('./services/MQTTService')
  , m = new MQTTService(config.mqtt, ls)


// Start application
var server = app.listen(3000, function () {

  var host = server.address().address
  var port = server.address().port

  console.log('Starting data API at http://%s:%s', host, port)

})
