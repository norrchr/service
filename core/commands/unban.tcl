service::commands::register unban 400 [namespace current]::unban_cmd

proc unban_cmd {nickname hostname handle channel text} {
	global lastbind lasttrigger
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set mask [lindex [split $text] 0]
	if {$mask == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind #id|hostname."
	} elseif {$mask == "\*" || [string equal -nocase all $mask]} {
		putserv "NOTICE $nickname :To unbanall, please use the '${lasttrigger}banclear' command (To unban all permbans too, please use '${lasttrigger}banclear all')." 
	} elseif {[regexp {^#[0-9]{1,}$} $mask]} {
		set mask [string trimleft $mask #]
		if {[llength [banlist $channel]] == "0"} {
			putserv "NOTICE $nickname :No registered bans for $channel."
		} elseif {$mask == "0" || $mask > [llength [banlist $channel]]} {
			putserv "NOTICE $nickname :Invalid ban id #$mask."
		} else {
			set id "0"
			set ban "0"
			foreach bann [banlist $channel] {
				if {$bann == ""} { return }
				incr id
				if {$id == $mask} {
					set ban [lindex $bann 0]
				}
			}
			if {$ban == "0"} {
				putserv "NOTICE $nickname :Ban ID #$mask does not exist."
			} elseif {[killchanban $channel $ban]} {
				putserv "NOTICE $nickname :Ban ID #$mask ($ban) successfully removed from $channel banlist."
				if {[ischanban $channel $ban] && [botisop $channel]} {
					pushmode $channel -b $ban
					flushmode $channel
				}
			} else {
				putserv "NOTICE $nickname :Error removing ban id #$mask ($ban) from $channel banlist."
			}
		}
	} elseif {[regexp {(.+)!(.+)@(.+)} $mask]} {
		set found "0"
		foreach ban [banlist $channel] {
			if {[string match -nocase $mask [lindex $ban 0]]} {
				set found 1
				break
			}
		}
		if {$found} {
			if {[killchanban $channel $mask]} {
				putserv "NOTICE $nickname :Banmask $mask successfully removed from $channel banlist."
				if {[ischanban $channel $mask] && [botisop $channel]} {
					pushmode $channel -b $mask
					flushmode $channel
				}
			}
		} else {
			set found "0"
			foreach chanban [chanbans $channel] {
				if {[string match -nocase $mask [lindex $chanban 0]]} {
					set found 1
					break
				}
			}
			if {$found} {
				if {![botisop $channel]} {
					putserv "NOTICE $nickname :I need op to unban $mask."
				} else {
					pushmode $channel -b $mask
					flushmode $channel
					putserv "NOTICE $nickname :Channel ban $mask removed."
				}
			} else {
				putserv "NOTICE $nickname :Banmask $mask does not exist."
			}
		}
	}
}