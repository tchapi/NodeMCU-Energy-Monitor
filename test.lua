config = require("config")

gpio.mode(config.LEDS_PIN,gpio.OUTPUT)
ws2812.writergb(config.LEDS_PIN, string.char(255,255,255):rep(8))

app = require("application")
setup = require("setup")

setup.start()
