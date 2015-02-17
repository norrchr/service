proc vip_on {channel nickname handle lastbind arg} {
	if {[channel get $channel service_vip]} {
		putserv "NOTICE $nickname :Vip is already \002enabled\002."
	} else {
		channel set $channel +service_vip
		putserv "NOTICE $nickname :Vip is now \002enabled\002."
	}
}