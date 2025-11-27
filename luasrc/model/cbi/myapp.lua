m = Map("myapp", "My Application Settings")
 
s = m:section(NamedSection, "general", "settings", "General Settings")
s.addremove = false
 
enable = s:option(Flag, "enabled", "Enable My Application")
enable.default = 0
 
port = s:option(Value, "port", "Listen Port")
port.datatype = "port"
port.default = "8080"
 
return m