service::commands::register banclear,bc 450 [namespace current]::banclear_cmd

proc banclear_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {$text == ""} { putserv "NOTICE $nickname :Syntax: $lastbind -global|-all|-list|-perm|-temp|-chan|#MINUTES (if #MINUTES is specified, only bans added <= MINUTES ago will be removed)."; return }
	array set options {
		{global} {0}
		{all} {0}
		{list} {0}
		{perm} {0}
		{temp} {0}
		{chan} {0}
		{time} {-1}
	}
	foreach option [split $text " "] {
		if {$option == ""} { continue }
		if {[string equal -nocase -global $option]} {
			set options(global) 1
		} elseif {[string equal -nocase -all $option]} {
			set options(all) 1
		} elseif {[string equal -nocase -list $option]} {
			set options(list) 1
		} elseif {[string equal -nocase -perm $option]} {
			set options(perm) 1
		} elseif {[string equal -nocase -temp $option]} {
			set options(temp) 1
		} elseif {[string equal -nocase -chan $option]} {
			set options(chan) 1
		} elseif {[string index $option 0] == "#"} {
			if {![string is integer [set options(time) [string range $option 1 end]]] || $options(time) <=0} {
				putserv "NOTICE $nickname :ERROR: Minutes must be an integer greater than 0."; return
			} else {
				set options(time) [expr {60*$options(time)}]
			}
		} else {
			putserv "NOTICE $nickname :ERROR: Invalid option '$option' specified. (Valid options are: -global|-all|-list|-perm|-temp|-chan|#MINUTES)"; return
		}
	}
	#if {$options(time) == 0} {
	#	putserv "NOTICE $nickname :ERROR: Minutes must be greater than 0."; return
	#} else {
	#	set options(time) [expr {60*$options(time)}]
	#}
	if {$options(global)} {
		if {![matchattr $handle nm]} { return }
		if {$options(chan)} {
			putserv "NOTICE $nickname :ERROR: Invalid option '-chan' specified with '-global' option."; return
		}
		if {($options(perm) == "0" && $options(temp) == "0") && !$options(all)} {
			putserv "NOTICE $nickname :ERROR: Please specify '-perm', '-temp' or '-all' along with '-global' option."; return
		}		
		set id 0; set btime 0; set perm 0; set nonperm 0; set kp 0; set kt 0; set perml [list]; set nonperml [list]
		foreach ban [banlist] {
			if {$ban == ""} { continue }
			set btime [lindex $ban 3]
			set ban [lindex $ban 0]
			incr id
			if {[ispermban $ban] && ($options(perm) || $options(all))} {
				incr perm
				if {$options(time)>0 && [expr {[unixtime]-$btime}] > $options(time)} { continue }
				if {[killban $ban]} {
					incr kp
					lappend perml $ban
				}
			} elseif {![ispermban $ban] && ($options(temp) || $options(all))} {
				incr nonperm
				if {$options(time)>0 && [expr {[unixtime]-$btime}] > $options(time)} { continue }
				if {[killban $ban]} {
					incr kt
					lappend nonperml $ban
				}
			}
		}
		if {$kp > 0 || $kt > 0} {
			foreach chan [channels] {
				if {![botisop $chan]} { continue }
				foreach ban [join "$perml $nonperml"] {
					if {$ban == ""} { continue }
					if {[ischanban $ban $chan]} {
						pushmode $chan -b $ban
					}
					flushmode $chan
				}
			}
		}
		if {$kp > 0} {
			if {$options(list)} {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kp global permban(s) <= $options(time) seconds old: [join $perml "; "]."
				} else {
					putserv "NOTICE $nickname :Removed $kp global permban(s): [join $perml "; "]"
				}
				#if {[llength $perml] > 8} {
				#	set bans [list]
				#	foreach ban $perml {
				#		if {$ban == ""} { continue }
				#		lappend bans $ban
				#		if {[llength $bans] == 8} {
				#			putserv "NOTICE $nickname: [join $bans "; "]"
				#			set bans [list]
				#		}
				#	}
				#	if {[llength $bans] > 0} {
				#		putserv "NOTICE $nickname :[join $perml "; "]"
				#	}
				#} else {
				#	putserv "NOTICE $nickname [join $bans "; "]"
				#}
			} else {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kp global permban(s) <= $options(time) seconds old."
				} else {
					putserv "NOTICE $nickname :Removed $kp global permban(s)."
				}
			}
		}
		if {$kt > 0} {
			if {$options(list)} {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kt global permban(s) <= $options(time) seconds old: [join $nonperml "; "]"
				} else {
					putserv "NOTICE $nickname :Removed $kt global permban(s): [join $nonperml "; "]"
				}
				#if {[llength $nonperml] > 8} {
				#	set bans [list]
				#	foreach ban $nonperml {
				#		if {$ban == ""} { continue }
				#		lappend bans $ban
				#		if {[llength $bans] == 8} {
				#			putserv "NOTICE $nickname: [join $bans "; "]"
				#			set bans [list]
				#		}
				#	}
				#	if {[llength $bans] > 0} {
				#		putserv "NOTICE $nickname :[join $bans "; "]"
				#	}
				#} else {
				#	putserv "NOTICE $nickname [join $nonperml "; "]"
				#}
			} else {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kt global permban(s) <= $options(time) seconds old."
				} else {
					putserv "NOTICE $nickname :Removed $kt global permban(s)."
				}
			}
		}
		if {$options(all)} {
			if {$options(time)>0} {
				putserv "NOTICE $nickname :Removed a total of [set t [expr {$kt + $kp}]] global ban(s) <= $options(time) seconds old (Total: $t/$id Permanent: $kp/$perm Non-permanent: $kt/$nonperm)."
			} else {
				putserv "NOTICE $nickname :Removed a total of [set t [expr {$kt + $kp}]] global ban(s) (Total: $t/$id Permanent: $kp/$perm Non-permanent: $kt/$nonperm)."
			}
		}
	} else {
		# channel		
		if {($options(perm) == "0" && $options(temp) == "0" && $options(chan) == "0") && !$options(all)} {
			putserv "NOTICE $nickname :ERROR: Please specify '-perm', '-temp', '-chan' or '-all'."; return
		}		
		set id 0; set btime 0; set perm 0; set nonperm 0; set kp 0; set kt 0; set perml [list]; set nonperml [list];
		set cb 0; set kc 0; set chanbans [list];		
		foreach ban [chanbans $channel] {
			if {$ban == ""} { continue }
			set btime [lindex $ban 2]; set ban [lindex $ban 0]
			if {![isban $ban $channel] && ($options(chan) || $options(all))} {
				incr cb
				if {$options(time)>0 && $btime > $options(time)} { continue }
				if {[botisop $channel]} {
					pushmode $channel -b $ban
					incr kc
					lappend chanbans $ban
				}
			}
		}		
		foreach ban [banlist $channel] {
			if {$ban == ""} { continue }
			set btime [lindex $ban 3]
			set ban [lindex $ban 0]
			incr id
			if {[ispermban $ban $channel] && ($options(perm) || $options(all))} {
				incr perm
				if {$options(time)>0 && [expr {[unixtime]-$btime}] > $options(time)} { continue }
				if {[killchanban $channel $ban]} {
					incr kp
					lappend perml $ban
					if {[botisop $channel]} {
						pushmode $channel -b $ban
					}
				}
			} elseif {![ispermban $ban $channel] && ($options(temp) || $options(all))} {
				incr nonperm
				if {$options(time)>0 && [expr {[unixtime]-$btime}] > $options(time)} { continue }
				if {[killchanban $channel $ban]} {
					incr kt
					lappend nonperml $ban
					if {[botisop $channel]} {
						pushmode $channel -b $ban
					}
				}
			}
		}
		flushmode $channel		
		if {$kc > 0} {
			if {$options(list)} {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kc $channel chanban(s) <= $options(time) seconds old: [join $chanbans "; "]."
				} else {
					putserv "NOTICE $nickname :Removed $kc $channel chanban(s): [join $chanbans "; "]."
				}
				#if {[llength $chanbans] > 8} {
				#	set bans [list]
				#	foreach ban $chanbans {
				#		if {$ban == ""} { continue }
				#		lappend bans $ban
				#		if {[llength $bans] == 8} {
				#			putserv "NOTICE $nickname: [join $bans "; "]"
				#			set bans [list]
				#		}
				#	}
				#	if {[llength $bans] > 0} {
				#		putserv "NOTICE $nickname :[join $bans "; "]"
				#	}
				#} else {
				#	putserv "NOTICE $nickname [join $chanbans "; "]"
				#}
			} else {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kc $channel chanban(s) <= $options(time) seconds old."
				} else {
					putserv "NOTICE $nickname :Removed $kc $channel chanban(s)."
				}
			}
		}		
		if {$kp > 0} {
			if {$options(list)} {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kp $channel permban(s) <= $options(time) seconds old: [join $perml "; "]."
				} else {
					putserv "NOTICE $nickname :Removed $kp $channel permban(s): [join $perml "; "]."
				}
				#if {[llength $perml] > 8} {
				#	set bans [list]
				#	foreach ban $perml {
				#		if {$ban == ""} { continue }
				#		lappend bans $ban
				#		if {[llength $bans] == 8} {
				#			putserv "NOTICE $nickname: [join $bans "; "]"
				#			set bans [list]
				#		}
				#	}
				#	if {[llength $bans] > 0} {
				#		putserv "NOTICE $nickname :[join $bans "; "]"
				#	}
				#} else {
				#	putserv "NOTICE $nickname [join $perml "; "]"
				#}
			} else {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kp $channel permban(s) <= $options(time) seconds old."
				} else {
					putserv "NOTICE $nickname :Removed $kp $channel permban(s)."
				}
			}
		}
		if {$kt > 0} {
			if {$options(list)} {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kt $channel tempban(s) <= $options(time) seconds old: [join $nonperml "; "]."
				} else {
					putserv "NOTICE $nickname :Removed $kt $channel tempban(s): [join $nonperml "; "]."
				}
				#if {[llength $nonperml] > 8} {
				#	set bans [list]
				#	foreach ban $nonperml {
				#		if {$ban == ""} { continue }
				#		lappend bans $ban
				#		if {[llength $bans] == 8} {
				#			putserv "NOTICE $nickname: [join $bans "; "]"
				#			set bans [list]
				#		}
				#	}
				#	if {[llength $bans] > 0} {
				#		putserv "NOTICE $nickname :[join $bans "; "]"
				#	}
				#} else {
				#	putserv "NOTICE $nickname [join $nonperml "; "]"
				#}
			} else {
				if {$options(time)>0} {
					putserv "NOTICE $nickname :Removed $kt $channel tempban(s) <= $options(time) seconds old."
				} else {
					putserv "NOTICE $nickname :Removed $kt $channel tempban(s)."
				}
			}
		}
		incr id $cb
		if {$options(all)} {
			if {$options(time)>0} {
				putserv "NOTICE $nickname :Removed a total of [set t [expr {$kc + $kt + $kp}]] $channel ban(s) <= $options(time) seconds old (Total: $t/$id Permanent: $kp/$perm Non-permanent: $kt/$nonperm Channel bans: $kc/$cb)."
			} else {
				putserv "NOTICE $nickname :Removed a total of [set t [expr {$kc + $kt + $kp}]] $channel ban(s) (Total: $t/$id Permanent: $kp/$perm Non-permanent: $kt/$nonperm Channel bans: $kc/$cb)."
			}
		}
	}
}