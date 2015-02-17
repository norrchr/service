proc vip_authbl_on {channel nickname handle lastbind text} {
	if {[channel get $channel service_vip_authbl]} {
		putserv "NOTICE $nickname :$channel vip-authbl is already enabled."
	} else {
		channel set $channel +service_vip_authbl
		putserv "NOTICE $nickname :$channel vip-authbl is now enabled."
	}
}