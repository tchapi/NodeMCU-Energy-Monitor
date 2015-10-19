var mqtt = require('mqtt')

MQTTService = function(options, log_service) {
  this.client  = mqtt.connect('mqtt://' + options.host + ':' + options.port, {username : options.user, password : options.password})
  this.control_endpoint = options.control_endpoint
  this.data_endpoint = options.data_endpoint

  this.client.on('connect', (function () {

    console.log("Connected to Broker at " + options.host)

    this.client.subscribe(this.data_endpoint)

    console.log("Backend is open to data on home/energy")

  }).bind(this))

  this.client.on('message', (function (topic, message) {

    //console.log("Message received [" + topic + ": " + message + "]")
    this.handle(topic, message)

  }).bind(this))

  this.log_service = log_service
}

var p = MQTTService.prototype

p.handle = function(topic, message) {
  if (topic == this.data_endpoint){
    message = message.toString('utf-8')
    tokens = message.split("&")
    //"id=" .. config.SENSOR_ID .. "&w=" .. power .. "&t=" .. temperature
    id = tokens[0].substring(3)
    w = tokens[1].substring(2)
    t = tokens[2].substring(2)
    //console.log("id = " + id + " - w = " + w + " - t = " + t)
    this.log_service.append({temperature: t, power: w})
  }
}

p.notify = function(sensor_id, message) {
  console.log(" -- notify(" + sensor_id + "):: " + message)
  this.client.publish(this.control_endpoint + '/' + sensor_id, message)
}

module.exports = MQTTService
