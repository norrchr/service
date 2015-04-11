proc onsplt {nickname hostname handle channel} {
	variable netsplit_start
	if {[string equal -nocase Q $nickname] && ![channel get $channel service_netsplit]} {
		channel set $channel +service_netsplit
		channel set $channel service_netsplit_time "[unixtime]"
		putserv "PRIVMSG $channel :$netsplit_start"
	}
}