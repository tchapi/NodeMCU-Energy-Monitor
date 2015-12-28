local module = {}

-- Colors
module.blue = string.char(2*config.BRIGHT, 204*config.BRIGHT, 253*config.BRIGHT)
module.turquoise = string.char(2*config.BRIGHT, 253*config.BRIGHT, 141*config.BRIGHT)
module.green = string.char(22*config.BRIGHT, 254*config.BRIGHT, 1*config.BRIGHT)
module.yellow = string.char(184*config.BRIGHT, 254*config.BRIGHT, 1*config.BRIGHT)
module.orange = string.char(255*config.BRIGHT, 163*config.BRIGHT, 0*config.BRIGHT)
module.red = string.char(255*config.BRIGHT, 0*config.BRIGHT, 0*config.BRIGHT)
module.white = string.char(255*config.BRIGHT, 255*config.BRIGHT, 255*config.BRIGHT)
module.OFF = string.char(0, 0, 0)
module.sequence = module.blue .. module.turquoise .. module.green .. module.yellow .. module.orange .. module.red

-- Just to check that bright works correctly
print(module.sequence)

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
