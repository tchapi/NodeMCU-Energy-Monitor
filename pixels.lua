local module = {}

-- Colors
module.blue = string.char(2, 204, 253)
module.turquoise = string.char(2, 253, 141)
module.green = string.char(22, 254, 1)
module.yellow = string.char(184, 254, 1)
module.orange = string.char(255, 163, 0)
module.red = string.char(255, 0, 0)
module.white = string.char(255, 255, 255)
module.OFF = string.char(0, 0, 0)
module.sequence = module.OFF .. module.OFF .. module.blue .. module.turquoise .. module.green .. module.yellow .. module.orange .. module.red

function module.set(colors)
  ws2812.writergb(config.LEDS_PIN, colors)
end

function module.setSingle(color)
  ws2812.writergb(config.LEDS_PIN, color:rep(config.PIXELS))
end

function module.clear()
  module.set(module.OFF:rep(config.PIXELS))
end

function module.start()
  gpio.mode(config.LEDS_PIN,gpio.OUTPUT)
  module.clear()
end

return module
