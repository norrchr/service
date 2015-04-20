service::commands::register invite 300 [namespace current]::invite_cmd

proc invite_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set invite [lindex [split $text] 0]
	if {$invite == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind <nickname>."
	} elseif {[onchan $invite $channel]} {
		putserv "NOTICE $nickname :ERROR: $invite is already on $channel."
	} elseif {![botisop $channel]} {
		putserv "NOTICE $nickname :I need op to do that!"
	} else {
		puthelp "INVITE $invite $channel"
		putserv "NOTICE $nickname :Invited $invite to $channel."
	}
}