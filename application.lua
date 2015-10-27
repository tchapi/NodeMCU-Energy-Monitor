local module = {}

local m = nil

-- We need to declare that global
local lastSampleI = 0
local sampleI = 0
local lastFilteredI = 0
local filteredI = 0
local sumI = 0
local sqI = 0

-- Calculates sampled I at RMS for a number of samples
local function calcIrms(NUMBER_OF_SAMPLES)

  sumI = 0
  
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

  local I_RATIO = config.I_CAL * ((config.SUPPLYVOLTAGE / 1000.0) / 1024) -- 1024 = 1<<10bits (10bits ADC)
  return math.max(0, I_RATIO * math.sqrt(sumI / NUMBER_OF_SAMPLES) - config.I_OFFSET)

end

local function calcTemperature()
    -- returns the temperature from one DS18S20 in DEG Celsius
    ow.setup(config.TEMP_PIN)
    count = 0
    repeat
      count = count + 1
      addr = ow.reset_search(config.TEMP_PIN)
      addr = ow.search(config.TEMP_PIN)
      tmr.wdclr()
    until((addr ~= nil) or (count > 100))

    if (addr == nil) then
      print("No more addresses.")
    else
      print(addr:byte(1,8))
      crc = ow.crc8(string.sub(addr,1,7))
      if (crc == addr:byte(8)) then
        if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
          -- print("Device is a DS18S20 family device.")
            repeat
              ow.reset(config.TEMP_PIN)
              ow.select(config.TEMP_PIN, addr)
              ow.write(config.TEMP_PIN, 0x44, 1)
              tmr.delay(1000000) -- 100ms
              present = ow.reset(config.TEMP_PIN)
              ow.select(config.TEMP_PIN, addr)
              ow.write(config.TEMP_PIN,0xBE,1)
              print("P="..present)  
              data = nil
              data = string.char(ow.read(config.TEMP_PIN))
              for i = 1, 8 do
                data = data .. string.char(ow.read(config.TEMP_PIN))
              end
              print(data:byte(1,9))
              crc = ow.crc8(string.sub(data,1,8))
              print("CRC="..crc)
              if (crc == data:byte(9)) then
                 t = (data:byte(1) + data:byte(2) * 256) * 625
                 t1 = t / 10000
                 print("Temperature="..t1.." deg C")
                return t1 
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

-- 
local function leds(power)
    local nb_leds = math.ceil(power / (config.MAX_CURRENT * config.VOLTAGE) * 6); -- + 2 leds at the start 
    local lit = pixels.green .. pixels.OFF .. string.sub(pixels.sequence, 1, nb_leds) .. pixels.OFF:rep(config.PIXELS - 2 - nb_leds)
    pixels.set(lit)
end

-- Sends data to the broker
local function send_data(power, temperature)
    pixels.set(pixels.green .. pixels.yellow) -- sample pixel only
    local s = string.format("id=%s&w=%d&t=%.2f",config.SENSOR_ID, power, temperature) 
    m:publish(config.DATA_ENDPOINT, s, 2, 0, function(client)
      pixels.set(pixels.green .. pixels.green) -- sample pixel only
      tmr.delay(500*1000)
      pixels.set(pixels.OFF .. pixels.OFF)
    end)
end

-- Displays data on the 7-seg and the leds
local function display_data(power, temperature)
    leds(power)
    segment.print(temperature,1)
end

local function sample()
    pixels.set(pixels.yellow .. pixels.OFF)
    local temperature = calcTemperature()
    local Irms = calcIrms(1480) -- Calculate Irms only
    local power = math.floor(Irms * config.VOLTAGE)
    
    display_data(power, temperature)
    send_data(power, temperature)
    -- Will be done by the publish callback
    -- pixels.set(pixels.OFF .. pixels.OFF)
end

-- Starts the sampling timer
local function sampling_start()
    print("Starting sampling")
    tmr.stop(6)
    tmr.alarm(6, config.SAMPLE_DELAY * 1000, 1, sample)
end

-- Starts the MQTT broker
local function mqtt_start()

    pixels.set(pixels.red:rep(2))
    m = mqtt.Client(config.SENSOR_ID, 120, config.USER, config.PASSWORD)
    
    m:on("message", function(conn, topic, data)
      pixels.set(pixels.OFF .. pixels.blue)
      if data ~= nil then
        print(topic .. ": " .. data)
        -- change display somehow to indicate message
        segment.dash()
      end
      tmr.delay(500*1000) -- just so we can see the light
      pixels.set(pixels.OFF .. pixels.OFF)
    end)

    pixels.set(pixels.orange:rep(4))
    
    m:connect(config.HOST, config.PORT, 0, function(con) 
        print("Connected to broker")
        pixels.set(pixels.yellow:rep(6))
        m:subscribe(config.CONTROL_ENDPOINT, 2, function(client)
            print("Subscribed to control endpoint with QoS 2")
            pixels.set(pixels.green:rep(8))
            sampling_start()
            pixels.clear()
            sample() -- once, for start
        end)
    end) 

end

function module.start()
    -- init Segment & leds
    segment.print(0,0)
    tmr.delay(500*1000)
    pixels.clear()
    mqtt_start()
end

return module
