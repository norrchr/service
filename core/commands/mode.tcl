service::commands::register mode 400 [namespace current]::mode_cmd

proc mode_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	#modes = bCcdDiklmnNoprstuv
	if {$text == ""} {
		putserv "NOTICE $nickname :${lastbind}$command +-modes."
	} elseif {![regexp {\+|\-} [string index $text 0]]} {
		putserv "NOTICE $nickname :Mode(s) must start with a '+' or '-'."
	} else {
		putserv "MODE $channel $text"
	}
}