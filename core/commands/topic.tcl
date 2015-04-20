service::commands::register topic 450 [namespace current]::topic_cmd

proc topic_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set skin [channel get $channel service_topic_skin]
	set current [channel get $channel service_topic_current]
	set maps [channel get $channel service_topic_map]
	set q [channel get $channel service_topic_Q]
	set save [channel get $channel service_topic_save]
	set force [channel get $channel service_topic_force]
	set cmd [string tolower [lindex [split $text] 0]]
	if {$cmd eq "skin"} {
		set nskin [join [lrange $text 1 end]]
		if {$nskin eq ""} {
			putserv "NOTICE $nickname :Current skin: $skin"
			putserv "NOTICE $nickname :Syntax: $lastbind $cmd <skin>. (Words enclosed in :'s are keywords (example - :channel: :news:))"
		} elseif {[string equal $skin $nskin]} {
			putserv "NOTICE $nickname :ERROR: Skin already set to '$skin'."
		} else {
			channel set $channel service_topic_skin [set skin $nskin]
			# detect keywords??
			# process the new skin??
			putserv "NOTICE $nickname :Done. $channel topic skin set to '$nskin'."
		}
	} elseif {$cmd eq "keyword" || $cmd eq "keywords" || $cmd eq "map"} {
		set locked [list :botnick: :channel:]
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "add" || $cmd_ eq "set"} {
			set m [lindex [split $text] 2]
			set v [join [lrange $text 3 end]]
			if {$m == "" || $v == ""} {
				putserv "NOTICE $nickname :Syntax: $lastbind $cmd_ <map> <value>."
			} elseif {[string index $m 0] != ":" && [string index $m end] != ":"} {
				putserv "NOTICE $nickname :ERROR: keyword must be enclosed within ':'. (Example ':botnick:' ':channel:')"
			} elseif {[lsearch -exact [string tolower $locked] [string tolower $m]]!=-1} {
				putserv "NOTICE $nickname :ERROR: you can not set/change/remove the value of '$m'. (Default map - locked)"
			} elseif {[string length $v]>50} {
				putserv "NOTICE $nickname :ERROR: keyword value can not be greater than 50 characters long."
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
					channel set $channel service_topic_map [set maps [lreplace $maps $pos $pos "$m \{$v\}"]]
					putserv "NOTICE $nickname :Done. Overwriting keyword '$m' with value '$v' to $channel topic keywords list."
				} else {
					channel set $channel service_topic_map [set maps [linsert $maps end "$m \{$v\}"]]
					putserv "NOTICE $nickname :Done. Keyword '$m' with value '$v' saved to $channel topic keywords list."
				}
			}
		} elseif {$cmd_ eq "remove" || $cmd_ eq "unset" || $cmd_ eq "delete" || $cmd_ eq "del"} {
			set m [lindex [split $text] 2]
			if {$m == ""} {
				putserv "NOTICE $nickname :Syntax: $lastbind $cmd_ <map>."
			} elseif {[string index $m 0] != ":" && [string index $m end] != ":"} {
				putserv "NOTICE $nickname :ERROR: keyword must be enclosed within ':'. (Example ':botnick:' ':channel:')"
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
					channel set $channel service_topic_map [set maps [lreplace $maps $pos $pos]]
					putserv "NOTICE $nickname :Done. Removed keyword '$m' with value '$v' from $channel topic keywords list."
				} else {
					putserv "NOTICE $nickname :Error: Keyword '$m' does not exist in $channel topic keywords list."
				}
			}
		} elseif {$cmd_ eq "list"} {
			if {[llength $maps]<=0} {
				putserv "NOTICE $nickname :There are no topic keywords saved for $channel."
			} else {
				putserv "NOTICE $nickname :Keyword - Value:"
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
				putserv "NOTICE $nickname :End of topic keywords list for $channel. ($i keyword(s) saved)"
			}
		} else {
			putserv "NOTICE $nickname :Syntax: $lastbind $cmd add|remove|list ?keyword? ?value?."
		}
	} elseif {$cmd eq "preview"} {
		if {$skin eq ""} { putserv "NOTICE $nickname :ERROR: No topic skin set for $channel."; return }
		set maps [linsert [linsert $maps end ":channel: $channel"] end ":botnick: $::botnick"]
		set topic [string map [join $maps] $skin]
		putserv "NOTICE $nickname :Topic preview for $channel:"
		putserv "NOTICE $nickname :$topic"
	} elseif {$cmd eq "set"} {
		if {$skin eq ""} { putserv "NOTICE $nickname :ERROR: No topic skin set for $channel."; return }
		set maps [linsert [linsert $maps end ":channel: $channel"] end ":botnick: $::botnick"]
		set topic [string map [join $maps] $skin]
		channel set $channel service_topic_current $topic
		if {[channel get $channel service_topic_Q]} {
			putserv "PRIVMSG Q :SETTOPIC $channel $topic"
			putserv "NOTICE $nickname :$channel topic successfully set via Q."
		} elseif {![botisop $channel]} {
			putserv "NOTICE $nickname :ERROR: I need op to set $channel topic."
		} else {						
			putserv "TOPIC $channel :$topic"
			putserv "NOTICE $nickname :$channel topic successfully set via bot."
		}
	} elseif {$cmd eq "q"} {
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "on" || $cmd_ eq "enable"} {
			if {$q} {
				putserv "NOTICE $nickname :$channel topic Q is already enabled."
			} else {
				channel set $channel +service_topic_Q
				putserv "NOTICE $nickname :$channel topic Q is now enabled."
			}
		} elseif {$cmd_ eq "off" || $cmd_ eq "disable"} {
			if {!$q} {
				putserv "NOTICE $nickname :$channel topic Q is already disabled."
			} else {
				channel set $channel -service_topic_Q
				putserv "NOTICE $nickname :$channel topic Q is now disabled."
			}
		} elseif {$cmd_ eq "status" || $cmd_ eq "st"} {
			putserv "NOTICE $nickname :$channel topic Q is: \002[expr {$q == "1" ? "enabled" : "disabled"}]\002."
		} else {
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd_ on|off|status."
		}
	} elseif {$cmd eq "save"} {
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "on" || $cmd_ eq "enable"} {
			if {$save} {
				putserv "NOTICE $nickname :$channel topic save is already enabled."
			} else {
				channel set $channel +service_topic_save
				putserv "NOTICE $nickname :$channel topic save is now enabled."
			}
		} elseif {$cmd_ eq "off" || $cmd_ eq "disable"} {
			if {!$save} {
				putserv "NOTICE $nickname :$channel topic save is already disabled."
			} else {
				channel set $channel -service_topic_save
				putserv "NOTICE $nickname :$channel topic Q is now disabled."
			}
		} elseif {$cmd_ eq "status" || $cmd_ eq "st"} {
			putserv "NOTICE $nickname :$channel topic save is: \002[expr {$save == "1" ? "enabled" : "disabled"}]\002."
		} else {
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd_ on|off|status."
		}
	} elseif {$cmd eq "force"} {
		set cmd_ [string tolower [lindex [split $text] 1]]
		if {$cmd_ eq "on" || $cmd_ eq "enable"} {
			if {$force} {
				putserv "NOTICE $nickname :$channel topic force is already enabled."
			} else {
				channel set $channel +service_topic_force
				putserv "NOTICE $nickname :$channel topic force is now enabled."
			}
		} elseif {$cmd_ eq "off" || $cmd_ eq "disable"} {
			if {!$force} {
				putserv "NOTICE $nickname :$channel topic force is already disabled."
			} else {
				channel set $channel -service_topic_force
				putserv "NOTICE $nickname :$channel topic force is now disabled."
			}
		} elseif {$cmd_ eq "status" || $cmd_ eq "st"} {
			putserv "NOTICE $nickname :$channel topic force is: \002[expr {$force == "1" ? "enabled" : "disabled"}]\002."
		} else {
			putserv "NOTICE $nickname :SYNTAX: $lastbind $cmd_ on|off|status."
		}
	} elseif {$cmd eq "status" || $cmd eq "st"} {
		set maps [linsert [linsert $maps end ":channel: $channel"] end ":botnick: $::botnick"]
		set topic ""
		if {$skin != ""} {
			set topic [string map [join $maps] $skin]
		}
		set keywords [list]
		foreach keyword $maps {
			if {$keyword eq ""} { continue }
			lappend keywords [lindex $keyword 0]
		}
		putserv "NOTICE $nickname :$channel topic skin: $skin"
		putserv "NOTICE $nickname :$channel topic stats: (Q - \002[expr {$q == "1" ? "enabled" : "disabled"}]\002) (Save - \002[expr {$save == "1" ? "enabled" : "disabled"}]\002) (Force - \002[expr {$force == "1" ? "enabled" : "disabled"}]\002) (Keywords - (\002[llength $maps]\002) [join $keywords ", "]) (Skin - \002[expr {$skin eq "" ? "Unset" : "Set"}]\002) (Syncd: \002[expr {[string equal $topic [topic $channel]] ? "Yes" : "No"}]\002)."
	} else {
		putserv "NOTICE $nickname :SYNTAX: $lastbind skin|keyword|preview|set|Q|save|force|status ?arguments?."
	}
}