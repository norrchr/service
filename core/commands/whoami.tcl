service::commands::register whoami -1 [namespace current]::whoami_cmd

proc whoami_cmd {nickname hostname handle channel text} {
	if {[matchattr $handle S|S $channel]} { return }
	if {![validuser $handle]} { putserv "NOTICE $nickname :You are not known to me."; return }
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set nicks [expr {[set x [lsort -unique [hand2nicks $handle]]] == "" ? "N/A" : $x}] 
	putserv "NOTICE $nickname :Account information for $nickname (using nickname(s): [join $nicks ", "] (under handle: $handle)):"
	set global [matchattr $handle ADnmovf]
	putserv "NOTICE $nickname :Userid: [getuser $handle XTRA userid][expr {$global ? " - Global userflags: +[chattr $handle]" : "."}]"
	set lvl [list]
	if {[matchattr $handle A]} { lappend lvl "Administrator" }
	if {[matchattr $handle D]} { lappend lvl "Developer" }
	if {[matchattr $handle n]} { lappend lvl "Owner" }
	if {[matchattr $handle m]} { lappend lvl "Master" }
	if {[matchattr $handle o]} { lappend lvl "Operator" }
	if {[matchattr $handle vf]} { lappend lvl "Friend" }
	if {[llength $lvl] >= 1} {
		putserv "NOTICE $nickname :You're a Bot [join $lvl ", "]."
	}
	putserv "NOTICE $nickname :Last Login: [expr {[getuser $handle XTRA lastlogin] == "" ? "N/A" : "[clock format [getuser $handle XTRA lastlogin] -format "%D %T"]"}] - Last Hostname: [getuser $handle XTRA lasthost]"
	putserv "NOTICE $nickname :Email: [getuser $handle XTRA email] - Last set: [expr {[getuser $handle XTRA emailset] == "" ? "N/A" : "[clock format [getuser $handle XTRA emailset] -format "%D %T"]"}]"
	putserv "NOTICE $nickname :Trigger: [getuser $handle XTRA mytrigger] - Last set: [expr {[getuser $handle XTRA mytriggerset] == "" ? "N/A" : "[clock format [getuser $handle XTRA mytriggerset] -format "%D %T"]"}]"
	putserv "NOTICE $nickname :Commands Executed: [expr {[set x [getuser $handle XTRA cmdcount]] == "" ? "0" : $x}] command[expr {$x == "1" ? "" : "s"}] - Last command: [expr {[getuser $handle XTRA lastcmd] == "" ? "N/A" : [getuser $handle XTRA lastcmd]}] - When: [expr {[getuser $handle XTRA lastcmdset] == "" ? "N/A" : "[clock format [getuser $handle XTRA lastcmdset] -format "%D %T"]"}]"
	putserv "NOTICE $nickname :You have '[llength [getuser $handle HOSTS]]' hostmask(s) assigned to your account."
	putserv "NOTICE $nickname :[join [getuser $handle HOSTS] ", "]."

	set list [list]
	foreach channel [channels] {
		if {[matchattr $handle |nmovf $channel]} {
			lappend list "$channel [lindex [split [chattr $handle $channel] |] 1]"
		}
	}
	if {[llength $list] < 1} {
		putserv "NOTICE $nickname :You are not known on any of my channels."
	} else {
		putserv "NOTICE $nickname :You are known in the following [llength $list] channel(s): (#channel +-flags)"
		putserv "NOTICE $nickname :[join $list ", "]."
	}
	putserv "NOTICE $nickname :End of WHOAMI."
}