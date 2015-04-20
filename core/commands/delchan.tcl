service::commands::register delchan,remchan,part,-chan 950 delchan_cmd

proc delchan_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {[set chan [lindex [split $text] 0]] == "" || [string index $chan 0] != "#"} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind #channel."
	} elseif {![validchan $chan]} {
		putserv "NOTICE $nickname :$chan is not added to my channel list."
	} else {
		channel remove $chan
		putserv "NOTICE $nickname :Channel ($chan) successfully removed from my channel list."
	}
}