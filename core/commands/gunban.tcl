service::commands::register gunban 850 [namespace current]::gunban_cmd

proc gunban_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set mask [lindex [split $text] 0]
	if {$mask == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind #id|hostname."
	} elseif {[string index $mask 0] == "#" && [string is integer [set mask [string trimleft $mask #]]]} {
		if {[llength [banlist]] == "0"} {
			putserv "NOTICE $nickname :No registered global bans."
		} elseif {$mask == "0" || $mask > [llength [banlist]]} {
			putserv "NOTICE $nickname :Invalid ban id #$mask."
		} else {
			set id "0"
			set ban "0"
			foreach bann [banlist] {
				if {$bann == ""} { return }
				incr id
				if {$id == $mask} {
					set ban [lindex $bann 0]
				}
			}
			if {$ban == "0"} {
				putserv "NOTICE $nickname :Ban ID #$mask does not exist."
			} elseif {[killban $ban]} {
				putserv "NOTICE $nickname :Ban ID #$mask ($ban) successfully removed from global banlist."
				if {[ischanban $channel $ban] && [botisop $channel]} {
					pushmode $channel -b $ban
				}
			} else {
				putserv "NOTICE $nickname :Error removing ban id #$mask ($ban) from global banlist."
			}
		}
	} elseif {[regexp {(.+)!(.+)@(.+)} $mask]} {
		set found "0"
		foreach ban [banlist] {
			if {[string match -nocase $mask [lindex $ban 0]]} {
				set found 1
				break
			}
		}
		if {$found} {
			if {[killban $mask]} {
				putserv "NOTICE $nickname :Banmask $mask successfully removed from global banlist."
				if {[ischanban $channel $mask] && [botisop $channel]} {
					pushmode $channel -b $mask
				}
			}
		} else {
			putserv "NOTICE $nickname :Banmask '$mask' does not exist."
		}
	}
}