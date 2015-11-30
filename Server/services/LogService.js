var fs = require('fs')

LogService = function(log_file) {
  this.log_file = log_file
}

var p = LogService.prototype

p.append = function(data) {

  var d = new Date()
  date = d.getFullYear() + "/" + ('0' + (d.getMonth()+1)).slice(-2) + "/" + ('0' + d.getDate()).slice(-2) + " " + d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds()

  // Format log
  /*
    Matching grok configuration :
    match => { "message" => "(?<timestamp>%{YEAR}/%{MONTHNUM:month}/%{MONTHDAY:day} %{TIME}) %{NUMBER:temperature} %{NUMBER:power} %{NUMBER:heap}" }
  */
  var log_message = date + " " + data.temperature + " " + data.power + " " + data.heap

  fs.appendFile(this.log_file, log_message + "\n", function (err) {
    if (err) {
      return 0
    } else {
      return 1
    }
  });
}

module.exports = LogService
