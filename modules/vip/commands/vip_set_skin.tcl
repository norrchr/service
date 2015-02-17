proc vip_set_skin {channel nickname handle lastbind text} {
	set subcommand [string tolower [lindex [split $text] 0]]
	set status [channel get $channel service_vips]
	if {$subcommand eq "on"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel vip-skin is already enabled."
		} else {
			channel set $channel +service_vips
			putserv "NOTICE $nickname :$channel vip-skin is now enabled."
		}
	} elseif {$subcommand eq "off"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel vip-skin is already disabled."
		} else {
			channel set $channel -service_vips
			putserv "NOTICE $nickname :$channel vip-skin is now disabled."
		}
	} elseif {$subcommand eq "status"} {
		putserv "NOTICE $nickname :$channel vip-skin is [expr {$status ? "enabled" : "disabled"}]."
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|status."
	}
}