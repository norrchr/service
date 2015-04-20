service::commands::register access 0 access_cmd

proc access_cmd {nickname hostname handle channel text} {
	global lastbind; variable global_user_levels; variable channel_user_levels
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {[llength $text] < 1} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind <nickname|#handle> ?-global|#channel? ?level?"
		return
	}
	set who [lindex [split $text] 0]
	set where [lindex [split $text] 1]
	set global 0
	if {[string index $who 0] == "#"} {
		if {![validuser [set hand [string trimleft $who #]]]} {
			putserv "NOTICE $nickname :ERROR: Handle '$hand' does not exist in my database."; return
		}
	} elseif {[set hand [nick2hand $who]] == "*"} {
		putserv "NOTICE $nickname :ERROR: Nickname '$who' does not match any of my users."; return
	}
	if {[string index $where 0] == "#"} {
		if {![validchan $where]} {
			putserv "NOTICE $nickname :ERROR: Invalid channel '$channel' specified."; return
		} else {
			set level [string tolower [lindex [split $text] 1]]
		}
	} elseif {[string equal -nocase "-global" $where]} {
		set level [string tolower [lindex [split $text] 2]]
		if {$level != "" && ![info exists global_user_levels($level)]} {
			putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names global_user_levels] ", "])"; return
		}
		set cl [accesslevel $hand]; # current level
		switch -exact -- $cl {
			0 {set before "Global Nothing"}
			1 {set before "Global Ban"}
			2 {set before "Global Voice"}
			3 {set before "Global Operator"}
			4 {set before "Global Master"}
			5 {set before "Global Owner"}
			6 {set before "Network Service"}
			7 {set before "Bot Developer"}
			8 {set before "Bot Administrator"}
		}
		#set levels $global_user_levels($level)
		set global 1
	} else {
		set where $channel
		set level [string tolower [lindex [split $text] 1]]
	}
	if {!$global} {
		if {$level != "" && ![info exists channel_user_levels($level)]} {
			putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names channel_user_levels] ", "])"; return
		} else {
			#set levels $channel_user_levels($level)
			set cl [accesslevel $hand $where]; # current level
			switch -exact -- $cl {
				0 {set before "unknown"}
				1 {set before "banned"}
				2 {set before "voice"}
				3 {set before "operator"}
				4 {set before "master"}
				5 {set before "owner"}
				6 {set before "unknown"}
			}
			# 6 == bot staff hack
		}
	}
	if {$level == ""} {
		if {$global} {
			if {[accesslevel $handle] == 0} {
				putserv "NOTICE $nickname: ERROR: You do not have the required privileges to view global access levels."; return
			}
			putserv "NOTICE $nickname :Global userlevel for '$who' is currently '$before'."; return
		} else {
			if {[accesslevel $handle $where] == 0} {
				putserv "NOTICE $nickname :ERROR: You do not have the required privileges to view $where access levels."; return
			}
			putserv "NOTICE $nickname :Channel userlevel for '$who' is currently '$where $before'."; return
		}
	} else {
		if {$global} {
			set levels $global_user_levels($level)
		} else {
			set levels $channel_user_levels($level)
		}
		set mf [lindex [split $levels] 0]; # flags required
		set af [lindex [split $levels] 1]; # flags provided
		set clear [expr {$level == "clear" || $level == "none" ? 1:0}]
		if {$global} {
			if {!$clear && [matchattr $hand $af]} {
				putserv "NOTICE $nickname :ERROR: User '$who' is already 'global $level'."; return
			} elseif {![matchattr $handle $mf]} {
				putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to modify '$who' to 'global $level'."; return
			}
		} else {			
			if {!$clear && [matchattr $hand $af $where]} {
				putserv "NOTICE $nickname :ERROR: User '$who' is already '$where $level'."; return
			} elseif {![matchattr $handle $mf $where]} {
				putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to modify '$who' to '$where $level'."; return
			}
		}
		if {[string equal -nocase "clear" $level] || [string equal -nocase "none" $level]} { set level "nothing" }
		if {$global} {
			chattr $hand $af
			#set type [expr {[accesslevel $hand] > $cl ? "Upgraded" : "Downgraded"}]
			set type [expr {[accesslevel $hand] == $cl ? "Reset" : [expr {[accesslevel $hand] > $cl ? "Upgraded" : "Downgraded"}] }]
			if {[string equal -nocase "ban" $level]} {
				set kmsg $kickmsg(gban)
				channel set $adminchan [set id [expr {[channel get $adminchan gkid] + 1}]]
				regsub -all :adminchan: $kmsg "$adminchan" kmsg
				regsub -all :id: $kmsg "$id" kmsg
				regsub -all :reason: $kmsg "Global Banned" kmsg
				foreach host [getuser $hand HOSTS] {
					if {$host == "" || $host == "*!*@*" || $host == "*!*@" || [string match -nocase "-telnet!*@*" $host]} { continue }
					newban $host $handle "$kickmsg" 0
				}
			}
			#putserv "NOTICE $nickname :Global Access level for '#$hand' has been \002$type\002 from \002$before\002 to \002Global Ban\002."
			putserv "NOTICE $nickname :$type user access for '$who' from '$before' to 'global $level'."
		} else {
			chattr $hand |$af $where
			set type [expr {[accesslevel $hand $where] == $cl ? "Reset" : [expr {[accesslevel $hand $where] > $cl ? "Upgraded" : "Downgraded"}] }]
			if {[string equal -nocase "ban" $level]} {
				foreach host [getuser $hand HOSTS] {
					if {$host == "" || $host == "*!*@*" || $host == "*!*@" || [string match -nocase "-telnet!*@*" $host]} { continue }
					newchanban $where $host $handle "$kickmsg(defaultban)" 0
				}
			}
			#putserv "NOTICE $nickname :Access level for '#$hand' has been \002$type\002 from \002$before\002 to \002Channel Ban\002."
			putserv "NOTICE $nickname :$type user access for '$who' from '$where $before' to '$where $level'."
		}
	}
}