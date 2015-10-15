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

-- split strings
function split(inputstr, sep)
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- Led
local function ws(colors)
    ws2812.writergb(config.LEDS_PIN, colors)
end

-- 
local function leds(watts)
    local nb_leds = math.ceil(watts / (config.MAX_CURRENT * config.VOLTAGE) * 6) + 2; -- + 2 leds at the start 
    local lit = strsub(sequence, 1, nb_leds )
    ws(lit)
end

local function segment(data)
    i2c.write(0,data)
end

local function sample()
    -- sample only w for now
    temperature = 25.2
    local watts = adc.read(0)
    display_data(watts, temperature)
    send_data(watts, temperature)
end

-- Sends data to the broker
local function send_data(watts, temperature)
    m:publish(config.ENDPOINT, "id=" .. config.SENSOR_ID .. "&w=" .. watts .. "&t=" .. temperature,0,0)
end

-- Displays data on the 7-seg and the leds
local function display_data(watts, temperature)
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

    -- i2c init for 7-segment
    i2c.setup(0,config.SEGMENT_PIN_SDA,config.SEGMENT_PIN_SCL,i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x70, i2c.TRANSMITTER)
    segment(12.34) -- test

    -- init for LEDS, W = 0 at first
    leds(0)

    mqtt_start()

end

return module
