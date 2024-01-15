publishing_mqtt = false
publishing_http = false

watchdog = tmr.create()
push_timer = tmr.create()
chip_id = string.format("%06X", node.chipid())
device_id = "esp8266_" .. chip_id
mqtt_prefix = "sensor/" .. device_id
mqttclient = mqtt.Client(device_id, 120)

dofile("config.lua")

print("MAX44006 " .. chip_id)

ledpin = 4
gpio.mode(ledpin, gpio.OUTPUT)
gpio.write(ledpin, 0)

max44006 = require("max44006")
i2c.setup(0, 1, 2, i2c.SLOW)

function log_restart()
	print("Network error " .. wifi.sta.status())
end

function setup_client()
	print("Connected")
	gpio.write(ledpin, 1)
	max44006.start()
	publishing_mqtt = true
	mqttclient:publish(mqtt_prefix .. "/state", "online", 0, 1, function(client)
		publishing_mqtt = false
		push_timer:start()
	end)
end

function connect_mqtt()
	print("IP address: " .. wifi.sta.getip())
	print("Connecting to MQTT " .. mqtt_host)
	mqttclient:on("connect", hass_register)
	mqttclient:on("offline", log_restart)
	mqttclient:lwt(mqtt_prefix .. "/state", "offline", 0, 1)
	mqttclient:connect(mqtt_host)
end

function connect_wifi()
	print("WiFi MAC: " .. wifi.sta.getmac())
	print("Connecting to ESSID " .. station_cfg.ssid)
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, connect_mqtt)
	wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, log_restart)
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, log_restart)
	wifi.setmode(wifi.STATION)
	wifi.sta.config(station_cfg)
	wifi.sta.connect()
end

function push_data()
	if max44006.read() then
		local json_str = string.format('{"red_uwcm2": %f, "green_uwcm2": %f, "blue_uwcm2": %f, "clear_uwcm2": %f, "ir_uwcm2": %f, "rssi_dbm": %d}', max44006.red, max44006.green, max44006.blue, max44006.clear, max44006.ir, wifi.sta.getrssi())
		local influx_str = string.format("red_uwcm2=%f,green_uwcm2=%f,blue_uwcm2=%f,clear_uwcm2=%f,ir_uwcm2=%f", max44006.red, max44006.green, max44006.blue, max44006.clear, max44006.ir)
		if not publishing_mqtt then
			publishing_mqtt = true
			watchdog:start(true)
			gpio.write(ledpin, 0)
			mqttclient:publish(mqtt_prefix .. "/data", json_str, 0, 0, function(client)
				publishing_mqtt = false
				if influx_url and influx_attr and influx_str then
					publish_influx(influx_str)
				else
					gpio.write(ledpin, 1)
					collectgarbage()
				end
			end)
		end
	else
		print("MAX44006 error")
	end
end

function publish_influx(payload)
	if not publishing_http then
		publishing_http = true
		http.post(influx_url, influx_header, "max44006" .. influx_attr .. " " .. payload, function(code, data)
			publishing_http = false
			gpio.write(ledpin, 1)
			collectgarbage()
		end)
	end
end

function hass_register()
	local hass_device = string.format('{"connections":[["mac","%s"]],"identifiers":["%s"],"model":"ESP8266 + MAX44006","name":"MAX44006 %s","manufacturer":"derf"}', wifi.sta.getmac(), device_id, chip_id)
	local hass_entity_base = string.format('"device":%s,"state_topic":"%s/data","expire_after":600', hass_device, mqtt_prefix)
	local hass_red = string.format('{%s,"name":"Red","object_id":"%s_red","unique_id":"%s_red","device_class":"irradiance","unit_of_measurement":"µW/cm²","value_template":"{{value_json.red_uwcm2}}"}', hass_entity_base, device_id, device_id)
	local hass_green = string.format('{%s,"name":"Green","object_id":"%s_green","unique_id":"%s_green","device_class":"irradiance","unit_of_measurement":"µW/cm²","value_template":"{{value_json.green_uwcm2}}"}', hass_entity_base, device_id, device_id)
	local hass_blue = string.format('{%s,"name":"Blue","object_id":"%s_blue","unique_id":"%s_blue","device_class":"irradiance","unit_of_measurement":"µW/cm²","value_template":"{{value_json.blue_uwcm2}}"}', hass_entity_base, device_id, device_id)
	local hass_clear = string.format('{%s,"name":"Clear","object_id":"%s_clear","unique_id":"%s_clear","device_class":"irradiance","unit_of_measurement":"µW/cm²","value_template":"{{value_json.clear_uwcm2}}"}', hass_entity_base, device_id, device_id)
	local hass_ir = string.format('{%s,"name":"IR","object_id":"%s_ir","unique_id":"%s_ir","device_class":"irradiance","unit_of_measurement":"µW/cm²","value_template":"{{value_json.ir_uwcm2}}"}', hass_entity_base, device_id, device_id)
	local hass_rssi = string.format('{%s,"name":"RSSI","object_id":"%s_rssi","unique_id":"%s_rssi","device_class":"signal_strength","unit_of_measurement":"dBm","value_template":"{{value_json.rssi_dbm}}","entity_category":"diagnostic"}', hass_entity_base, device_id, device_id)

	mqttclient:publish("homeassistant/sensor/" .. device_id .. "/irradiance_red/config", hass_red, 0, 1, function(client)
		mqttclient:publish("homeassistant/sensor/" .. device_id .. "/irradiance_green/config", hass_green, 0, 1, function(client)
			mqttclient:publish("homeassistant/sensor/" .. device_id .. "/irradiance_blue/config", hass_blue, 0, 1, function(client)
				mqttclient:publish("homeassistant/sensor/" .. device_id .. "/irradiance_clear/config", hass_clear, 0, 1, function(client)
					mqttclient:publish("homeassistant/sensor/" .. device_id .. "/irradiance_ir/config", hass_ir, 0, 1, function(client)
						mqttclient:publish("homeassistant/sensor/" .. device_id .. "/rssi/config", hass_rssi, 0, 1, function(client)
							collectgarbage()
							setup_client()
						end)
					end)
				end)
			end)
		end)
	end)
end

watchdog:register(180 * 1000, tmr.ALARM_SEMI, node.restart)
push_timer:register(20 * 1000, tmr.ALARM_AUTO, push_data)
watchdog:start()

connect_wifi()
