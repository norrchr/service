service::commands::register userlist 350 userlist_cmd

proc userlist_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {$text == ""} { putserv "NOTICE $nickname :Syntax: $lastbind -global|-chan|-all|#level (where level is a bot defined user level)."; return }
	array set options {
		{global} {0}
		{all} {0}
		{chan} {0}
		{level} {}
	}
	foreach option [split $text " "] {
		if {$option == ""} { continue }
		if {[string equal -nocase -global $option]} {
			set options(global) 1
		} elseif {[string equal -nocase -all $option]} {
			set options(all) 1
		} elseif {[string equal -nocase -chan $option]} {
			set options(chan) 1
		} elseif {[string index $option 0] == "#"} {
			set options(level) [string tolower [string range $option 1 end]]
			if {![info exists global_user_levels($options(level))] || ![info exists channel_user_levels($options(level))]} {
				putserv "NOTICE $nickname :ERROR: Invalid level '$options(level)' specified."; return
			}
		} else {
			putserv "NOTICE $nickname :ERROR: Invalid option '$option' specified. (Valid options are: -global|-all|-chan|#level)"; return
		}
	}
	if {(!$options(global) && !$options(chan) && !$options(all)) || ($options(all) && ($options(global) || $options(chan)))} {
		putserv "NOTICE $nickname :ERROR: You must supply one of the following options: -global|-chan|-all."; return
	}
	if {$options(global) || $options(all)} {
		if {![matchattr $handle ADnm]} { return }
		if {[llength [userlist ADBSnmovf]]<=0} {
			putserv "NOTICE $nickname :There are no global users."; return
		}
		set id 0; set show 0; set admin 0; set dev 0; set owner 0; set master 0; set op 0; set voice 0; set ban 0; set service 0; set status ""
		foreach user [userlist ADBSnmovf] {
			if {$user == ""} { continue }
			incr id
			if {[matchattr $user B]} {
				set status "Global Ban"; incr ban
			} elseif {[matchattr $user S]} {
				set status "Network Service"; incr service
			} else {
				if {[matchattr $user vf]} {
					set status "Global Voice"; incr voice
				}
				if {[matchattr $user o]} {
					set status "Global Operator"; incr op
				}
				if {[matchattr $user m]} {
					set status "Global Master"; incr master
				}
				if {[matchattr $user n]} {
					set status "Global Owner"; incr owner
				}
				if {[matchattr $user A]} {
					set status "Bot Administrator"; incr admin
				}
				if {[matchattr $user D]} {
					set status "Bot Developer"; incr dev
				}
			}
			if {[set nick [hand2nick $user]] == ""} {
				set nick "Offline"
			}	
			putserv "NOTICE $nickname :(#$id) - $user ($nick) - [join [getuser $user HOSTS] ", "] - +[chattr $user] \002($status)\002."
		}
		putserv "NOTICE $nickname :End of global userlist (Total: $id Developer: $dev Administrator: $admin Owner: $owner Master: $master Op: $op Voice: $voice Service: $service Ban: $ban)."
	}
	if {$options(chan) || $options(all)} {
		if {[llength [userlist |nmovf]]<=0} {
			putserv "NOTICE $nickname :There are no $channel users."; return
		}
		set id 0; set show 0; set owner 0; set master 0; set op 0; set voice 0; set ban 0; set service 0; set status ""
		foreach user [userlist |nmovfS $channel] {
			if {$user == ""} { continue }
			incr id
			if {[matchattr $user |B $channel]} {
				set status "Ban"; incr ban
			}
			if {[matchattr $user |vf $channel]} {
				set status "Voice"; incr voice
			}
			if {[matchattr $user |o $channel]} {
				set status "Operator"; incr op
			}
			if {[matchattr $user |m $channel]} {
				set status "Master"; incr master
			}
			if {[matchattr $user |n $channel]} {
				set status "Owner"; incr owner
			}
			if {[matchattr $user |S $channel]} {
				set status "Network Service"; incr service
			}
			if {[set nick [hand2nick $user]] == ""} {
				set nick "Offline"
			}
			putserv "NOTICE $nickname :(#$id) - $user ($nick) - [join [getuser $user HOSTS] ", "] - +[chattr $user] \002($status)\002."
		}
		putserv "NOTICE $nickname :End of $channel userlist (Total: $id Owner: $owner Master: $master Op: $op Voice: $voice Service: $service Ban: $ban)."
	}
}