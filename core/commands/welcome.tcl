service::commands::register welcome 450 welcome_cmd

proc welcome_cmd {nickname hostname handle channel text} {
	global lastbind; variable welcomeskin
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_welcome]
	set notice [channel get $channel service_welcome_notice]
	if {[set skin [channel get $channel service_welcome_skin]] == ""} {
		channel set $channel service_welcome_skin "[set skin $welcomeskin]"
	}
	set cmd [string tolower [lindex [split $text] 0]]
	if {$cmd eq "on" || $cmd eq "enable"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel welcome is already enabled."
		} else {
			channel set $channel +service_welcome
			putserv "NOTICE $nickname :$channel welcome is now enabled."
		}
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel welcome is already disabled."
		} else {
			channel set $channel -service_welcome
			putserv "NOTICE $nickname :$channel welcome is now disabled."
		}
	} else {$cmd eq "notice"} {
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "on" || $cmd_ eq "enable"} {
			if {$notice} {
				putserv "NOTICE $nickname :$channel welcome notice is already enabled."
			} else {
				channel set $channel +service_welcome_notice
				putserv "NOTICE $nickname :$channel welcome notice is now enabled."
			}
		} elseif {$cmd_ eq "off" || $cmd_ eq "disable"} {
			if {!$notice} {
				putserv "NOTICE $nickname :$channel welcome notice is already disabled."
			} else {
				channel set $channel -service_welcome_notice
				putserv "NOTICE $nickname :$channel welcome notice is now disabled."
			}
		} elseif {$cmd_ eq "status" || $cmd_ eq "st"} {
			putserv "NOTICE $nickname :$channel welcome notice is: \002[expr {$notice ? "enabled" : "disabled"}]\002."
		} else {
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd on|off|status."
		}
	} elseif {$cmd eq "set"} {
		set newskin [join [lrange $text 1 end]]
		if {$skin == ""} {
			putserv "NOTICE $nickname :Current: $skin."
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd ?skin?."
		} elseif {[string length $newskin] < 10} {
			putserv "NOTICE $nickname :Welcome skin must be more than 10 letters."
		} elseif {[string length $newskin] > 250} {
			putserv "NOTICE $nickname :Welcome skin must be less than 250 letters."
		} elseif {[string equal -nocase $skin $newskin]} {
			putserv "NOTICE $nickname :The new welcome skin is the same as the current one."
		} else {
			channel set $channel service_welcome_skin "$newskin"
			putserv "NOTICE $nickname :Done. Welcome Skin set to: $newskin."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		putserv "NOTICE $nickname :$channel welcome is: \002[expr {$status ? "enabled" : "disabled"}]. $channel welcome notice is: \002[expr {$notice ? "enabled" : "disabled"}]."
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|notice|set|status ?on/off/skin?."
	}
}