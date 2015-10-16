print("Delaying startup for 2s...")
tmr.delay(2000 * 1000)

config = require("config")

gpio.mode(config.LEDS_PIN,gpio.OUTPUT)
ws2812.writergb(config.LEDS_PIN, string.char(255,255,255):rep(8))

i2c = require("i2c")
app = require("application")
setup = require("setup")

setup.start()
