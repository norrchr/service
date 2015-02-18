proc authban_on {channel nickname handle lastbind text} {
	if {[channel get $channel service_authban]} {
		putserv "NOTICE $nickname :Authbans is already \002enabled\002."
	} else {
		channel set $channel +service_authban
		putserv "NOTICE $nickname :Authbans is now \002enabled\002."
	}
}