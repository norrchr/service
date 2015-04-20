service::commands::register whois -1 [namespace current]::whois_cmd

proc whois_cmd {nickname hostname handle channel text} {
	global lastbind
	if {![validuser $handle]} { puthelp "NOTICE $nickname :You are not known to me and so you can't whois my users."; return }
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set who [lindex [split $text] 0]
	set whoo [lindex [split $text] 1]
	if {$who == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind nickname|#handle ?nickname|#handle?."
		return
	}
	if {[string index $who 0] == "#"} {
		if {![validuser [set hand [string range $who 1 end]]]} {
			putserv "NOTICE $nickname :Handle '#$hand' does not exist in my database."
		} else {
			set nicks [expr {[set x [lsort -unique [hand2nicks $hand]]] == "" ? "N/A" : $x}]
		}
	} else {
		set hand [nick2hand $who]
		if {$hand == ""} {
			putserv "NOTICE $nickname :ERROR: '$who' is not on any of my channels."
		} elseif {$hand == "*"} {
			putserv "NOTICE $nickname :ERROR: '$who' is not known to my database."
		} else {
			set nicks [expr {[set x [lsort -unique [hand2nicks $hand]]] == "" ? "N/A" : $x}]
		}
	}
	if {$whoo != "" && ![string equal -nocase $who $whoo]} {
		putserv "ERROR: '$who' does not equal '$whoo' - Extended WHOIS fail."; set extended 0; return
	} else {
		set extended 1
	}
	putserv "NOTICE $nickname :Account information for $who (using [expr {[string index $who 0] == "#" ? "nickname(s): [join $nicks ", "]" : "nickname(s): [join $nicks ", "] (under handle: $hand)"}]):"
	set global [matchattr $handle ADnm]
	putserv "NOTICE $nickname :Userid: [getuser $hand XTRA userid][expr {$global ? " - Global userflags: +[chattr $hand]." : "."}]"
	set lvl [list]; set protected 0
	if {[matchattr $hand A]} { lappend lvl "Administrator" }
	if {[matchattr $hand D]} { lappend lvl "Developer" }
	if {[matchattr $hand n]} { lappend lvl "Owner" }
	if {[matchattr $hand m]} { lappend lvl "Master" }
	if {[llength $lvl] >= 1} {
		putserv "NOTICE $nickname :$who is a Bot [join $lvl ", "]."
		set protected 1
	}
	if {[matchattr $hand S]} { putserv "NOTICE $nickname :$who is a Network Service."; putserv "NOTICE $nickname :End of WHOIS."; return }
	if {!$global && $protected} { putserv "NOTICE $nickname :End of WHOIS."; return }
	if {$extended} {
		putserv "NOTICE $nickname :Last Login: [expr {[getuser $hand XTRA lastlogin] == "" ? "N/A" : "[clock format [getuser $hand XTRA lastlogin] -format "%D %T"]"}]"
	}
	if {$global && $extended} {
		#putserv "NOTICE $nickname :Further information for '$who':"
		putserv "NOTICE $nickname :Last hostname: [getuser $hand XTRA lasthost]"
		putserv "NOTICE $nickname :Email: [getuser $hand XTRA email] - Last set: [expr {[getuser $hand XTRA emailset] == "" ? "N/A" : "[clock format [getuser $hand XTRA emailset] -format "%D %T"]"}]"
		putserv "NOTICE $nickname :Trigger: [getuser $hand XTRA mytrigger] - Last set: [expr {[getuser $hand XTRA mytriggerset] == "" ? "N/A" : "[clock format [getuser $hand XTRA mytriggerset] -format "%D %T"]"}]"
		putserv "NOTICE $nickname :Commands Executed: [expr {[set x [getuser $hand XTRA cmdcount]] == "" ? "0" : $x}] command[expr {$x == "1" ? "" : "s"}] - Last command: [expr {[getuser $hand XTRA lastcmd] == "" ? "N/A" : [getuser $hand XTRA lastcmd]}] - When: [expr {[getuser $hand XTRA lastcmdset] == "" ? "N/A" : "[clock format [getuser $hand XTRA lastcmdset] -format "%D %T"]"}]"
		putserv "NOTICE $nickname :Has '[llength [getuser $hand HOSTS]]' hostmask(s) assigned."
		putserv "NOTICE $nickname :[join [getuser $hand HOSTS] ", "]."
	}
	set list [list]
	foreach channel [channels] {
		if {[matchattr $handle ADnm|mnovf $channel] && [matchattr $who |mnovf $channel]} {
			lappend list "$channel [lindex [split [chattr $who $channel] |] 1]"
		}
	}
	if {[llength $list] < 1} {
		putserv "NOTICE $nickname :'$who' is not known on any of my channels."
	} else {
		putserv "NOTICE $nickname :'$who' is known in '[llength $list]' of my channel(s): (#channel +-flags)"
		putserv "NOTICE $nickname :[join $list ", "]."
	}
	putserv "NOTICE $nickname :End of WHOIS."
}