config = require("config")

gpio.mode(config.LEDS_PIN,gpio.OUTPUT)
ws2812.writergb(config.LEDS_PIN, string.char(255,255,255):rep(8))

segment = require("segment")
--app = require("application")
--setup = require("setup")

--setup.start()

segment.start()
tmr.delay(500)
segment.print(3.1)