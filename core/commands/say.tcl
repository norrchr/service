service::commands::register say 450 say_cmd

proc say_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {$text == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind <messaege>."
	} else {
		putserv "PRIVMSG $channel :$text"
	}
}