service::commands::register enforcemodes 450 enforcemodes_cmd

proc enforcemodes_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_enforcemodes]
	set enforcedmodes [string map { k, {} l, {} } [channel get $channel service_enforcedmodes]]
	set cmd [string tolower [lindex [split $text] 0]]
	if {$cmd eq "on" || $cmd eq "enable"} {
		if {$status} {
			putserv "NOTICE $nickname :ERROR: $channel enforcemodes is already enabled."
		} else {
			channel set $channel +service_enforcemodes
			putserv "NOTICE $nickname :Done. $channel enforcemodes is now enabled."
		}
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :ERROR: $channel enforcemodes is already disabled."
		} else {
			channel set $channel -service_enforcemodes
			putserv "NOTICE $nickname :Done. $channel enforcemodes is now disabled."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		putserv "NOTICE $nickname :$channel enforcemodes is [expr {$status eq 1 ? "enabled" : "disabled:"}]. Enforcedmodes set to '$enforcedmodes'."
	} elseif {$cmd eq "set"} {
		set valid [list C c D s t T r p u n N m M i l k]
		if {[lrange $text 1 end] eq ""} { putserv "NOTICE $nickname :Syntax: $lastbind $cmd +-modes ?params?. (Valid modes: [lsort [join $valid ""]])"; return }
		set modes [lindex [split $text] 1]
		set params [join [lrange $text 2 end]]
		set pre ""; set plus [list]; set minus [list]; set eparams [list]; set invalid [list]
		for {set i 0} {$i<[string length $modes]} {incr i} {
			set chr [string index $modes $i]
			if {$chr eq ""} { continue }
			if {$chr eq "+" || $chr eq "-"} { set pre $chr; continue }
			if {$pre eq ""} { putserv "NOTICE $nickname :ERROR: Syntax: ${lastbind}$command $cmd +-modes ?params?"; return }
			if {[lsearch -exact $valid $chr] eq -1} { lappend invalid $chr; continue }
			if {$pre eq "+" && $chr eq "l"} {
				set param [lindex [split $params] 0]
				if {$param eq "" || ![string is integer $param]} {
					putserv "NOTICE $nickname :ERROR: You didn't provide a valid parameter for +l."; return
				} elseif {$param eq "0" || $param <= [llength [chanlist $channel]]} {
					putserv "NOTICE $nickname :ERROR: Limit must be greater than the number of users currently on $channel."; return
				} elseif {[channel get $channel service_autolimit]} {
					putserv "NOTICE $nickname :ERROR: $channel autolimit is currently enabled -- Ignoring +l."; set params [lreplace $params 0 0]; continue
				} else {
					lappend plus "l"; lappend eparams "l,$param"; set params [lreplace $params 0 0]; continue
				}
			} elseif {$pre eq "-" && $chr eq "l" && [channel get $channel service_autolimit]} {
				putserv "NOTICE $nickname :ERROR: $channel autolimit is currently enabled -- Ignoring -l."; continue
			} elseif {$pre eq "+" && $chr eq "k"} {
				set param [lindex [split $params] 0]
				if {$param eq ""} {
					putserv "NOTICE $nickname :ERROR: You didn't provide a valid parameter for +k."; return
				} elseif {[string match *,* $param]} {
					putserv "NOTICE $nickname :ERROR: Invalid key specified."; return
				} else {
					lappend plus "k"; lappend eparams "k,$param"; set params [lreplace $params 0 0]; continue
				}
			} elseif {$pre eq "+"} {
				lappend plus $chr
			} elseif {$pre eq "-"} {
				lappend minus $chr
			}
		}
		set plus [join $plus ""]; set minus [join $minus ""]
		set conflict [list]
		foreach mode $plus {
			if {$mode eq ""} { continue }
			if {[string match *$mode* $minus]} { lappend conflict $mode }
		}
		if {[llength $conflict]>0} {
			putserv "NOTICE $nickname :ERROR: You can not enforce  mode(s) '[join $conflict ""]' both ways."; return				
		}
		channel set $channel service_enforcedmodes "+${plus}-${minus} $eparams"
		set key ""; set limit ""
		if {[string match *l* [getchanmode $channel]]} {
			if {[string match *k* [getchanmode $channel]]} {
				set limit [lindex [split [getchanmode $channel]] 2]
				set key [lindex [split [getchanmode $channel]] 1]
			} else {
				set limit [lindex [split [getchanmode $channel]] 1]
			}
		}							
		if {[botisop $channel]} {
			set domodes [list]; set doparams [list]
			foreach mode $plus {
				if {$mode eq ""} { continue }
				if {$mode eq "l" || $mode eq "k"} {
					set tmp [lindex [split $eparams] 0]
					if {[string index $tmp 0] eq $mode} {
						set tmp [string trimleft $tmp ${mode},]
					} else {
						set tmp [string trimleft [lindex [split $eparams] 1] ${mode},]
					}
					if {![string match *$mode* [getchanmode $channel]]} {										
						lappend domodes "+$mode"; lappend doparams $tmp
					} elseif {$chr eq "l" && $limit nq $tmp} {
						lappend domodes "+$mode"; lappend doparams $tmp
					} elseif {$chr eq "k" && ![string equal $key $tmp]} {
						lappend domodes "+$mode"; lappend doparams $tmp
					}	
				} elseif {![string match *$mode* [getchanmode $channel]]} {
					lappend domodes "+$mode"
				}
				if {[llength $domodes] eq 6} {
					putserv "MODE $channel [join $domodes ""] [join $doparams " "]"
					set domodes [list]; set doparams [list]
				}
			}
			foreach mode $minus {
				if {$mode eq ""} { continue }
				if {$mode eq "k" && [string match *$mode* [getchanmode $channel]]} {
					lappend domodes "-$mode"; lappend doparams $key
				} elseif {[string match *$mode* [getchanmode $channel]]} {
					lappend domodes "-$mode"
				}
				if {[llength $domodes] eq 6} {
					putserv "MODE $channel [join $domodes ""] [join $doparams " "]"
					set domodes [list]; set doparams [list]
				}
			}
			if {[llength $domodes]>0} {
				putserv "MODE $channel [join $domodes ""] [join $doparams " "]"
				set domodes [list]; set doparams [list]
			}	
		}	
		putserv "NOTICE $nickname :Done. Set enforcedmodes for $channel to '+${plus}-${minus} [string map { k, {} l, {} } [join $eparams " "]]'."
	} else {
		putserv "NOTICE $nickname :Syntax: $lastbind on|off|set|status ?arguments?."
	}
}