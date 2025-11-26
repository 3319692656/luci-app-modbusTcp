module("luci.controller.modbusTcp", package.seeall)

function index()
    entry({ "admin", "services", "modbusTcp" }, alias("admin", "services", "modbusTcp", "config"), _("Modbus TCP Bridge"),
        60)
    entry({ "admin", "services", "modbusTcp", "config" }, cbi("modbusTcp/config"), _("Configuration"), 10)
    entry({ "admin", "services", "modbusTcp", "devices" }, arcombine(cbi("modbusTcp/devices"), cbi("modbusTcp/device")),
        _("Devices"), 20)
    entry({ "admin", "services", "modbusTcp", "status" }, call("action_status"), _("Status"), 30)
    entry({ "admin", "services", "modbusTcp", "test" }, call("action_test_connection"), _("Test Connection"), 40)
    entry({ "admin", "services", "modbusTcp", "service" }, call("action_service"), nil)
end

function action_status()
    local http = require("luci.http")
    local sys = require("luci.sys")

    local status = {
        service_running = sys.call("pgrep -f '/usr/sbin/modbus_bridge' >/dev/null") == 0,
        last_update = sys.exec("date -r /tmp/modbus_last_update 2>/dev/null || echo 'Never'"),
        log_tail = sys.exec("tail -n 10 /tmp/modbus_bridge.log 2>/dev/null || echo 'No log available'")
    }

    http.prepare_content("application/json")
    http.write_json(status)
end

function action_service()
    local http = require("luci.http")
    local sys = require("luci.sys")
    local action = http.formvalue("action")

    if action == "start" then
        sys.call("/etc/init.d/modbus_bridge start >/dev/null 2>&1")
    elseif action == "stop" then
        sys.call("/etc/init.d/modbus_bridge stop >/dev/null 2>&1")
    elseif action == "restart" then
        sys.call("/etc/init.d/modbus_bridge restart >/dev/null 2>&1")
    end

    http.redirect(luci.dispatcher.build_url("admin/services/modbusTcp/status"))
end

function action_test_connection()
    local http = require("luci.http")
    local nixio = require("nixio")
    local json = require("luci.jsonc")

    local host = http.formvalue("host") or "127.0.0.1"
    local port = tonumber(http.formvalue("port")) or 502

    local sock = nixio.socket(nixio.AF_INET, nixio.SOCK_STREAM)
    sock:setopt(nixio.SOL_SOCKET, nixio.SO_RCVTIMEO, 5)

    local result = { success = false, message = "" }

    local ok, err = sock:connect(host, port)
    if ok then
        result.success = true
        result.message = "Modbus TCP connection successful on port 502"
        sock:close()
    else
        result.success = false
        result.message = "Connection failed: " .. tostring(err)
    end

    http.prepare_content("application/json")
    http.write_json(result)
end
