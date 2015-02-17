proc vip_set_notice {channel nickname handle lastbind text} {
	set subcommand [string tolower [lindex [split $text] 0]]
	set status [channel get $channel service_vipn]
	if {$subcommand eq "on"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel vip-notice is already enabled."
		} else {
			channel set $channel +service_vipn
			putserv "NOTICE $nickname :$channel vip-notice is now enabled."
		}
	} elseif {$subcommand eq "off"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel vip-notice is already disabled."
		} else {
			channel set $channel -service_vipn
			putserv "NOTICE $nickname :$channel vip-notice is now disabled."
		}
	} elseif {$subcommand eq "status"} {
		putserv "NOTICE $nickname :$channel vip-notice is [expr {$status ? "enabled" : "disabled"}]."
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|status."
	}
}