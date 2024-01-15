local max44006 = {}
local device_address = 0x45

max44006.bus_id = 0

function max44006.writeReg(reg, data)
	ret = true
	i2c.start(max44006.bus_id)
	if not i2c.address(max44006.bus_id, device_address, i2c.TRANSMITTER) then
		ret = false
	end
	i2c.write(max44006.bus_id, reg, data)
	i2c.stop(max44006.bus_id)
	return ret
end

function max44006.readReg(reg, len)
	ret = true
	i2c.start(max44006.bus_id)
	if not i2c.address(max44006.bus_id, device_address, i2c.TRANSMITTER) then
		ret = false
	end
	i2c.write(max44006.bus_id, reg)
	i2c.start(max44006.bus_id)
	if not i2c.address(max44006.bus_id, device_address, i2c.RECEIVER) then
		ret = false
	end
	local data = i2c.read(max44006.bus_id, len)
	i2c.stop(max44006.bus_id)
	return ret, data
end

function max44006.start()
	max44006.readReg(0x00, 1)
	max44006.readReg(0x00, 1)
	max44006.writeReg(0x01, 0x20)
	max44006.writeReg(0x02, 0x03)
end

function max44006.read()
	ret = true
	i2c.start(max44006.bus_id)
	if not i2c.address(max44006.bus_id, device_address, i2c.TRANSMITTER) then
		ret = false
	end
	i2c.write(max44006.bus_id, {0x04})
	--i2c.stop(max44006.bus_id)
	i2c.start(max44006.bus_id)
	if not i2c.address(max44006.bus_id, device_address, i2c.RECEIVER) then
		ret = false
	end
	local data = i2c.read(max44006.bus_id, 10)
	i2c.stop(max44006.bus_id)

	local mul = 0.512
	max44006.clear = (bit.lshift(string.byte(data, 1), 8) + string.byte(data, 2)) * mul
	max44006.red = (bit.lshift(string.byte(data, 3), 8) + string.byte(data, 4)) * mul
	max44006.green = (bit.lshift(string.byte(data, 5), 8) + string.byte(data, 6)) * mul
	max44006.blue = (bit.lshift(string.byte(data, 7), 8) + string.byte(data, 8)) * mul
	max44006.ir = (bit.lshift(string.byte(data, 9), 8) + string.byte(data, 10)) * mul
	return ret
end

return max44006
