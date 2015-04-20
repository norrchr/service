service::commands::register commands 600 [namespace current]::commands_cmd

proc commands_cmd {nickname hostname handle channel text} {
	global lastbind; variable trigger
	if {![validuser $handle]} { return }
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set trig [getuser $handle XTRA mytrigger]
	if {$trig == ""} {
		setuser $handle XTRA $trigger
		set trig "$trigger"
	}
	if {[set chanlevel [service commands handle2level $handle $channel]] <= 0} {
		putserv "NOTICE $nickname :You are not known on $channel and have no access to channel commands."
	} elseif {[llength [set chancmds [service commands level2cmds $chanlevel 0]]] <= 0} {
		putserv "NOTICE $nickname :You have no $channel commands available to you."
	} else {
		putserv "NOTICE $nickname :You have [llength $chancmds] $channel command(s) available to you: (trigger: $trig)"
		putserv "NOTICE $nickname :[join $chancmds ", "]"
	}
	if {[set globallevel [service commands handle2level $handle]] <= 600} {
		putserv "NOTICE $nickname :You are not known on $channel and have no access to channel commands."
	} elseif {[llength [set globalcmds [service commands level2cmds $globallevel 600]]] <= 0} {
		putserv "NOTICE $nickname :You have no global commands available to you."
	} else {
		putserv "NOTICE $nickname :You have [llength $globalcmds] global command(s) available to you: (trigger: $trig)"
		putserv "NOTICE $nickname :[join $globalcmds ", "]"
	}	
	putserv "NOTICE $nickname :End of commands list."
}