# ESP8266 Lua/NodeMCU module for MAX44006 irradiance sensors

[esp8266-nodemcu-max44006](https://finalrewind.org/projects/esp8266-nodemcu-max44006/)
provides an ESP8266 NodeMCU Lua module (`max44006.lua`) as well as MQTT /
HomeAssistant / InfluxDB integration example (`init.lua`) for **MAX44006**
irradiance sensors connected via I²C.

## Dependencies

max44006.lua has been tested with Lua 5.1 on NodeMCU firmware 3.0.1 (Release
202112300746, float build). It requires the following modules.

* bit
* i2c

Most practical applications (such as the example in init.lua) also need the
following modules.

* gpio
* mqtt
* node
* tmr
* wifi

## Setup

Connect the MAX44006 sensor to your ESP8266/NodeMCU board as follows.

* MAX44006 GND → ESP8266/NodeMCU GND
* MAX44006 VCC → ESP8266/NodeMCU 3V3
* MAX44006 SDA → NodeMCU D1 (ESP8266 GPIO5)
* MAX44006 SCL → NodeMCU D2 (ESP8266 GPIO4)

If you use different pins for SCL and SDA, you need to adjust the i2c.setup
call in the examples provided in this repository to reflect those changes. Keep
in mind that some ESP8266 pins must have well-defined logic levels at boot time
and may therefore be unsuitable for MAX44006 connection.

## Usage

Copy **max44006.lua** to your NodeMCU board and set it up as follows.

```lua
max44006 = require("max44006")
i2c.setup(0, 1, 2, i2c.SLOW)
max44006.start()

-- can be called with up to 10 Hz
function some_timer_callback()
	if max44006.read() then
		-- All values are float
		-- Maximum value is for 1677 blue and 8388 for others
		-- max44006.red   : Irradiance on Red channel [µW/cm²]
		-- max44006.green : Irradiance on Green channel [µW/cm²]
		-- max44006.blue  : Irradiance on Blue channel [µW/cm²]
		-- max44006.clear : Irradiance on Clear channel [µW/cm²]
		-- max44006.ir    : Irradiance on IR channel [µW/cm²]
	else
		print("MAX44006 error")
	end
end
```

## Application Example

**init.lua** is an example application with HomeAssistant integration.
To use it, you need to create a **config.lua** file with WiFI and MQTT settings:

```lua
station_cfg = {ssid = "...", pwd = "..."}
mqtt_host = "..."
```

Optionally, it can also publish readings to InfluxDB.
To do so, configure URL and attribute:

```lua
influx_url = "..."
influx_attr = "..."
```

Readings will be published as `max44006[influx_attr] red_uwcm2=%f,green_uwcm2=%f,blue_uwcm2=%f,clear_uwcm2=%f,ir_uwcm2=%f`.
So, unless `influx_attr = ''`, it must start with a comma, e.g. `influx_attr = ',device=' .. device_id`.

## Images

![](https://finalrewind.org/projects/esp8266-nodemcu-max44006/media/hass.png)

## References

Mirrors of the esp8266-nodemcu-max44006 repository are maintained at the following locations:

* [Chaosdorf](https://chaosdorf.de/git/derf/esp8266-nodemcu-max44006)
* [Finalrewind](https://git.finalrewind.org/derf/esp8266-nodemcu-max44006)
* [GitHub](https://github.com/derf/esp8266-nodemcu-max44006)
