service::commands::register broadcast,spam 850 broadcast_cmd

proc broadcast_cmd {nickname hostname handle channel text} {
	global lastbind; variable homechan; variable adminchan; variable helpchan
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {$text == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind <message>."
	} else {
		set list ""
		set id "0"
		foreach chan [channels] {
			if {$chan == ""} { return }
			if {![string equal -nocase $homechan $chan] && ![string equal -nocase $adminchan $chan] && ![string equal -nocase $helpchan $chan]} {
				puthelp "PRIVMSG $chan :\(broadcast\) $text"
				incr id 1
			}
		}
		putserv "NOTICE $nickname :Done. Broadcasted to ($id/[llength [channels]]) Successfully."
	}
}