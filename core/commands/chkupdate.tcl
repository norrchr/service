service::commands::register chkupdate 950 [namespace current]::chkupdate_cmd

proc chkupdate_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set d [pwd]
	cd [pwd]/scripts/service
	if {[catch {set r [exec bash uptodate.sh]} err]} {
		cd $d
		putserv "NOTICE $nickname :Error checking if service is up-to-date. (Reported to bot admins)"
		set rc [service getconf core adminchan]
		putserv "PRIVMSG $rc :Error checking if service is up-to-date for $nickname ($handle):"
		foreach li [split $err \n] {
			if {$li eq ""} { continue }
			putserv "PRIVMSG $rc :$li"
		}
		putserv "PRIVMSG $rc :end of error."
	} else {
		cd $d
		if {[lindex [split $r] 0] eq 1} {
			putserv "NOTICE $nickname :Service up-to-date."
		} else {
			putserv "NOTICE $nickname :Service update available. ([lindex [split $r] 1])"
		}
	}
}