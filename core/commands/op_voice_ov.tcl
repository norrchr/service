service::commands::register op,voice,deop,devoice,ov,deov 350 [namespace current]::op_voice_ov_cmds

proc op_voice_ov_cmds {nickname hostname handle channel text} {
	global lastbind lastcommand
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {![botisop $channel]} {
		putserv "NOTICE $nickname :$channel $lastcommand: I need op to do that!"
		return
	}
	set bitchmode [channel get $channel service_bitchmode]
	if {$text eq ""} {
		if {[string equal -nocase "op" $command] && [matchattr $handle ADnm|nmo $channel] && ![isop $nickname $channel]} {
			putquick "MODE $channel +o $nickname"
		} elseif {[string equal -nocase "deop" $command] && [matchattr $handle ADnm|nmo $channel] && [isop $nickname $channel]} {
			putquick "MODE $channel -o $nickname"
		} elseif {[string equal -nocase "voice" $command] && [matchattr $handle ADnm|nmovf $channel] && ![isvoice $nickname $channel]} {
			putquick "MODE $channel +v $nickname"
		} elseif {[string equal -nocase "devoice" $command] && [matchattr $handle ADnm|nmovf $channel] && [isvoice $nickname $channel]} {
			putquick "MODE $channel -v $nickname"
		} elseif {[string equal -nocase "ov" $command]} {
			set m [list]
			if {[matchattr $handle ADnm|nmo $channel] && ![isop $nickname $channel]} { lappend m "o" }
			if {[matchattr $handle ADnm|nmovf $channel] && ![isvoice $nickname $channel]} { lappend m "v" }
			if {[llength $m]>=1} {
				putquick "MODE $channel +[join $m ""] [string repeat $nickname [llength $m]]"
			}
		} elseif {[string equal -nocase "deov" $command]} {
			set m [list]
			if {[isop $nickname $channel]} { lappend m "o" }
			if {[isvoice $nickname $channel]} { lappend m "v" }
			if {[llength $m]>=1} {
				putquick "MODE $channel -[join $m ""] [string repeat $nickname [llength $m]]"
			}
		}
	} else {
		set pre [expr {([string equal -nocase "op" $command] || [string equal -nocase "voice" $command] || [string equal -nocase "ov" $command]) ? "+" : "-"}]
		set mode [expr {([string equal -nocase "op" $command] || [string equal -nocase "deop" $command]) ? "o" : "v"}]
		if {[string equal -nocase "ov" $command] || [string equal -nocase "deov" $command]} { set mode [list] }
		set users [list]; set notonchan [list]; set blocked [list]
		foreach user $text {
			if {$user eq ""} { continue }
			if {[lsearch -exact [split $user ""] *]>=0 || [lsearch -exact [split $user ""] ?]>=0} {
				set matches [lsearch -all -inline [string tolower [chanlist $channel]] [string tolower [string map { \[ \\[ \] \\] \{ \\{ \} \\} } $user]]]
				putlog "Wildcard matches: [join $matches " "]"
				if {[llength $matches]<=0} { continue }
				set matched [list]
				foreach match $matches {
					if {$match eq ""} { continue }
					set hand [nick2hand $match]
					if {[matchattr $hand Bd|Bd $channel]} { lappend blocked $match; continue }
					if {[string equal -nocase "op" $command] && ![isop $match $channel]} {
						if {$bitchmode && ![matchattr $hand |nmoS $channel]} { lappend blocked $match; continue }
						lappend matched $match; putlog "Wildcard match: $match"
					} elseif {[string equal -nocase "deop" $command] && [isop $match $channel]} {
						lappend matched $match; putlog "Wildcard match: $match"
					} elseif {[string equal -nocase "voice" $command] && ![isvoice $match $channel]} {
						if {$bitchmode && ![matchattr $hand |nmovfS $channel]} { lappend blocked $match; continue }
						lappend matched $match; putlog "Wildcard match: $match"
					} elseif {[string equal -nocase "devoice" $command] && [isvoice $match $channel]} {
						lappend matched $match; putlog "Wildcard match: $match"
					} elseif {[string equal -nocase "ov" $command]} {
						if {$bitchmode && ![matchattr $hand |nmoS $channel]} {
							lappend blocked $match; continue
						} elseif {![isop $match $channel]} {
							lappend mode "o"; lappend matched $match
						}
						if {$bitchmode && ![matchattr $hand |nmovfS $channel]} {
							lappend blocked $match; continue
						} elseif {![isvoice $match $channel]} {
							lappend mode "v"; lappend matched $match
						}
					} elseif {[string equal -nocase "deov" $command]} {
						if {[isop $match $channel]} { lappend mode "o"; lappend matched $match }
						if {[isvoice $match $channel]} { lappend mode "v"; lappend matched $match }
					}										
					if {[llength $matched] eq 6} {
						putlog "Wildcard matched: [join $matched " "]"
						if {[string equal -nocase "ov" $command] || [string equal -nocase "deov" $command] && [llength $mode] eq 6} {
							putlog "MODE $channel ${pre}[join $mode ""] [join $matched " "]"
							putquick "MODE $channel ${pre}[join $mode ""] [join $matched " "]"
							set mode [list]
						} else {
							putlog "MODE $channel ${pre}[string repeat $mode 6] [join $matched " "]"
							putquick "MODE $channel ${pre}[string repeat $mode 6] [join $matched " "]"
						}
						set matched [list]
					}
				}
				if {[llength $matched]>0} {
					putlog "Wildcard matched: [join $matched " "]"
					if {[string equal -nocase "ov" $command] || [string equal -nocase "deov" $command] && [llength $mode]>0} {
						putlog "MODE $channel ${pre}[join $mode ""] [join $matched " "]"
						putquick "MODE $channel ${pre}[join $mode ""] [join $matched " "]"
						set mode [list]
					} else {
						putlog "MODE $channel ${pre}[string repeat $mode [llength $matched]] [join $matched " "]"
						putquick "MODE $channel ${pre}[string repeat $mode [llength $matched]] [join $matched " "]"
					}
					set matched [list]
				}
			} elseif {![onchan $user $channel]} {
				lappend notonchan $user
			} elseif {[matchattr [set hand [nick2hand $user]] Bd|Bd $channel]} {
				lappend blocked $user
			} else {
				if {[string equal -nocase "op" $command] && ![isop $user $channel]} {
					if {$bitchmode && ![matchattr $hand |nmoS $channel]} { lappend blocked $user; continue }
					lappend users $user
				} elseif {[string equal -nocase "deop" $command] && [isop $user $channel]} {
					lappend users $user
				} elseif {[string equal -nocase "voice" $command] && ![isvoice $user $channel]} {
					if {$bitchmode && ![matchattr $hand |nmovfS $channel]} { lappend blocked $user; continue }
					lappend users $user
				} elseif {[string equal -nocase "devoice" $command] && [isvoice $user $channel]} {
					lappend users $user
				} elseif {[string equal -nocase "ov" $command]} {
					if {$bitchmode && ![matchattr $hand |nmoS $channel]} {
						lappend blocked $user; continue
					} elseif {![isop $user $channel]} {
						lappend mode "o"; lappend users $user
					}
					if {$bitchmode && ![matchattr $hand |nmovfS $channel]} {
						lappend blocked $user; continue
					} elseif {![isvoice $user $channel]} {
						lappend mode "v"; lappend users $user
					}
				} elseif {[string equal -nocase "deov" $command]} {
					if {[isop $user $channel]} { lappend mode "o"; lappend users $user }
					if {[isvoice $user $channel]} { lappend mode "v"; lappend users $user }
				}									
				if {[llength $users] eq 6} {
					if {[string equal -nocase "ov" $command] || [string equal -nocase "deov" $command] && [llength $mode]>0} {
						putlog "MODE $channel ${pre}[join $mode ""] [join $users " "]"
						putquick "MODE $channel ${pre}[join $mode ""] [join $users " "]"
						set mode [list]
					} else {
						putquick "MODE $channel ${pre}[string repeat $mode 6] [join $users " "]"
					}
					set users [list]
				}
			}
		}
		if {[llength $users]>0} {
			if {[string equal -nocase "ov" $command] || [string equal -nocase "deov" $command] && [llength $mode]>0} {
				putlog "MODE $channel ${pre}[join $mode ""] [join $users " "]"
				putquick "MODE $channel ${pre}[join $mode ""] [join $users " "]"
				set mode [list]
			} else {
				putquick "MODE $channel ${pre}[string repeat $mode [llength $users]] [join $users " "]"
			}
			set users [list]
		}
		set blocked [lsort -unique $blocked]
		putquick "NOTICE $nickname :Done. (Not on ${channel}: [expr {[llength $notonchan]<=0 ? "N/A" : [join $notonchan ", "]}] - Blocked: [expr {[llength $blocked]<=0 ? "N/A" : [join $blocked ", "]}])"
	}
}