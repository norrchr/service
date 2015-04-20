service::commands::register flyby,autoop,ao,autovoice,av,known,bitch,bitchmode 450 misc_cmd

proc misc_cmd {nickname hostname handle channel text} {
	global lastbind lastcommand
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set command_ [string tolower $lastcommand]
	if {$command_ == "autoop" || $command_ == "ao"} {
		set str "auto-op"; set udef "ao"
	} elseif {$command_ == "autovoice" || $command_ == "av"} {
		set str "auto-voice"; set udef "av"
	} else {
		set str $command_; set udef $command_
	}
	set status [channel get $channel service_$udef]
	set cmd [lindex [split $text] 0]
	switch -exact -- $cmd {
		"on" - "enable" {
			if {$status} {
				putserv "NOTICE $nickname :$channel $str is already enabled."
			} else {
				channel set $channel +service_$udef
				if {$command_ eq "bitchmode" && [botisop $channel]} {
					set domode [list]
					foreach user [chanlist $channel] {
						if {$user eq "" || [isbotnick $user]} { continue }
						set hand [nick2hand $user]
						if {[isop $user] && ![matchattr $hand ADnS|nmoS $channel]} {
							lappend domode "-o $user"
						}
						if {[isvoice $user] && ![matchattr $hand ADnmovfS|nmovfS $channel]} {
							lappend domode "-v $user"
						}
					}
					if {[llength $domode]>0} {
						set modes [list]; set params [list]
						foreach dmode $domode {
							if {$dmode eq ""} { continue }
							set mode [lindex [split $dmode] 0]
							set param [lindex [split $dmode] 1]
							lappend modes $mode
							if {$param ne ""} {
								lappend params $param
							}
							if {[llength $modes] eq 6} {
								putserv "MODE $channel [join $modes ""] [join $params " "]"
								set modes [list]; set params [list]
							}
						}
						if {[llength $modes]>0} {
							putserv "MODE $channel [join $modes ""] [join $params " "]"
							set modes [list]; set params [list]
						}
					}
				}
				putserv "NOTICE $nickname :Done. $channel $str is now enabled."
			}
		}
		"off" - "disable" {
			if {!$status} {
				putserv "NOTICE $nickname :$channel $str is already disabled."
			} else {
				channel set $channel -service_$udef
				putserv "NOTICE $nickname :Done. $channel $str is now disabled."
			}
		}
		"status" {
			if {$status} {
				putserv "NOTICE $nickname :$channel $str is enabled."
			} else {
				putserv "NOTICE $nickname :$channel $str is disabled."
			}
		}
		"default" {
			putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|status."
		}
	}
}