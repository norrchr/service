service::commands::register help -1 help_cmd

proc help_cmd {nickname hostname handle channel text} {
	global lastbind lasttrigger; variable trigger; variable cmdhelp
	if {![validuser $handle]} { return }
	set trig [getuser $handle XTRA mytrigger]
	if {$trig == ""} {
		setuser $handle XTRA $trigger
		set trig "$trigger"
	}
	set command [string tolower [lindex [split $text] 0]]
	set tonick [string tolower [lindex [split $text] 1]]
	if {$tonick == ""} {
		if {[llength [array names cmdhelp]] <= 0} {
			putserv "NOTICE $nickname :ERROR: No help information available."; return
		}
		if {![helper_help_cmd_tonick $command $nickname]} {
			putserv "NOTICE $nickname :ERROR: Invalid command '$command'. Please use ${lasttrigger}commands to get a list of available commands to you."
		}
	} elseif {![onchan $tonick]} {
		putserv "NOTICE $nickname :ERROR: '$tonick' is not on any of my channels."
	} else {
		if {[llength [array names cmdhelp]] <= 0} {
			putserv "NOTICE $nickname :ERROR: No help information available."
			putserv "NOTICE $tonick :ERROR: No help information available."; return
		}
		if {![helper_help_cmd_tonick $command $tonick]} {
			putserv "NOTICE $nickname :ERROR: Invalid command '$command'. Please use ${lasttrigger}commands to get a list of available commands to you."
		} else {
			putserv "NOTICE $nickname :Done. Sent help information for '$command' to '$tonick'."
		}
	}
}