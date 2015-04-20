service::commands::register hop 850 [namespace current]::hop_cmd

proc hop_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set chan [lindex [split $text] 0]
	if {$chan == "" || [string index $chan 0] != "#"} {
		putserv "NOTICE $nickname :Usage: $lastbind ?#channel?."
	} elseif {![validchan $chan]} {
		putserv "NOTICE $nickname :Channel '$chan' is not a valid channel."
	} else {
		if {[botonchan $chan]} {
			putserv "PART $chan"
		}
		putserv "JOIN $chan"
		putserv "NOTICE $nickname :Successfully hop'd on $chan."
	}
}