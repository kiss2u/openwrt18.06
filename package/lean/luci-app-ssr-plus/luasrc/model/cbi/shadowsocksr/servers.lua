-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocksr = "shadowsocksr"

local uci = luci.model.uci.cursor()
local server_count = 0
uci:foreach("shadowsocksr", "servers", function(s)
  server_count = server_count + 1
end)

m = Map(shadowsocksr,  translate("Servers subscription and manage"))

-- Server Subscribe

s = m:section(TypedSection, "server_subscribe")
s.anonymous = true

o = s:option(Flag, "auto_update", translate("Auto Update"))
o.rmempty = false
o.description = translate("Auto Update Server subscription, GFW list and CHN route")

o = s:option(Flag, "v2ray_update", translate("Enable V2ray Update"))
o.rmempty = false

o = s:option(ListValue, "auto_update_time", translate("Update time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default=2
o.rmempty = false

o = s:option(ListValue, "edition", translate("Edition"))
o:value("auto_detected", "Auto Detected")
o:value("4.20.0", "4.20.0")
o:value("4.19.1", "4.19.1")
o:value("4.18.2", "4.18.2")
o:value("4.18.1", "4.18.1")
o:value("4.18.0", "4.18.0")
o.rmempty = false

o = s:option(Value, "v2ray_path", translate("V2ray Path"))
o.default = "/usr/bin/v2ray"
o.rmempty = true
o.description = translate("After modifying the path, you need to download v2ray manually")

o = s:option(Button,"update_v2ray",translate("Manual Upgrade V2ray"))
o.inputstyle = "reload"
o.write = function()
  luci.sys.call("bash /usr/share/shadowsocksr/v2ray_update1.sh >>/tmp/ssrplus.log 2>&1")
end

o = s:option(DynamicList, "subscribe_url", translate("Subscribe URL"))
o.rmempty = true

o = s:option(Flag, "proxy", translate("Through proxy update"))
o.rmempty = false
o.description = translate("Through proxy update list, Not Recommended ")

o = s:option(Button,"update",translate("Update"))
o.inputstyle = "reload"
o.write = function()
  luci.sys.call("bash /usr/share/shadowsocksr/subscribe.sh >>/tmp/ssrplus.log 2>&1")
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shadowsocksr", "servers"))
end

o = s:option(Button,"delete",translate("Delete all severs"))
o.inputstyle = "reset"
o.description = string.format(translate("Server Count") ..  ": %d", server_count)
o.write = function()
  uci:delete_all("shadowsocksr", "servers", function(s) return true end)
  luci.sys.call("uci commit shadowsocksr && /etc/init.d/shadowsocksr stop") 
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shadowsocksr", "servers"))
end

-- [[ Servers Manage ]]--
s = m:section(TypedSection, "servers")
s.anonymous = true
s.addremove = true
s.sortable = false
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/services/shadowsocksr/servers/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "type", translate("Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("")
end

o = s:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server", translate("Server Address"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Server Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

if nixio.fs.access("/usr/bin/ssr-kcptun") then

o = s:option(DummyValue, "kcp_enable", translate("KcpTun"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

end

o = s:option(DummyValue, "switch_enable", translate("Auto Switch"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = s:option(DummyValue, "weight", translate("weight"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = s:option(DummyValue,"server",translate("Ping Latency"))
o.template="shadowsocksr/ping"

m:append(Template("shadowsocksr/server_list"))

return m
