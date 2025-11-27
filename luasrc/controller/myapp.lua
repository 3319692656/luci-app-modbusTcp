module("luci.controller.myapp.myapp", package.seeall)
 
function index()
    entry({"admin", "services", "myapp"}, cbi("myapp"), _("My Application"), 60).dependent = true
end