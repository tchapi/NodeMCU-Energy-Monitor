config = require("config")
print("1")
print(node.heap())

pixels = require("pixels")
  pixels.start()
  pixels.setSingle(pixels.red)
print("2")
print(node.heap())

segment = require("segment")
  segment.start()
print("3")
print(node.heap())

app = require("application")
print("4")
print(node.heap())

setup = require("setup")
print("5")
print(node.heap())

pixels.setSingle(pixels.orange)
setup.start()
