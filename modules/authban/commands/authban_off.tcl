proc authban_off {channel nickname handle lastbind text} {
	if {![channel get $channel service_authban]} {
		putserv "NOTICE $nickname :Authbans is already \002disabled\002."
	} else {
		channel set $channel -service_authban
		putserv "NOTICE $nickname :Authbans is now \002disabled\002."
	}
}