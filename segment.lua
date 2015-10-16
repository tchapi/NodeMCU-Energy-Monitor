local module = {}
    -- https://github.com/adafruit/Adafruit-Raspberry-Pi-Python-Code/tree/master/Adafruit_LEDBackpack
    -- TODO
local numbertable = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71}
local displaybuffer = {}

function module.print(float)
  printFloat(float, 0, 10)
  send_displayBuffer(SEGMENT_ADDR, SEGMENT_WRITE_REG)
end

local function send_displayBuffer(addr, reg, value)
  i2c.start(0)
  i2c.address(0, addr , i2c.TRANSMITTER)
  i2c.write(0,reg)
  for i=0,8 do
    i2c.write(0, bit.band(displaybuffer[i],0xFF));    
    i2c.write(0, bit.rshift(displaybuffer[i],8)); 
  end
  -- i2c.write(0,value)
  i2c.stop(0)
end

local function writeDigitRaw(d, bitmask)
  if (d > 4) then
    return
  end
  displaybuffer[d] = bitmask
end

local function writeDigitNum( d, num, dot)
  if (d > 4) then
    return
  end
  writeDigitRaw(d, bit.bor(numbertable[num + 1], bit.lshift(dot, 7)))
end

local function printFloat(n, fracDigits, base) 

  local numericDigits = 4   -- available digits on display
  
  -- calculate the factor required to shift all fractional digits
  -- into the integer part of the number
  local toIntFactor = 1.0
  for i=0,fracDigits do
    toIntFactor = toIntFactor * base
  end

  -- create integer containing digits to display by applying
  -- shifting factor and rounding adjustment
  local displayNumber = n * toIntFactor + 0.5
  
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
    displayNumber = n * toIntFactor + 0.5
  end
  
  -- did toIntFactor shift the decimal off the display?
  if (toIntFactor < 1) then
    print("error")
  else
    -- otherwise, display the number
    local displayPos = 4
    
    if (displayNumber) then -- if displayNumber is not 0
      for i=1,displayNumber do
        if (i <= fracDigits) then break end
        local displayDecimal = (fracDigits ~= 0 and i == fracDigits)
        displayPos = displayPos - 1
        writeDigitNum(displayPos, displayNumber % base, displayDecimal)
        if(displayPos == 2) then
          displayPos = displayPos - 1
          writeDigitRaw(displayPos, 0x00)
        end
        displayNumber = displayNumber / base
      end
    else
      displayPos = displayPos - 1
      writeDigitNum(displayPos, 0, false)
    end
  
    -- clear remaining display positions
    while(displayPos >= 0) do
      displayPos = displayPos - 1
      writeDigitRaw(displayPos, 0x00)
    end

  end

end

function module.start()
  -- i2c init for 7-segment
  i2c.setup(0,config.SEGMENT_PIN_SDA,config.SEGMENT_PIN_SCL,i2c.SLOW)
end

return module