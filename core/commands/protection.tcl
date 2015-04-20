service::commands::register protection,protect 400 [namespace current]::protection_cmd

proc protection_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_prot]
	set hard [channel get $channel service_prot_hard]
	set cmd [string tolower [lindex [split $text] 0]]
	if {$cmd eq "on" || $cmd eq "enable"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel protection is already enabled."
		} elseif {[set sb [getnetworkservice $channel "chanserv"]] == ""} {
			putserv "NOTICE $nickname :No network channel service bot present at $channel."
		} else {
			channel set $channel service_servicebot $sb
			channel set $channel +service_prot
			if {[string match *l* [getchanmode $channel]]} {
				if {[string match *k* [getchanmode $channel]]} {
					channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 2]
				} else {
					channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 1]
				}
			}
			putserv "NOTICE $nickname :Done (Network Service: $sb)."
		}
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel protection is already disabled."
		} else {
			channel set $channel -service_prot
			putserv "NOTICE $nickname :Done."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		putserv "NOTICE $nickname :$channel protection is \002[expr {$status ? "enabled" : "disabled"}]\002 - hard protection is \002[expr {$hard ? "enabled" : "disable"}]\002."
	} elseif {$cmd eq "hard"} {
		set sub [string tolower [lindex [split $text] 1]]
		if {$sub eq "on" || $sub eq "enable"} {
			if {$hard} {
				putserv "NOTICE $nickname :Hard protection is already enabled."
			} else {
				channel set $channel +service_prot_hard
				putserv "NOTICE $nickname :Hard protection is now enabled."
			}
		} elseif {$sub eq "off" || $sub eq "disable"} {
			if {!$hard} {
				putserv "NOTICE $nickname :Hard protection is already disabled."
			} else {
				channel set $channel -service_prot_hard
				putserv "NOTICE $nickname :Hard protection is now disabled."
			}
		} elseif {$sub eq "status" || $sub eq "st"} {
			if {$hard} {
				putserv "NOTICE $nickname :Hard protection is: \002enabled\002."
			} else {
				putserv "NOTICE $nickname :Hard protection is :\002disabled\002."
			}
		} else {
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd on|off|status."
		}
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|status."
	}
}