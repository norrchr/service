service::commands::register chanlev 450 [namespace current]::chanlev_cmd

proc chanlev_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set who [lindex [split $text] 0]
	set flags [lindex [split $text] 1]
	if {$who == "" || $flags == ""} {
		putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command <nickname|#authname> <+-flags>."
	} elseif {[string equal -nocase $botnick $who]} {
		putserv "NOTICE $nickname :ERROR: You can't modify my own chanlev!"
	} elseif {![regexp -nocase -- {\+|\-} $flags]} {
		putserv "NOTICE $nickname :Invalid flags format. You need to indicate a + and/or - sign."
	} elseif {![onchan Q $channel]} {
		putserv "NOTICE $nickname :ERROR: Q is not present on $channel."
	} else {
		putserv "PRIVMSG Q :CHANLEV $channel $who $flags"
		putserv "NOTICE $nickname :Done."
	}
}