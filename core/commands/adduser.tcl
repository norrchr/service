service::commands::register adduser 400 [namespace current]::adduser_cmd

proc adduser_cmd {nickname hostname handle channel text} {
	global lastbind botnick; variable global_user_levels; variable channel_user_levels; variable trigger; variable adminchan; variable kickmsg
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {[llength $text] < 3} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind <nickname> <handle> ?-global|#channel? <level>."
		return
	}
	set who [lindex [split $text] 0]
	set hand [lindex [split $text] 1]
	set where [lindex [split $text] 2]
	set global 0
	if {[string index $where 0] == "#"} {
		if {![validchan $where]} {
			putserv "NOTICE $nickname :ERROR: Invalid channel '$channel' specified."; return
		} else {
			set level [string tolower [lindex [split $text] 3]]
		}
	} elseif {[string equal -nocase "-global" $where]} {
		set level [string tolower [lindex [split $text] 3]]
		if {![info exists global_user_levels($level)]} {
			putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names global_user_levels] ", "])"; return
		}
		set levels $global_user_levels($level)
		set global 1
	} else {
		set where $channel
		set level [string tolower [lindex [split $text] 2]]
	}
	if {!$global} {
		if {![info exists channel_user_levels($level)]} {
			putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names channel_user_levels] ", "])"; return
		} else {
			set levels $channel_user_levels($level)
		}
	}
	set mf [lindex [split $levels] 0]; # flags required
	set af [lindex [split $levels] 1]; # flags provided
	if {$global && ![matchattr $handle $mf]} {
		putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to add '$who' (#$hand) as 'global $level'."; return
	} elseif {![matchattr $handle $mf $where]} {
		putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to add '$who' (#$hand) as '$where $level'."; return
	}
	if {![onchan $who]} {
		putserv "NOTICE $nickname :ERROR: User '$who' is not on any of my channels."; return
	} elseif {[validuser [nick2hand $who]]} {
		putserv "NOTICE $nickname :ERROR: User '$who' is already added as '[nick2hand $who]' - please use the ACCESS command to further modify access."; return
	} elseif {[string length $hand] <= 2 && [string length $hand] > 9} {
		putserv "NOTICE $nickname :ERROR: Handle length must be between 2 to 9 characters long."; return
	} elseif {[getchanhost $who] == ""} {
		putserv "NOTICE $nickname :ERROR: Could not grab hostname for $who - carn't proceed."; return
	} else {
		if {[string match -nocase *users.quakenet.org [set host *!*[string trimleft [getchanhost $who] ~]]]} {
			set host *!*@[lindex [split $host @] 1]
		}
		adduser $hand $host
		if {$global} {
			chattr $hand $af
		} else {
			chattr $hand $af $where
		}
		setuser $hand XTRA mytrigger "$trigger"
		setuser $hand XTRA mytriggerset "[clock seconds]"
		channel set $adminchan service_userid "[set userid [expr {[channel get $adminchan service_userid]+1}]]"
		setuser $hand XTRA userid $userid
		setuser $hand XTRA email "N/A"
		setuser $hand XTRA loggedin 1
		setuser $hand XTRA lastlogin [clock seconds]
		setuser $hand XTRA lasthost "[string trimleft [getchanhost $who] ~]"
		setuser $hand XTRA cmdcount 0
		setuser $hand XTRA lastcmd "N/A"
		if {$global} {
			putserv "NOTICE $nickname :\002$who\002 ($hand) added as \002global $level\002."
			if {$level == "ban"} {
				set kmsg $kickmsg(gban)
				channel set $adminchan [set id [expr {[channel get $adminchan gkid] + 1}]]
				regsub -all :adminchan: $kmsg "$adminchan" kmsg
				regsub -all :id: $kmsg "$id" kmsg
				regsub -all :reason: $kmsg "Global Banned" kmsg
				newban $host $handle "$kmsg" 0
			} else {
				putserv "NOTICE $who :\002$nickname ($handle)\002 added you as \002global $level\002."
			}
		} else {
			putserv "NOTICE $nickname :\002$who\002 ($hand) added as \002$where $level\002."
			if {$level == "ban"} {
				newchanban $where $host $handle "$kickmsg(defaultban)" 0
			} else {
				putserv "NOTICE $who :\002$nickname ($handle)\002 added you as \002$where $level\002."
				if {![isop $who $where] && [botisop $where] && [matchattr $hand |nmo $where]} {
					pushmode $where +o $who
				} elseif {![isvoice $who $where] && [botisop $where] && [matchattr $hand |vf $where]} {
					pushmode $where +v $who
				}
			}
		}
		putserv "NOTICE $who :For security reasons, please type: /msg $botnick password <password>. Your default mytrigger is set to: $trigger. To find out my commands, please type ${trigger}commands or $botnick commands."
	}
}