# NodeMCU-Energy-Monitor
A simple Lua-based current and temperature monitor

This is the follow-up of https://github.com/tchapi/Arduino-Energy-Monitor

Pins :
7 segment -> i2c -> SDA / SCL ?
Leds -> pin GPIO simple
Current sensor -> ADC 0 on ESP8266
Temperature -> one-wire, pin 9, DS18B20, https://www.sparkfun.com/products/245

### Installation

Please follow the steps at http://www.foobarflies.io/a-simple-connected-object-with-nodemcu-and-mqtt/, you'll be up and running in a few minutes.

### Notes

Before uploading to the device, move `config.lua.dist` to `config.lua` with correct values.
