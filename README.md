# NodeMCU-Energy-Monitor
A simple Lua-based current and temperature monitor

This is the follow-up of https://github.com/tchapi/Arduino-Energy-Monitor

### To upload a new firmware :

// For Rev 1 boards (larger)
python esptool.py --port /dev/tty.wchusbserial1420 write_flash 0x00000 ../firmwares/nodemcu_float_0.9.6-dev_20150625.bin

// For Rev2 Boards (AMICA)
python esptool.py --baud 115200 --port /dev/tty.SLAB_USBtoUART write_flash -fm dio -fs 32m 0x00000 ../firmwares/nodemcu_float_0.9.6-dev_20150625.bin


// Specific :
python /Users/tchap/Documents/home/docs/Outils/ESP\ —\ NodeMCU/esptool-master/esptool.py --baud 115200 --port /dev/tty.SLAB_USBtoUART write_flash -fm dio -fs 32m 0x00000 /Users/tchap/Documents/home/www/Current\ \&\ Temp\ Logger\ v2/nodemcu-dev-11-modules-2015-10-20-10-34-40-float.bin

### Installation

Please follow the steps at http://www.foobarflies.io/a-simple-connected-object-with-nodemcu-and-mqtt/, you'll be up and running in a few minutes.

### Notes

Before uploading to the device, move `config.lua.dist` to `config.lua` with correct values.
