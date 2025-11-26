m = Map("modbusTcp", translate("Modbus TCP Devices"),
    translate("Configure Modbus TCP devices using Southwest Jiaotong University protocol"))

s = m:section(TypedSection, "device", translate("Modbus Devices"))
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true

name = s:option(Value, "name", translate("Device Name"))
name.datatype = "string"

host = s:option(Value, "host", translate("Modbus Host"))
host.placeholder = "192.168.1.100"
host.datatype = "host"

port = s:option(Value, "port", translate("Modbus Port"))
port.default = "502"
port.datatype = "port"

slave = s:option(Value, "slave_id", translate("Slave ID"))
slave.default = "1"
slave.datatype = "uinteger"

func_code = s:option(ListValue, "function_code", translate("Function Code"))
func_code:value("1", "01 - Read Coils")
func_code:value("3", "03 - Read Holding Registers")
func_code.default = "3"

start_addr = s:option(Value, "start_addr", translate("Start Address"))
start_addr.default = "0"
start_addr.datatype = "uinteger"

count = s:option(Value, "count", translate("Data Count"))
count.default = "10"
count.datatype = "uinteger"

interval = s:option(Value, "poll_interval", translate("Poll Interval (seconds)"))
interval.default = "10"
interval.datatype = "uinteger"

return m
