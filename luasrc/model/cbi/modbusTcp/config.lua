local uci = require("luci.model.uci").cursor()

m = Map("modbusTcp", translate("Modbus TCP Bridge Configuration"),
    translate("Configure MQTT server settings for Southwest Jiaotong University PLC protocol"))

s = m:section(TypedSection, "global", translate("Global Settings"))
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable Service"))
enabled.default = "0"

poll = s:option(Value, "poll_interval", translate("Poll Interval (seconds)"))
poll.default = "10"
poll.datatype = "uinteger"

s = m:section(TypedSection, "mqtt", translate("MQTT Server Settings"))
s.anonymous = true
s.addremove = false

host = s:option(Value, "host", translate("MQTT Host"))
host.datatype = "host"

port = s:option(Value, "port", translate("MQTT Port"))
port.default = "1883"
port.datatype = "port"

user = s:option(Value, "username", translate("Username"))

pass = s:option(Value, "password", translate("Password"))
pass.password = true

topic = s:option(Value, "topic_prefix", translate("Topic Prefix"))
topic.default = "swjtu/plc/data"

return m
