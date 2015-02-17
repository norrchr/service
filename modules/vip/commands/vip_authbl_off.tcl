proc vip_authbl_off {channel nickname handle lastbind text} {
	if {![channel get $channel service_vip_authbl]} {
		putserv "NOTICE $nickname :$channel vip-authbl is already disabled."
	} else {
		channel set $channel -service_vip_authbl
		putserv "NOTICE $nickname :$channel vip-authbl is now disabled."
	}
}