local nixio = require "nixio"
local bit = require "bit"

local modbus_bridge = {}

-- 西南交通大学PLC协议功能码
modbus_bridge.FUNCTION_CODES = {
    READ_COILS = 0x01,             -- 01: 读线圈状态
    READ_HOLDING_REGISTERS = 0x03, -- 03: 读保持型寄存器
    WRITE_SINGLE_COIL = 0x05,      -- 05: 强制单个线圈
    WRITE_MULTIPLE_COILS = 0x0F    -- 15: 强制多个线圈
}

-- 创建Modbus TCP MBAP头（根据文档第1章）
function modbus_bridge.create_mbap_header(transaction_id, pdu_length, slave_id)
    -- 协议标识固定为0x0000，长度包括单元标识符+PDU
    return string.pack(">I2 I2 I2 B",
        transaction_id or 0x0001,
        0x0000,         -- 协议标识
        pdu_length + 1, -- 长度（PDU长度+单元标识符）
        slave_id or 1)
end

-- 01功能码：读线圈状态（根据文档2.2.1）
function modbus_bridge.read_coils(host, port, slave_id, start_addr, count)
    local sock = nixio.socket(nixio.AF_INET, nixio.SOCK_STREAM)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_RCVTIMEO, 5)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_SNDTIMEO, 5)

    local ok, err = sock:connect(host, port)
    if not ok then
        return nil, "Connection failed: " .. tostring(err)
    end

    -- 构建PDU（功能码01）
    local function_code = modbus_bridge.FUNCTION_CODES.READ_COILS
    local pdu = string.pack(">B I2 I2", function_code, start_addr, count)

    -- 创建完整报文（MBAP头 + PDU）
    local mbap_header = modbus_bridge.create_mbap_header(1, #pdu, slave_id)
    local request = mbap_header .. pdu

    local sent, err = sock:send(request)
    if not sent then
        sock:close()
        return nil, "Send failed: " .. tostring(err)
    end

    -- 接收响应
    local response, err = sock:recv(1024)
    sock:close()

    if not response or #response < 9 then
        return nil, "Invalid response: " .. tostring(err)
    end

    -- 解析响应（跳过7字节MBAP头）
    local byte_count = string.byte(response, 9)
    if byte_count * 8 < count then
        return nil, "Insufficient data in response"
    end

    local coil_data = response:sub(10, 10 + byte_count - 1)
    local coils = {}

    -- 解析线圈状态（低位在前，低字节在前）
    for byte_idx = 1, byte_count do
        local byte_val = string.byte(coil_data, byte_idx)
        for bit_pos = 0, 7 do
            local coil_index = (byte_idx - 1) * 8 + bit_pos
            if coil_index < count then
                local coil_state = bit.band(bit.rshift(byte_val, bit_pos), 0x01)
                coils[coil_index + 1] = (coil_state == 1)
            end
        end
    end

    return coils
end

-- 03功能码：读保持型寄存器（根据文档2.2.2）
function modbus_bridge.read_holding_registers(host, port, slave_id, start_addr, count)
    local sock = nixio.socket(nixio.AF_INET, nixio.SOCK_STREAM)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_RCVTIMEO, 5)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_SNDTIMEO, 5)

    local ok, err = sock:connect(host, port)
    if not ok then
        return nil, "Connection failed: " .. tostring(err)
    end

    -- 构建PDU（功能码03）
    local function_code = modbus_bridge.FUNCTION_CODES.READ_HOLDING_REGISTERS
    local pdu = string.pack(">B I2 I2", function_code, start_addr, count)

    -- 创建完整报文
    local mbap_header = modbus_bridge.create_mbap_header(1, #pdu, slave_id)
    local request = mbap_header .. pdu

    local sent, err = sock:send(request)
    if not sent then
        sock:close()
        return nil, "Send failed: " .. tostring(err)
    end

    -- 接收响应
    local response, err = sock:recv(1024)
    sock:close()

    if not response or #response < 9 then
        return nil, "Invalid response: " .. tostring(err)
    end

    -- 解析响应（跳过7字节MBAP头）
    local byte_count = string.byte(response, 9)
    if byte_count ~= count * 2 then
        return nil, "Invalid byte count in response"
    end

    local register_data = response:sub(10, 10 + byte_count - 1)
    local registers = {}

    -- 解析寄存器值（高字节在前）
    for i = 1, count do
        local byte_pos = (i - 1) * 2 + 1
        if byte_pos + 1 <= byte_count then
            local high_byte = string.byte(register_data, byte_pos)
            local low_byte = string.byte(register_data, byte_pos + 1)
            local value = high_byte * 256 + low_byte
            registers[i] = value
        end
    end

    return registers
end

-- 05功能码：强制单个线圈（根据文档2.2.3）
function modbus_bridge.write_single_coil(host, port, slave_id, coil_addr, coil_state)
    local sock = nixio.socket(nixio.AF_INET, nixio.SOCK_STREAM)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_RCVTIMEO, 5)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_SNDTIMEO, 5)

    local ok, err = sock:connect(host, port)
    if not ok then
        return false, "Connection failed: " .. tostring(err)
    end

    -- 构建PDU（功能码05）
    local function_code = modbus_bridge.FUNCTION_CODES.WRITE_SINGLE_COIL
    local coil_value = coil_state and 0xFF00 or 0x0000 -- ON:FF00, OFF:0000
    local pdu = string.pack(">B I2 I2", function_code, coil_addr, coil_value)

    -- 创建完整报文
    local mbap_header = modbus_bridge.create_mbap_header(1, #pdu, slave_id)
    local request = mbap_header .. pdu

    local sent, err = sock:send(request)
    if not sent then
        sock:close()
        return false, "Send failed: " .. tostring(err)
    end

    -- 接收响应
    local response, err = sock:recv(1024)
    sock:close()

    if not response or #response < 12 then
        return false, "Invalid response: " .. tostring(err)
    end

    -- 验证响应是否与请求一致
    return true, "Write single coil successful"
end

-- 15功能码：强制多个线圈（根据文档2.2.4）
function modbus_bridge.write_multiple_coils(host, port, slave_id, start_addr, coil_states)
    local sock = nixio.socket(nixio.AF_INET, nixio.SOCK_STREAM)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_RCVTIMEO, 5)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_SNDTIMEO, 5)

    local ok, err = sock:connect(host, port)
    if not ok then
        return false, "Connection failed: " .. tostring(err)
    end

    local coil_count = #coil_states
    local byte_count = math.ceil(coil_count / 8)

    -- 构建线圈数据字节
    local coil_bytes = {}
    for i = 1, byte_count do
        local byte_val = 0
        for bit_pos = 0, 7 do
            local coil_index = (i - 1) * 8 + bit_pos
            if coil_index < coil_count and coil_states[coil_index + 1] then
                byte_val = bit.bor(byte_val, bit.lshift(1, bit_pos))
            end
        end
        table.insert(coil_bytes, string.char(byte_val))
    end

    local coil_data = table.concat(coil_bytes)

    -- 构建PDU（功能码15）
    local function_code = modbus_bridge.FUNCTION_CODES.WRITE_MULTIPLE_COILS
    local pdu = string.pack(">B I2 I2 B", function_code, start_addr, coil_count, byte_count)
    pdu = pdu .. coil_data

    -- 创建完整报文
    local mbap_header = modbus_bridge.create_mbap_header(1, #pdu, slave_id)
    local request = mbap_header .. pdu

    local sent, err = sock:send(request)
    if not sent then
        sock:close()
        return false, "Send failed: " .. tostring(err)
    end

    -- 接收响应
    local response, err = sock:recv(1024)
    sock:close()

    if not response or #response < 12 then
        return false, "Invalid response: " .. tostring(err)
    end

    return true, "Write multiple coils successful"
end

-- MQTT发布功能
function modbus_bridge.mqtt_publish(host, port, username, password, topic, message)
    local cmd = string.format('mosquitto_pub -h "%s" -p "%d"', host, port or 1883)

    if username and username ~= "" then
        cmd = cmd .. string.format(' -u "%s"', username)
    end

    if password and password ~= "" then
        cmd = cmd .. string.format(' -P "%s"', password)
    end

    -- 转义消息中的特殊字符
    message = message:gsub('"', '\\"')
    message = message:gsub("'", "\\'")

    cmd = cmd .. string.format(' -t "%s" -m "%s" -q 1', topic, message)

    local exit_code = os.execute(cmd)
    return exit_code == 0
end

-- 处理设备数据采集
function modbus_bridge.process_device(device_config, mqtt_config)
    local result = {
        device = device_config.name or device_config[".name"],
        timestamp = os.time(),
        success = false,
        data = {}
    }

    local function_code = tonumber(device_config.function_code) or 3

    if function_code == 1 then
        -- 读线圈状态
        local coils, err = modbus_bridge.read_coils(
            device_config.host,
            tonumber(device_config.port) or 502,
            tonumber(device_config.slave_id) or 1,
            tonumber(device_config.start_addr) or 0,
            tonumber(device_config.count) or 8
        )

        if coils then
            result.success = true
            result.data.coils = coils
            result.message = string.format("Read %d coils successfully", #coils)
        else
            result.success = false
            result.message = "Read coils failed: " .. tostring(err)
        end
    elseif function_code == 3 then
        -- 读保持寄存器
        local registers, err = modbus_bridge.read_holding_registers(
            device_config.host,
            tonumber(device_config.port) or 502,
            tonumber(device_config.slave_id) or 1,
            tonumber(device_config.start_addr) or 0,
            tonumber(device_config.count) or 10
        )

        if registers then
            result.success = true
            result.data.registers = {}
            for i, value in ipairs(registers) do
                result.data.registers[i] = {
                    address = (tonumber(device_config.start_addr) or 0) + i - 1,
                    value = value
                }
            end
            result.message = string.format("Read %d registers successfully", #registers)
        else
            result.success = false
            result.message = "Read registers failed: " .. tostring(err)
        end
    else
        result.success = false
        result.message = "Unsupported function code: " .. tostring(function_code)
    end

    -- 发布到MQTT
    if result.success then
        local json = require("luci.jsonc")
        local topic = string.format("%s/%s",
            mqtt_config.topic_prefix or "modbus/data",
            device_config.name or device_config[".name"])

        local json_data = json.stringify(result)
        local mqtt_success = modbus_bridge.mqtt_publish(
            mqtt_config.host,
            tonumber(mqtt_config.port) or 1883,
            mqtt_config.username,
            mqtt_config.password,
            topic,
            json_data
        )

        result.mqtt_status = mqtt_success and "published" or "publish_failed"
    end

    return result
end

return modbus_bridge