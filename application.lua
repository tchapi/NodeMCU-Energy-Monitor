local module = {}

-- Colors
blue = string.char(2, 204, 253)
turquoise = string.char(2, 253, 141)
green = string.char(22, 254, 1)
yellow = string.char(184, 254, 1)
orange = string.char(255, 163, 0)
red = string.char(255, 0, 0)
white = string.char(255, 255, 255)
OFF = string.char(0, 0, 0)
sequence = OFF .. OFF .. blue .. turquoise .. green .. yellow .. orange .. red;

-- We need to declare that global
local lastSampleI, sampleI
local lastFilteredI, filteredI, sumI, sqI, Irms

-- Calculates sampled I at RMS for a number of samples
local function calcIrms(NUMBER_OF_SAMPLES)

  -- We need a correct voltage reference
  local SUPPLYVOLTAGE = adc.readvdd33()

  sumI = 0;

  for n=0,NUMBER_OF_SAMPLES do

    -- Store previous values
    lastSampleI = sampleI
    lastFilteredI = filteredI

    -- Sample
    sampleI = adc.read(0)

    -- Apply a digital high pass filters to remove 2.5V DC offset (centered on 0V).
    filteredI = 0.996 * (lastFilteredI + sampleI - lastSampleI)

    -- Root-mean-square method current
    -- 1) square current values
    sqI = filteredI * filteredI
    -- 2) sum
    sumI = sumI + sqI
  end

  local I_RATIO = config.I_CAL * ((SUPPLYVOLTAGE / 1000.0) / (1024)) -- 1024 = 1<<10bits (10bits ADC)
  return math.max(0, I_RATIO * math.sqrt(sumI / NUMBER_OF_SAMPLES) - config.I_OFFSET)

end

local function calcTemperature()
    -- returns the temperature from one DS18S20 in DEG Celsius
    ow.setup(TEMP_PIN)
    count = 0
    repeat
      count = count + 1
      addr = ow.reset_search(TEMP_PIN)
      addr = ow.search(TEMP_PIN)
      tmr.wdclr()
    until((addr ~= nil) or (count > 100))

    if (addr == nil) then
      print("No more addresses.")
    else
      print(addr:byte(1,8))
      crc = ow.crc8(string.sub(addr,1,7))
      if (crc == addr:byte(8)) then
        if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
          print("Device is a DS18S20 family device.")
            repeat
              ow.reset(TEMP_PIN)
              ow.select(TEMP_PIN, addr)
              ow.write(TEMP_PIN, 0x44, 1)
              tmr.delay(1000000) -- 100ms
              present = ow.reset(TEMP_PIN)
              ow.select(TEMP_PIN, addr)
              ow.write(TEMP_PIN,0xBE,1)
              print("P="..present)  
              data = nil
              data = string.char(ow.read(TEMP_PIN))
              for i = 1, 8 do
                data = data .. string.char(ow.read(TEMP_PIN))
              end
              print(data:byte(1,9))
              crc = ow.crc8(string.sub(data,1,8))
              print("CRC="..crc)
              if (crc == data:byte(9)) then
                 t = (data:byte(1) + data:byte(2) * 256) * 625
                 t1 = t / 10000
                 t2 = t % 10000
                 print("Temperature="..t1.."."..t2.."Centigrade")
                return t / 10000 
              end                   
              tmr.wdclr()
            until false
        else
          print("Device family is not recognized.")
        end
      else
        print("CRC is not valid!")
      end
    end

end

-- split strings
function split(inputstr, sep)
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- 
local function leds(power)
    local nb_leds = math.ceil(power / (config.MAX_CURRENT * config.VOLTAGE) * 6) + 2; -- + 2 leds at the start 
    local lit = strsub(sequence, 1, nb_leds) .. OFF:rep(config.PIXELS - nb_leds)
    ws2812.writergb(config.LEDS_PIN, lit)
end

local function sample()
    local temperature = calcTemperature()
    local Irms = calcIrms(1480) -- Calculate Irms only
    local power = math.floor(Irms * config.VOLTAGE)

    display_data(power, temperature)
    send_data(power, temperature)
end

-- Sends data to the broker
local function send_data(power, temperature)
    m:publish(config.ENDPOINT, "id=" .. config.SENSOR_ID .. "&w=" .. power .. "&t=" .. temperature,0,0)
end

-- Displays data on the 7-seg and the leds
local function display_data(power, temperature)
    leds(watt)
    segment(temperature)
end

-- Starts the MQTT broker
local function mqtt_start()

    m = mqtt.Client(config.ID, 120, config.USER, config.PASSWORD)
    
    m:on("message", function(conn, topic, data) 
      if data ~= nil then
        print(topic .. ": " .. data)
        local d = split(data, "-")
        -- change display
        -- segment(d[2])
      end
    end)
    
    m:connect(config.HOST, config.PORT, 0, 1, function(con) 
        print("Connected to broker")
        sampling_start()
    end) 

end

local function sampling_start()
    tmr.stop(3)
    tmr.alarm(3, config.SAMPLE_DELAY * 1000, 1, sample)
end

function module.start()
    -- init Segment & leds
    segment.print(12.34)
    leds(0) 
    mqtt_start()
end

return module
