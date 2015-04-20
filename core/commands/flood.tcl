service::commands::register flood 450 [namespace current]::flood_cmd

proc flood_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_flood]
	set chan [join [channel get $channel flood-chan] :]
	set join [join [channel get $channel flood-join] :]
	set ctcp [join [channel get $channel flood-ctcp] :]
	set mjoin [join [channel get $channel service_flood_massjoin] :]
	set btime "[channel get $channel service_bantime_flood]"
	set cmd [lindex [split $text] 0]
	if {$cmd eq "on" || $cmd eq "enable"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel anti-flood is already enabled."
		} else {
			channel set $channel +service_flood
			putserv "NOTICE $nickname :$channel anti-flood is now enabled."
		}
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel anti-flood is already disabled."
		} else {
			channel set $channel -service_flood
			putserv "NOTICE $nickname :$channel anti-flood is now disabled."
		}
	} elseif {$cmd eq "set"} {
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "chan"} {
			set chan_ [lindex [split $text] 2]
			if {$chan_ == ""} {
				putserv "NOTICE $nickname :Syntax: ${lastbind}$command $cmd $cmd_ <x:y>. (where x is lines and y is per seconds)"									
			} elseif {$chan_ == "$chan"} {
				putserv "NOTICE $nickname :flood-chan is already set to $chan_. ([lindex [split $chan :] 0] lines in [lindex [split $chan :] 1] seconds)"
			} elseif {![regexp -nocase {^[\d]{1,3}\:[\d]{1,3}$} $chan_]} {
				putserv "NOTICE $nickname :Invalid setting - Must be in the format: \002x\002:\002y\002 (x lines :(in) y seconds  - where x and y must be positive (not minus) digits)"
			} else {
				channel set $channel flood-chan "$chan_"
				putserv "NOTICE $nickname :flood-chan setting is now set to '$chan_'. ([lindex [split $chan_ :] 0] lines in [lindex [split $chan_ :] 1] seconds)"
			}
		} elseif {$cmd_ eq "join"} {
			set join_ [lindex [split $text] 2]
			if {$join_ == ""} {
				putserv "NOTICE $nickname :Syntax: ${lastbind}$command $cmd $cmd_ <x:y>. (where x is joins and y is per seconds)"
			} elseif {$join_ == "$join"} {
				putserv "NOTICE $nickname :flood-join is already set to $join_. ([lindex [split $join_ :] 0] joins in [lindex [split $join_ :] 1] seconds)"
			} elseif {![regexp -nocase {^[\d]{1,3}\:[\d]{1,3}$} $join_]} {
				putserv "NOTICE $nickname :Invalid setting - Must be in the format: \002x\002:\002y\002 (x joins :(in) y seconds  - where x and y must be positive (not minus) digits)"
			} else {
				channel set $channel flood-join "$join_"
				putserv "NOTICE $nickname :flood-join setting is now set to '$join_'. ([lindex [split $join_ :] 0] joins in [lindex [split $join_ :] 1] seconds)"
			}
		} elseif {$cmd_ eq "ctcp"} {
			set ctcp_ [lindex [split $text] 2]
			if {$ctcp_ == ""} {
				putserv "NOTICE $nickname :Syntax: ${lastbind}$command $cmd $cmd_ <x:y>. (where x is ctcps and y is per seconds)"
			} elseif {$ctcp_ == "$ctcp"} {
				putserv "NOTICE $nickname :flood-ctcp is already set to $ctcp_. ([lindex [split $ctcp :] 0] ctcps in [lindex [split $ctcp :] 1] seconds)"
			} elseif {![regexp -nocase {^[\d]{1,3}\:[\d]{1,3}$} $ctcp_]} {
				putserv "NOTICE $nickname :Invalid setting - Must be in the format: \002x\002:\002y\002 (x ctcps :(in) y seconds  - where x and y must be positive (not minus) digits)"
			} else {
				channel set $channel flood-ctcp "$ctcp_"
				putserv "NOTICE $nickname :flood-ctcp setting is now set to '$ctcp_'. ([lindex [split $ctcp :] 0] ctcps in [lindex [split $ctcp :] 1] seconds)"
			}
		} elseif {$cmd_ eq "massjoin"} {
			set mjoin_ [lindex [split $text] 2]
			if {$mjoin_ == ""} {
				putserv "NOTICE $nickname :Syntax: ${lastbind}$command $cmd $cmd_ <x:y>. (where x is joins and y is per seconds)"
			} elseif {$mjoin_ == "$mjoin"} {
				putserv "NOTICE $nickname :flood-join is already set to $mjoin_. ([lindex [split $mjoin_ :] 0] joins in [lindex [split $mjoin_ :] 1] seconds)"
			} elseif {![regexp -nocase {^[\d]{1,3}\:[\d]{1,3}$} $mjoin_]} {
				putserv "NOTICE $nickname :Invalid setting - Must be in the format: \002x\002:\002y\002 (x joins :(in) y seconds  - where x and y must be positive (not minus) digits)"
			} else {
				channel set $channel service_flood_massjoin "$mjoin_"
				putserv "NOTICE $nickname :flood-join setting is now set to '$mjoin_'. ([lindex [split $mjoin_ :] 0] joins in [lindex [split $mjoin_ :] 1] seconds)"
			}
		} else {
			putserv "NOTICE $nickname :Anti-Dlood settings are either 'chan', 'join', 'ctcp' or 'massjoin'."
		}
	} elseif {$cmd eq "bantime"} {
		set btime_ "[lindex [split $text] 1]"
		if {$btime_ == ""} {
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd <bantime>."
		} elseif {![regexp -nocase {^[\d]{1,}$} $btime_]} {
			putserv "NOTICE $nickname :Bantime must be an integer (number)."
		} elseif {$btime_ == "0"} {
			putserv "NOTICE $nickname :Bantime must be greater than 0."
		} elseif {$btime_ == $btime} {
			putserv "NOTICE $nickname :Bantime is already set at '$btime_' minute(s)"
		} else {
			channel set $channel service_bantime_flood $btime_
			putserv "NOTICE $nickname :flood-bantime set to '$btime_' minute(s)."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		set status "[expr {$status == 1 ? "enabled" : "disabled:"}]"
		if {$btime == "" || $btime == "0"} {
			set btime [channel set $channel service_bantime_flood 2]
		}
		putserv "NOTICE $nickname :$channel anti-flood is \002$status\002. Flood-chan is set to '$chan' ([lindex [split $chan :] 0] lines in [lindex [split $chan :] 1] seconds). Flood-join is set to '$join' ([lindex [split $join :] 0] joins in [lindex [split $join :] 1] seconds). Flood-ctcp is set to '$ctcp' ([lindex [split $ctcp :] 0] ctcps in [lindex [split $ctcp :] 1] seconds). Flood-bantime is set to '$btime' minute(s)."
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|set|bantime|status."
	}
}