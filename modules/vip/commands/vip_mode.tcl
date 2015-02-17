proc vip_mode {channel nickname handle lastbind arg} {
	if {[channel get $channel service_vipm] == ""} {
		channel set $channel service_vipm "$[namespace parent]::vipmode"
	}
	set status "[lindex [split $text] 1]"
	if {$status == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind $option @/+."
	} elseif {![regexp {\@|\+} $status]} {
		putserv "NOTICE $nickname :Vip-mode must be one of '@ +'."
	} elseif {$status == [channel get $channel service_vipm]} {
		putserv "NOTICE $nickname :Vip-mode is already set to '$status'."
	} else {
		channel set $channel service_vipm "$status"
		putserv "NOTICE $nickname :Vip-mode is now set to '$status'."
	}
}