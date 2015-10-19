local module = {}
    -- https://github.com/adafruit/Adafruit-Raspberry-Pi-Python-Code/tree/master/Adafruit_LEDBackpack
    -- TODO
local numbertable = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71}
local displaybuffer = {}

local function send_singleValue(addr, reg, value)
  i2c.start(0)
  i2c.address(0, addr , i2c.TRANSMITTER)
  i2c.write(0,reg)
  i2c.write(0,value)
  i2c.stop(0)
end

local function send_displayBuffer(addr, reg)
  i2c.start(0)
  i2c.address(0, addr , i2c.TRANSMITTER)
  i2c.write(0,reg)
  for i=1,8 do
    i2c.write(0, bit.band(displaybuffer[i],0xFF))    
    i2c.write(0, bit.rshift(displaybuffer[i],8))
  end
  -- i2c.write(0,value)
  i2c.stop(0)
end

local function writeDigitRaw(d, bitmask)
  if (d > 5) then
    return
  end
  displaybuffer[d] = bitmask
end

local function writeDigitNum(d, num, dot)
  if (d > 5) then
    return
  end
  --print(d .. ": " .. numbertable[num+1] .. " - dot : " .. dot)
  writeDigitRaw(d, bit.bor(numbertable[num+1], bit.lshift(dot, 7)))
end

local function printFloat(n, fracDigits, base) 

  local numericDigits = 4   -- available digits on display
  
  -- calculate the factor required to shift all fractional digits
  -- into the integer part of the number
  local toIntFactor = 1.0
  for i=1,fracDigits do
    toIntFactor = toIntFactor * base
  end

  -- create integer containing digits to display by applying
  -- shifting factor and rounding adjustment
  local displayNumber = math.floor(n * toIntFactor + 0.5)
  
  -- calculate upper bound on displayNumber given
  -- available digits on display
  local tooBig = 1
  for i=1,numericDigits do
    tooBig = tooBig * base
  end

  -- if displayNumber is too large, try fewer fractional digits
  while(displayNumber >= tooBig) do
    fracDigits = fracDigits - 1
    toIntFactor = toIntFactor / base
    displayNumber = math.floor(n * toIntFactor + 0.5)
  end
    -- print(displayNumber)
  -- did toIntFactor shift the decimal off the display?
  if (toIntFactor < 1) then
    print("error; number too big")
  else
    -- otherwise, display the number
    local displayPos = 5

    for i=1,8 do
       displaybuffer[i] = 0x00
    end
        
    if (displayNumber > 0) then -- if displayNumber is not 0
      for i=displayPos,1,-1 do
          --print("---")
          --print(i)
        if (i == 3) then
          -- jump on middle colon
          writeDigitRaw(i, 0x00)
          --print("no semicolon")
        else 
          --print("number " .. displayNumber % base)
          local displayDecimal = (fracDigits ~= 0 and i == fracDigits) and 1 or 0
            --print(displayNumber)
            --print(displayDecimal)
          writeDigitNum(i, displayNumber % base, displayDecimal)
          displayNumber = math.floor(displayNumber / base)
        end
      end
    else
      writeDigitNum(displayPos, 0, false)
    end

  end

end

function module.print(float)
  printFloat(float, 2, 10)
  --for k,v in pairs(displaybuffer) do print(k,v) end
  send_displayBuffer(config.SEGMENT_ADDR, config.SEGMENT_WRITE_REG)
end

function module.start()
  -- i2c init for 7-segment
  i2c.setup(0,config.SEGMENT_PIN_SDA,config.SEGMENT_PIN_SCL,i2c.SLOW)

  -- Turn the oscillator on
  send_singleValue(config.SEGMENT_ADDR, bit.bor(0x20, 0x01), 0x00)

  -- Turn blink off
  send_singleValue(config.SEGMENT_ADDR, bit.bor(0x80,0x01, bit.lshift(0x00,1)), 0x00)

  -- Set maximum brightness
  send_singleValue(config.SEGMENT_ADDR, bit.bor(0xE0, 15), 0x00)
end

return module
