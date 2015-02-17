proc vip_set_chanmode {channel nickname handle lastbind text} {
	set subcommand [string tolower [lindex [split $text] 0]]
	set status [channel get $channel service_vip_chanmode]
	if {$subcommand eq "on"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel vip-chanmode is already enabled."
		} else {
			channel set $channel +service_vip_chanmode
			putserv "NOTICE $nickname :$channel vip-chanmode is now enabled."
		}
	} elseif {$subcommand eq "off"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel vip-chanmode is already disabled."
		} else {
			channel set $channel -service_vip_chanmode
			putserv "NOTICE $nickname :$channel vip-chanmode is now disabled."
		}
	} elseif {$subcommand eq "status"} {
		putserv "NOTICE $nickname :$channel vip-chanmode is [expr {$status ? "enabled" : "disabled"}]."
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|status."
	}
}