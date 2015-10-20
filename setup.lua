local module = {}

local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")

    pixels.setSingle(pixels.green)
    segment.clear()
    segment.setBrightness(10)
    app.start()
  end
end

local function wifi_start(list_aps)
    if list_aps then
        for key,value in pairs(list_aps) do
            if config.SSID and config.SSID[key] then
                wifi.setmode(wifi.STATION)
                wifi.sta.config(key,config.SSID[key])
                wifi.sta.connect()
                print("Connecting to " .. key .. " ...")
                --config.SSID = nil  -- more secure and save memory
                tmr.alarm(1, 2500, 1, wifi_wait_ip)
            end
        end
    else
        print("Error getting AP list")
    end
end

function module.start()
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION)
  pixels.setSingle(pixels.yellow)
  wifi.sta.getap(wifi_start)
end

return module
