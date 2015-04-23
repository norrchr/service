service::commands::register update 950 [namespace current]::update_cmd

proc update_cmd {nickname hostname handle channel text} {
	global lastbind lasttrigger
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set d [pwd]
	cd [pwd]/scripts/service
	if {[catch {set r [exec bash update.sh]} err]} {
		cd $d
		putserv "NOTICE $nickname :(1) Error updating service from git. (Reported to bot admins)"
		set rc [service getconf core adminchan]
		putserv "PRIVMSG $rc :(1) Error updating service from git for $nickname ($handle):"
		foreach li [split $err \n] {
			if {$li eq ""} { continue }
			putserv "PRIVMSG $rc :$li"
		}
		putserv "PRIVMSG $rc :end of error."
	} else {
		cd $d
		set result [lindex [split $r] 0]
		if {[lindex [split $r] 0] eq -1} {
			set err [jpin [lrange $r 1 end]]
			putserv "NOTICE $nickname :(2) Error updating service from git. (Reported to bot admins)"
			set rc [service getconf core adminchan]
			putserv "PRIVMSG $rc :(2) Error updating service from git for $nickname ($handle):"
			foreach li [split $err \n] {
				if {$li eq ""} { continue }
				putserv "PRIVMSG $rc :$li"
			}
			putserv "PRIVMSG $rc :end of error."
		} else {
			set vers [lindex [split $r] 1]
			set commit [lindex [split $r] 2]
			if {$result eq 0} {
				putserv "NOTICE $nickname :No update(s) available for service. \($vers \{$commit\}\)"
			} elseif {$result eq 1} {
				putserv "NOTICE $nickname :Pulled $vers \{$commit\} from git, please type ${lasttrigger}tcl save;rehash to load it."
			} else {
				putserv "NOTICE $nickname :Unexpected return code \"$result\" from git pull."
			}
		}
	}
}