proc vip_default {channel nickname handle lastbind arg} {
	set vip [expr {[channel get $channel service_vip] ? "enabled" : "disabled"}]
	set vips [expr {[channel get $channel service_vips] ? "enabled" : "disabled"}]
	set vipn [expr {[channel get $channel service_vipn] ? "enabled" : "disabled"}]
	set vipa [expr {[channel get $channel service_vip_authed] ? "enabled" : "disabled"}]
	set vipab [expr {[channel get $channel service_vip_authbl] ? "enabled" : "disabled"}]
	set vipcm [expr {[channel get $channel service_vip_chanmode] ? "enabled" : "disabled"}]
	set vipdm [expr {[channel get $channel service_vip_dynamicmode] ? "enabled" : "disabled"}]
	if {[set vipm [channel get $channel service_vipm]] == ""} {
		channel set $channel service_vipm "[set vipm $[namespace parent]::vipmode]"
	}
	if {[set vipid [channel get $channel service_vipid]] == ""} {
		channel set $channel service_vipid "[set vipid 0]"
	}
	putserv "NOTICE $nickname :Vip is: \002$vip\002 - Vip-skin is: \002$vips\002 - Vip-notice is: \002$vipn\002 - Vip-mode is: \002$vipm\002 - Vip-id is: \002#$vipid\002 - Vip-channel(s): \002[llength [channel get $channel service_vipc]]\002."
	putserv "NOTICE $nickname :Vip-authed is: \002$vipa\002 - Vip-authblacklist is: \002$vipab\002 - \002[llength [channel get $channel service_vip_authblist]] blacklisted auth(s)\002. Vip-chanmode is: \002$vipcm\002. Vip-dynamicmode is: \002$vipdm\002."
	putserv "NOTICE $nickname :Syntax: $lastbind on|off|add|del|set|list|authbl|mode ?arguments?."
}