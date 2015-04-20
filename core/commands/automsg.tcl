service::commands::register automsg 450 automsg_cmd

proc automsg_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_automsg]
	set last [channel get $channel service_automsg_last]
	set counter [channel get $channel service_automsg_counter]
	set interval [channel get $channel service_automsg_interval]
	set moderate [channel get $channel service_automsg_moderate]
	set method [channel get $channel service_automsg_method]
	set messages [channel get $channel service_automsg_messages]
	set maps [channel get $channel service_automsg_maps]
	set cmd [string tolower [lindex [split $text] 0]]
	if {$cmd eq "on" || $cmd eq "enable"} {
		if {$status} {
			putserv "NOTICE $nickname :$channel automsg is already enabled."
		} else {
			channel set $channel +service_automsg
			if {$last<0} { channel set $channel service_automsg_last 0 }
			if {$method eq ""} { channel set $channel service_automsg_method "loop" }
			if {$interval<5 || $interval>1440} { channel set $channel service_automsg_interval [set interval 5] }
			if {$counter<$interval} { channel set $channel service_automsg_counter $interval }
			putserv "NOTICE $nickname :$channel automsg is now enabled."
		}
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :$channel automsg is already disabled."
		} else {
			channel set $channel -service_automsg
			putserv "NOTICE $nickname :$channel automsg is now disabled."
		}
	} elseif {$cmd eq "list"} {
		if {[llength $messages]<=0} { putserv "NOTICE $nickname :There are no saved auto-messages for $channel."; return }
		set extended 0
		putserv "NOTICE $nickname :Message #ID - Message content:"
		set i 1; set grouped 0
		foreach message $messages {
			if {$message eq ""} { continue }
			if {[llength [split $message \n]]<=1} {
				putserv "NOTICE $nickname :(#$i) $message"; incr i; continue
			} else {
				set e 1
				foreach emessage [split $message \n] {
					if {$emessage eq ""} { continue }
					putserv "NOTICE $nickname :(#${i}-${e}) $emessage"; incr e; incr grouped; continue
				}
			}
		}
		putserv "NOTICE $nickname :End of saved auto-messages for $channel. ([llength $messages] message(s) with $grouped grouped message(s))"
	} elseif {$cmd eq "interval"} {
		set int [lindex [split $text] 1]
		if {[string index $int 0] != "#" || ![string is integer [set int [string trimleft $int #]]] || ($int<5 || $int>1440)} {
			putserv "NOTICE $nickname :Syntax: $lastbind $cmd <#interval>. (Where interval must be a number between 5-1440)"
		} elseif {$int eq $interval} {
			putserv "NOTICE $nickname :ERROR: Interval is already set to '#$int' minute(s)."; return
		} else {
			channel set $channel service_automsg_interval $int
			putserv "NOTICE $nickname :Done. Auto-message interval for $channel set to '#$int' minute(s)."
		}
	} elseif {$cmd eq "moderate"} {
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "on" || $cmd_ eq "enable"} {
			if {$moderate} {
				putserv "NOTICE $nickname :$channel auto-message moderate is already enabled."
			} else {
				channel set $channel +service_automsg_moderate
				putserv "NOTICE $nickname :$channel auto-message moderate is now enabled."
			}
		} elseif {$cmd_ eq "off" || $cmd_ eq "disable"} {
			if {!$moderate} {
				putserv "NOTICE $nickname :$channel auto-message moderate is already disabled."
			} else {
				channel set $channel -service_automsg_moderate
				putserv "NOTICE $nickname :$channel auto-message moderate is now disabled."
			}
		} elseif {$cmd_ eq "st" || $cmd_ eq "st"} {
			putserv "NOTICE $nickname :$channel auto-message moderate is: \002[expr {$moderare ? "enabled" : "disabled"}]\002."
		} else {
			putserv "NOTICE $nickname :Syntax: $lastbind $cmd on|off|status."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		putserv "NOTICE $nickname :$channel auto-message is: \002[expr {$status ? "enabled" : "disabled"}]\002 with [llength $messages] auto-message(s) and [expr {[llength $maps]+2}] map(s) saved. Interval is set to: \002#$interval\002 minute(s). Moderate is: \002[expr {$moderate ? "enabled" : "disabled"}]\002. Method is: \002$method\002."
	} elseif {$cmd eq "group"} {
		putserv "NOTICE $nickname :Coming Soon!"; return
	} elseif {$cmd eq "add"} {
		if {$text eq ""} { putserv "NOTICE $nickname :Syntax: $lastbind $cmd ?#position? <message>."; return }
		set pos [lindex [split $text] 1]
		if {[string index $pos 0] == "#"} {
			set pos [string trimleft $pos #]
			if {$pos eq "" || ![string is integer $pos]} { putserv "NOTICE $nickname :ERROR: Position must be an integer."; return }
			if {$pos<=0} { putserv "NOTICE $nickname :ERROR: Position can not be a negative number."; return }
			if {$pos>[llength $messages]} {
				putserv "NOTICE $nickname :Position is greater than the number of saved messages, set position to end of saved messages."
				set pos "end"
			}
			set message [join [lrange $text 2 end]]
		} else {
			set pos "end"; set message [join [lrange $text 1 end]]
		}
		if {$message eq ""} { putserv "NOTICE $nickname :ERROR: You need to supply a message."; return }
		channel set $channel service_automsg_messages [set messages [linsert $messages [expr {$pos eq "end" ? $pos : $pos-1}] $message]]
		putserv "NOTICE $nickname :Done. $channel auto-message saved to position #[expr {$pos eq "end" ? [llength $messages] : $pos}]/[llength $messages]."
	} elseif {$cmd eq "remove"} {
		if {$text eq ""} { putserv "NOTICE $nickname :Syntax: $lastbind $cmd <#id>."; return }
		set id [lindex [split $text] 1]
		if {[string index $id 0] == "#"} {
			set id [string trimleft $id #]
			if {$id eq "" || ![string is integer $id]} { putserv "NOTICE $nickname :ERROR: ID must be an integer."; return }
			if {$id<0} { putserv "NOTICE $nickname :ERROR: ID can not be a negative number."; return }
			if {$id>[llength $messages]} { putserv "NOTICE $nickname :Invalid message #id."; return }
			channel set $channel service_automsg_messages [set messages [lreplace $messages $id-1 $id-1]]
			putserv "NOTICE $nickname :Done. $channel auto-message removed from position #[expr {$id eq "end" ? [llength $messages] : $id}]/[llength $messages]."
		} else {
			putserv "NOTICE $nickname :Error: ID must start with #."; return
		}
	} elseif {$cmd eq "map"} {
		set locked [list :botnick: :channel:]
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "add"} {
			set m [lindex [split $text] 2]
			set v [join [lrange $text 3 end]]
			if {$m == "" || $v == ""} {
				putserv "NOTICE $nickname :Syntax: $lastbind $cmd_ <map> <value>."
			} elseif {[string index $m 0] != ":" && [string index $m end] != ":"} {
				putserv "NOTICE $nickname :ERROR: map must be enclosed within ':'. (Example ':botnick:' ':channel:')"
			} elseif {[lsearch -exact [string tolower $locked] [string tolower $m]]!=-1} {
				putserv "NOTICE $nickname :ERROR: you can not set/change/remove the value of '$m'. (Default map - locked)"
			} elseif {[string length $v]>80} {
				putserv "NOTICE $nickname :ERROR: map value can not be greater than 80 characters long."
			} else {
				set pos 0; set f 0
				foreach map $maps {
					if {$map == ""} { continue }
					if {[string equal -nocase $m [lindex [split $map] 0]]} {
						set f 1; break
					}
					incr pos
				}
				if {$f} {
					channel set $channel service_automsg_maps [set maps [lreplace $maps $pos $pos "$m \{$v\}"]]
					putserv "NOTICE $nickname :Done. Overwriting map '$m' with value '$v' to $channel auto-messsage maps list."
				} else {
					channel set $channel service_automsg_maps [set maps [linsert $maps end "$m \{$v\}"]]
					putserv "NOTICE $nickname :Done. Map '$m' with value '$v' saved to $channel auto-message maps list."
				}
			}
		} elseif {$cmd_ eq "remove"} {
			set m [lindex [split $text] 2]
			if {$m == ""} {
				putserv "NOTICE $nickname :Syntax: $lastbind $cmd_ <map>."
			} elseif {[string index $m 0] != ":" && [string index $m end] != ":"} {
				putserv "NOTICE $nickname :ERROR: map must be enclosed within ':'. (Example ':botnick:' ':channel:')"
			} elseif {[lsearch -exact [string tolower $locked] [string tolower $m]]!=-1} {
				putserv "NOTICE $nickname :ERROR: you can not set/change/remove the value of '$m'. (Default map - locked)"
			} else {
				set pos 0; set f 0
				foreach map $maps {
					if {$map == ""} { continue }
					if {[string equal -nocase $m [lindex [split $map] 0]]} {
						set v [join [lrange $map 1 end]]; set f 1; break
					}
					incr pos
				}
				if {$f} {
					channel set $channel service_automsg_maps [set maps [lreplace $maps $pos $pos]]
					putserv "NOTICE $nickname :Done. Removed map '$m' with value '$v' from $channel auto-messsage maps list."
				} else {
					putserv "NOTICE $nickname :Error: Map '$m' does not exist in $channel auto-message maps list."
				}
			}
		} elseif {$cmd_ eq "list"} {
			if {[llength $maps]<=0} {
				putserv "NOTICE $nickname :There a no auto-message maps saved for $channel."
			} else {
				putserv "NOTICE $nickname :Map - Value:"
				putserv "NOTICE $nickname ::botnick: - $::botnick"
				putserv "NOTICE $nickname ::channel: - $channel"
				set i 2
				foreach map $maps {
					if {$map == ""} { continue }
					set m [lindex [split $map] 0]
					set v [join [lrange $map 1 end]]
					if {$v == ""} { continue }
					putserv "NOTICE $nickname :$m - $v"
					incr i
				}
				putserv "NOTICE $nickname :End of auto-message maps list for $channel. ($i map(s) saved)"
			}
		} else {
			putserv "NOTICE $nickname :Syntax: $lastbind $cmd add|remove|list ?map? ?value?."
		}
	} elseif {$cmd eq "method"} {
		set valid [list random loop default]
		if {[set method [string tolower [lindex [split $text] 1]]] eq ""} {
			putserv "NOTICE $nickname :Syntax: $lastbind $cmd ?method?. (Valid methods: [lsort [join $valid ", "]])"
		} elseif {![lsearch -exact $valid $method]==-1} {
			putserv "NOTICE $nickname :ERROR: Invalid method '$method' - Valid methods: [lsort [join $valid ", "]]."
		} else {
			channel set $channel service_automsg_method $method
			putserv "NOTICE $nickname :Done. $channel auto-message method set to '$method'."
		}
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|add|remove|list|interval|moderate|group|method|map ?arguements?."
	}
}