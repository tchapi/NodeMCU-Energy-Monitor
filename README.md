# NodeMCU-Energy-Monitor
A simple Lua-based current and temperature monitor

> This is the follow-up of https://github.com/tchapi/Arduino-Energy-Monitor

## The NodeMCU / Lua code

### To upload a new firmware :

For Rev 1 boards (larger)

    python esptool.py --port /dev/tty.wchusbserial1420 write_flash 0x00000 ../firmwares/nodemcu_float_0.9.6-dev_20150625.bin

For Rev2 Boards (AMICA)

    python esptool.py --baud 115200 --port /dev/tty.SLAB_USBtoUART write_flash -fm dio -fs 32m 0x00000 ../firmwares/nodemcu_float_0.9.6-dev_20150625.bin

### Installation and Node.js code

Please follow the steps at http://www.foobarflies.io/a-simple-connected-object-with-nodemcu-and-mqtt/, you'll be up and running in a few minutes.

### Notes

Before uploading to the device, don't forget to move `config.lua.dist` to `config.lua` with correct values. Same goes for `config.json.dist` in the `Server` directory.

## The Android App

You need to have **Android Studio 1.5**. Open the project and generate a signed APK, or run directly in an emulator.

Upon the first launch, you will need to input your MQTT broker's credentials, and the endpoints that you have chosen. This is done by clicking on the 'Settings' button. Once it's done, click 'Retry' and within 10 secs you should have the 'Active' status.
