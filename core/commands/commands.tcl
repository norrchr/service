service::commands::register commands -1 commands_cmd

proc commands_cmd {nickname hostname handle channel text} {
	global lastbind; variable trigger
	if {![validuser $handle]} { return }
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set trig [getuser $handle XTRA mytrigger]
	if {$trig == ""} {
		setuser $handle XTRA $trigger
		set trig "$trigger"
	}
	set chancmds [helper_list_channelcmds_byhandle $channel $handle]
	if {[llength $chancmds] <= 0} {
		putserv "NOTICE $nickname :You have no $channel commands available to you."
	} else {
		putserv "Notice $nickname :The following $channel commands are available to you: (trigger: $trig)"
		putserv "NOTICE $nickname :[join [split $chancmds " "] ", "]"
	}
	set globcmds [helper_list_globalcmds_byhandle $handle]
	if {[llength $globcmds] > 0} {
		putserv "NOTICE $nickname :The following global commands are available to you: (trigger: $trig)"
		putserv "NOTICE $nickname :[join [split $globcmds " "] ", "]"
	}
	putserv "NOTICE $nickname :End of commands list."
}