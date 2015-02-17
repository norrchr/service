proc vip_authbl_status {channel nickname handle lastbind text} {
	putserv "NOTICE $nickname :$channel vip-authbl is [expr {[channel get $channel service_vip_authbl] ? "enabled" : "disabled"}]. ([llength [channel get $channel service_vip_authblist]] auth(s) blacklisted)"
}