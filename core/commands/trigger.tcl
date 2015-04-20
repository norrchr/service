service::commands::register trigger,mytrigger,trig,trigger 0 [namespace current]::trigger_cmd

proc trigger_cmd {nickname hostname handle channel text} {
	global lastbind
	set triggers [service getconf core triggers]
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set trigger [join [lindex [split $text] 0]]
	if {$trigger == ""} {
		putserv "NOTICE $nickname :Current mytrigger: [expr {[getuser $handle XTRA mytrigger] == "" ? "not set" : "[getuser $handle XTRA mytrigger]"}] (Triggers: [join "$triggers" ", "])."
	} elseif {[lsearch -exact "$triggers" $trigger] == "-1"} {
		putserv "NOTICE $nickname :Invalid trigger '$trigger'. Valid triggers are: [join "$triggers" ", "]."
	} else {
		setuser $handle XTRA mytrigger "$trigger"
		putserv "NOTICE $nickname :Trigger changed to '$trigger'."
	}
}