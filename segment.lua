local module = {}

local numbertable = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71}
local displaybuffer = {}
local numericDigits = 4 -- available digits on display

local function sendSingleValue(addr, reg, value)
  i2c.start(0)
  i2c.address(0, addr , i2c.TRANSMITTER)
  i2c.write(0,reg)
  i2c.write(0,value)
  i2c.stop(0)
end

local function sendDisplayBuffer(addr, reg)
  i2c.start(0)
  i2c.address(0, addr , i2c.TRANSMITTER)
  i2c.write(0,reg)
  for i=1,numericDigits + 1 do
    i2c.write(0, bit.band(displaybuffer[i],0xFF))    
    i2c.write(0, bit.rshift(displaybuffer[i],8))
  end
  i2c.stop(0)
end

local function writeDigitRaw(d, bitmask)
  if (d > numericDigits + 1) then
    return
  end
  displaybuffer[d] = bitmask
end

local function writeDigitNum(d, num, dot)
  writeDigitRaw(d, bit.bor(numbertable[num+1], bit.lshift(dot, 7)))
end

local function printFloat(n, fracDigits, base) 

  fracDigits = math.max(0,math.min(fracDigits, numericDigits - 1))
  
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
    print("error on 7-segment; number too big")
  else
    -- otherwise, display the number
    local displayPos = numericDigits + 1

    for i=1,displayPos do
       displaybuffer[i] = 0 -- fill with zeros
    end
        
    if (displayNumber > 0) then -- if displayNumber is not 0
      for i=displayPos,1,-1 do
          --print("---")
          --print(i)
        if (i == 3) then
          -- jump the middle colon
          writeDigitRaw(i, 0x00)
          fracDigits = fracDigits + 1
          --print("no semicolon")
        else 
          --print("number " .. displayNumber % base)
          local displayDecimal = (fracDigits ~= 0 and i == (displayPos - fracDigits)) and 1 or 0
            --print(displayNumber)
            --print(displayDecimal)
            if (displayNumber % base ~= 0 or i >= (displayPos - fracDigits)) then
                writeDigitNum(i, displayNumber % base, displayDecimal)
            end
          displayNumber = math.floor(displayNumber / base)
        end
      end
    else
      writeDigitNum(displayPos, 0, 0)
    end

  end

end

function module.print(float, precision)
  printFloat(float, precision, 10)
  --for k,v in pairs(displaybuffer) do print(k,v) end
  sendDisplayBuffer(config.SEGMENT_ADDR, config.SEGMENT_WRITE_REG)
end

function module.setBrightness(value)
  sendSingleValue(config.SEGMENT_ADDR, bit.bor(0xE0, math.max(1,math.min(15,value))), 0x00)
end

function module.start()
  -- i2c init for 7-segment
  i2c.setup(0,config.SEGMENT_PIN_SDA,config.SEGMENT_PIN_SCL,i2c.SLOW)

  -- Turn the oscillator on
  sendSingleValue(config.SEGMENT_ADDR, bit.bor(0x20, 0x01), 0x00)

  -- Turn blink off
  sendSingleValue(config.SEGMENT_ADDR, bit.bor(0x80,0x01, bit.lshift(0x00,1)), 0x00)

  -- Set maximum brightness
  sendSingleValue(config.SEGMENT_ADDR, bit.bor(0xE0, 5), 0x00)
end

return module
