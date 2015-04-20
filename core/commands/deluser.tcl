service::commands::register deluser 450 [namespace current]::deluser_cmd

proc deluser_cmd {nickname hostname handle channel text} {
	global lastbind lasttrigger
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	putserv "NOTICE $nickname :ERROR: please use '${lasttrigger}access <nickname|#handle> ?-global|#channel? clear' instead."
}