print("Delaying startup for 2s...")
tmr.delay(2000 * 1000)

config = require("config")

pixels = require("pixels")
pixels.start()
pixels.setSingle(red)

segment = require("segment")
segment.start()

app = require("application")
setup = require("setup")

pixels.setSingle(orange)
setup.start()