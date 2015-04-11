proc onrejn {nickname hostname handle channel} {
	variable netsplit_end
	if {[string equal -nocase Q $nickname] && [channel get $channel service_netsplit]} {
		channel set $channel -service_netsplit
		set time [duration [expr {[unixtime] - [channel get $channel service_netsplit_time]}]]
		channel set $channel service_netsplit_time ""
		regsub -all :time: $netsplit_end $time msg
		putserv "PRIVMSG $channel :$msg"
	}
}