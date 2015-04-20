service::commands::register autolimit 450 [namespace current]::autolimit_cmd

proc autolimit_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set cmd [string tolower [lindex [split $text] 0]]
	set status [channel get $channel service_autolimit]
	if {$cmd eq "on" || $cmd eq "enable"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel autolimit is already enabled."
		} else {
			channel set $channel +service_autolimit
			channel set $channel service_limit "10"
			set curr [llength [chanlist $channel]]
			set newlimit [expr {$curr + 10}]
			pushmode $channel +l $newlimit
			putserv "NOTICE $nickname :Done."
		}
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel autolimit is already disabled."
		} else {
			channel set $channel -service_autolimit
			channel set $channel service_limit ""
			putserv "NOTICE $nickname :Done."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel autolimit is enabled."
			putserv "NOTICE $nickname :Current setting: #[channel get $channel service_limit]."
		} else {
			putserv "NOTICE $nickname :$channel autolimit is disabled."
		}
	} else {
		if {[string index $cmd 0] == "#"} {
			set limit [string trimleft $cmd #]
			if {$limit < 3} {
				putserv "NOTICE $nickname :The limit must be 3 or higher."
			} elseif {[channel get $channel service_limit] == $limit} {
				putserv "NOTICE $nickname :The new limit must be different from the current limit."
			} else {
				channel set $channel service_limit "$limit"
				if {[string match *l* [getchanmode $channel]]} {
					if {[string match *k* [getchanmode $channel]]} {
						set curr [lindex [split [getchanmode $channel]] 2]
					} else {
						set curr [lindex [split [getchanmode $channel]] 1]
					}
					set newlimit [expr {[llength [chanlist $channel]] + $limit}]
					if {$newlimit != "$curr"} {
						pushmode $channel +l $newlimit
					}
				} else {
					pushmode $channel +l [expr {[llength [chanlist $channel]] + $limit}]
				}
				putserv "NOTICE $nickname :New limit successfully set to: #$limit."
			}
		} else {
			putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|status|#limit."
		}
	}
}