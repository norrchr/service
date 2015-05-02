proc sortmodes {mstr} {
	if {$mstr eq ""} { return }
	regsub -all { } $mstr "" mstr
	array set modes { {+} {} {-} {} }
	set pre +; set smodes [list]
	foreach chr [split $mstr ""] {
		if {$chr == "+" || $chr == "-"} { set pre $chr; continue }
		#putlog "appending $chr to $pre list"
		lappend modes($pre) "$chr"
	}
	#putlog "+ modes: $modes(+)"
	#putlog "- modes: $modes(-)"
	if {[llength $modes(+)] >= 1} {
		#putlog "appending + modes to smodes: $modes(+)"
		lappend smodes +[join $modes(+) ""]
	}
	if {[llength $modes(-)] >= 1} {
		#putlog "appending - modes to smodes: $modes(-)"
		lappend smodes -[join $modes(-) ""]
	}
	return [join $smodes ""]
}

# converts a modestring into a modelist (eg. "+ack-bl key" => {{+a} {-b} {+c} {+k key} {-l}})
proc splitmodes {mstr} {
	set key ""; set limit ""; set pre +; set result [list]
	set modes [lindex [split $mstr] 0]
	set params [lrange $mstr 1 end]
	foreach chr [split $modes ""] {
		if {$chr == "+"} { set pre +; continue }
		if {$chr == "-"} { set pre -; continue };
		if {$chr == "k" && $pre == "+" && [lrange $params 0 0] != ""} {
			lappend result "$pre$chr [lrange $params 0 0]"; set params [lrange $params 1 end]; continue 
			} elseif {$chr == "l" && $pre == "+" && [lrange $params 0 0] != ""} {
			lappend result "$pre$chr [lrange $params 0 0]"; set params [lrange $params 1 end]; continue
		} elseif {$chr == "b" && [lrange $params 0 0] != ""} {
			lappend result "$pre$chr [lrange $params 0 0]"; set params [lrange $params 1 end]; continue
		} elseif {$chr == "o" && [lrange $params 0 0] != ""} {
			lappend result "$pre$chr [lrange $params 0 0]"; set params [lrange $params 1 end]; continue
		} elseif {$chr == "v" && [lrange $params 0 0] != ""} {
			lappend result "$pre$chr [lrange $params 0 0]"; set params [lrange $params 1 end]; continue
		}
		if {![regexp {k|l|b|o|v} $chr]} {
			lappend result "$pre$chr"; continue 
		} elseif {[regexp {k|l} $chr] && $pre == "-"} {
			lappend result "$pre$chr"; continue
		}
	}
	return $result
}

# converts a modelist into a modestring (eg. {{+a} {-b} {+c} {+k key} {-l}} => "+ack-bl key")
proc joinmodes {mlist} {
	array set modes { {+} {} {-} {} }
	set params [list]
	foreach mode $mlist {
		regsub -all { } $mode "" mode
		set pre [string range $mode 0 0]
		set mode [string range $mode 1 1]
		set param [string range $mode 2 end]
		if {$mode == "k" && $pre == "+" && $param != ""} {
			lappend modes($pre) $mode; lappend params $param; continue
		} elseif {$mode == "l" && $pre == "+" && $param != "" && [string is integer $param]} {
			lappend modes($pre) $mode; lappend params $param; continue
		} elseif {$mode == "b" && $param != "" && [regexp {.*\!.*\@.*} $param]} {
			lappend modes($pre) $mode; lappend params $param; continue
		} elseif {$mode == "o" && $param != ""} {
			lappend modes($pre) $mode; lappend params $param; continue
		} elseif {$mode == "v" && $param != ""} {
			lappend modes($pre) $mode; lappend params $param; continue
		} elseif {![regexp {k|l|b|o|v} $mode]} {
			lappend modes($pre) "$mode"
		}
	}
	return "+[join $modes(+)]-[join $modes(-)] [join $params " "]"
}
# changes a modestring depending on the second modestring
# (zB "+nkt-m key" "-k+m" => "+ntm-k")

proc changemodes {oldmodes newmodes} {
	set oldmodes [splitmodes $oldmodes]
	set newmodes [splitmodes $newmodes]
	foreach md $newmodes {
		foreach {md2 param} [split $md] break
		foreach {pre mode} [split $md2 ""] break
		if {$pre == "+"} { set remove "-" }
		if {$pre == "-"} { set remove "+" }
		# delete the old
		if {[set pos [lsearch -glob $oldmodes "$remove$mode*"]] != -1} {
			set oldmodes [lreplace $oldmodes $pos $pos]
		}
		# add the new
		if {$param == ""} { lappend oldmodes $pre$mode } { lappend oldmodes "$pre$mode $param" }
	}
	return [joinmodes $oldmodes]
}
	
proc enforcedmode {channel mode} {
	if {[channel get $channel service_enforcedmodes] == ""} { return }
	foreach e [channel get $channel service_enforcedmodes] {
		if {$e == ""} { continue }
		if {[lindex [split $e] 0] == $mode} {
			return "$mode [expr {[lrange $e 1 end] != "" ? "[lrange $e 1 end]" : ""}]"
		}
	}
	return
}

proc onraw_mode {from raw arg {lookup 0}} {
	variable homechan; global botnick botname server
	set nickname [string trimleft [lindex [split $from !] 0] :]
	set hostname [string trimleft [lindex [split $from !] 1] ~]
	set channel [string trimleft [lindex [split $arg] 0] :]
	set service [channel get $channel service_servicebot]
	if {![validchan $channel] || [isbotnick $nickname] || [channel get $channel service_startup]} { return 0 }
	if {$service ne "" && [string equal -nocase $service $nickname]} { return 0 }
	if {![channel get $channel service_bitchmode] && (![channel get $channel service_enforcemodes] || [channel get $channel service_enforcedmodes] eq "+- ") && ![channel get $channel service_prot]} { return 0 }
	if {[string equal -nocase [lindex [split $server :] 0] $hostname] && $nickname == ""} { return 0 }
	if {$hostname eq "" && [string match -nocase $nickname [lindex [split $server :] 0]]} { return 0 }
	#set authname [service authname nick2auth $nickname]
	set handle [nick2hand $nickname]
	##putlog "onraw_mode: $nickname @ $channel = a:$authname / h:$handle / l:$lookup"
	#if {$handle == "*" && $authname == "" && $lookup == 0} {
		##putlog "onraw_mode: Performing auth lookup for $nickname @ $channel"
	#	if {[set op [isop $nickname $channel]]} {
	#		putquick "MODE $channel -o $nickname" -next
	#	}
	#	if {[llength [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] <= 0} {
	#		set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],1) "$op MODE $arg"
	#		putquick "WHO $nickname n%nuhat,139" -next; return
	#	} else {
	#		set id [expr {[lindex [split [lindex [split [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] end] ,] end] + 1}]
	#		set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],$id) "$op MODE $arg"
	#		return
	#	}
	#} elseif {$lookup == 2} {
	#	set reop 1
	#} else {
	#	set reop 0
	#}
	set reop 0
	##putlog "onraw_mode: $nickname @ $channel reop = $reop"
	#if {$authname != "" && [validuser $authname] && [getuser $authname xtra isauth] eq 1} { set handle $authname }
	set flags [expr {[channel get $channel service_prot_hard] ? "ADnNS|nmS" : "ADnNS|nmoS"}]
	set known [matchattr $handle $flags $channel]
	set bitchmode [channel get $channel service_bitchmode]
	set modes [lindex [split $arg] 1]
	set params [lrange $arg 2 end]
	set pre "+"
	set sorted [list]
	set domode [list]
	set noparams [list C c d D s t T r p u n N m M i]
	set punish 0
	##putlog "modes => $modes"
	##putlog "params => $params"
	for {set i 0} {$i<[string length $modes]} {incr i} {
		set chr [string index $modes $i]
		putlog "chr => $chr"
		if {$chr eq ""} { continue }
		if {$chr eq "+"} {
			##putlog "pre + / npre -"
			set pre "+"; set npre "-"; continue
		} elseif {$chr eq "-"} {
			##putlog "pre - / npre +"
			set pre "-"; set npre "+"; continue
		}
		lappend sorted "${pre}${chr}"
		##putlog "Got mode ${pre}${chr} by [expr {$known eq 1 ? "Known user" : ""}] $nickname @ $channel"
		if {$chr eq "d"} { continue }; # d can only be (un)set by the server, so ignore it
		if {[lsearch -exact $noparams $chr] ne -1} {
			## C c D s t T r p u n N m M i
			if {[channel get $channel service_enforcemodes] && ($pre eq "-" && [string match *$chr* [lindex [split [channel get $channel service_enforcedmodes] -] 0]]) || ($pre eq "+" && [string match *$chr* [lindex [split [lindex [split [channel get $channel service_enforcedmodes]] 0] -] 1]])} {
				lappend domode "${npre}${chr}"
			}
			if {$known} { continue }
			lappend domode "${npre}${chr}"
			set punish 1
			##putlog "punish 1 => $punish"
		} elseif {$chr eq "l"} {
			## l has to treated differently, as it has a param when set, but not when unset
			if {$pre eq "+"} {
				set param [lindex [split $params] 0]
				if {[channel get $channel service_autolimit]} {
					set limit [channel get $channel service_limit]
					if {$limit eq 0} { set limit 10 }
					if {[expr {[llength [chanlist $channel]]-$param}] < 3 || [expr {[llength [chanlist $channel]]-$param}] > 3} {
						lappend domode "+l [set limit [expr {[llength [chanlist $channel]]+$limit}]]"; set params [lreplace $params 0 0]
						if {$known} { channel set $channel service_chanmode_limit $limit }
					}
				} elseif {[channel get $channel service_enforcemodes] && [string match *l* [lindex [split [channel get $channel service_enforcedmodes] -] 0]]} {
					set limit [lrange [split [channel get $channel service_enforcedmodes]] 1 end]
					if {[string index $limit 0] eq "l"} {
						set limit [string trimleft [lindex [split $limit] 0] l,]
					} else {
						set limit [string trimleft [lindex [split $limit] 1] l,]
					}
					if {$limit ne $param} {
						lappend domode "+l $limit"; set params [lreplace $params 0 0]
						if {$known} { channel set $channel service_chanmode_limit $limit }
					}						
				} else {
					# +l has a param, pop it from the params list
					if {[channel get $channel service_enforcemodes] && [string match *l* [lindex [split [lindex [split [channel get $channel service_enforcedmodes]] 0] -] 1]]} {
						# -l enforced, do not +l
						set params [lreplace $params 0 0]
					} else {
						lappend domode "${npre}${chr}"
						set params [lreplace $params 0 0]
					}
				}
			} else {
				# -l does not have a param, lets calculate a new +10 limit
				# C c D s t T r p u n N m M i l k
				if {[channel get $channel service_autolimit]} {
					if {[set x [channel get $channel service_limit]] <= 0} { channel set $channel service_limit [set x 10] }
					set limit [expr {[llength [chanlist $channel]] + $x}]
				} elseif {[channel get $channel service_enforcemodes] && [string match *l* [lindex [split [channel get $channel service_enforcedmodes] -] 0]]} {
					set limit [lrange [split [channel get $channel service_enforcedmodes]] 1 end]
					if {[string index $limit 0] eq "l"} {
						set limit [string trimleft [lindex [split $limit] 0] l,]
					} else {
						set limit [string trimleft [lindex [split $limit] 1] l,]
					}						
				} elseif {[set limit [channel get $channel service_chanmode_limit]]<=0} {
					set limit [expr {[llength [chanlist $channel]]+10}]
				}
				if {[channel get $channel service_enforcemodes] && [string match *l* [lindex [split [lindex [split [channel get $channel service_enforcedmodes]] 0] -] 1]]} {
					# -l enforced, do not +l
				} else {
					lappend domode "${npre}${chr} $limit"
				}
			}
			if {$known} { continue }
			set punish 1
			#putlog "punish 2 => $punish"
		} elseif {$chr eq "k" && [channel get $channel service_enforcemodes]} {
			set param [lindex [split $params] 0]
			if {$pre eq "+" && [string match *k* [lindex [split [lindex [split [channel get $channel service_enforcedmodes]] 0] -] 1]]} {
				# -k enforced
				lappend domode "${npre}${chr} $param"; set params [lreplace $params 0 0]
			} elseif {$pre eq "+" && [string match *k* [lindex [split [channel get $channel service_enforcedmodes] -] 0]]} {
				# +k enforced, +k set, check the key matches our enforced key
				set key [lrange [split [channel get $channel service_enforcedmodes]] 1 end]
				if {[string index $key 0] eq "k"} {
					set key [string trimleft [lindex [split $key] 0] k,]
				} else {
					set key [string trimleft [lindex [split $key] 1] k,]
				}
				if {![string equal $param $key]} {
					# keys dont match
					lappend domode "-k $param"; lappend domode "+k $key"; set params [lreplace $params 0 0]
				}
			} elseif {$pre eq "-" && [string match *k* [lindex [split [channel get $channel service_enforcedmodes] -] 0]]} {
				# +k enforced
				set key [lrange [split [channel get $channel service_enforcedmodes]] 1 end]
				if {[string index $key 0] eq "k"} {
					set key [string trimleft [lindex [split $key] 0] k,]
				} else {
					set key [string trimleft [lindex [split $key] 1] k,]
				}
				lappend domode "${npre}${chr} $key"; set params [lreplace $params 0 0]
			}
			if {$known} { continue }
			set punish 1
		} else {
			set param [lindex [split $params] 0]; set params [lreplace $params 0 0]
			if {($pre eq "-" && $chr == "o" && [isbotnick $param])} {
				if {$known} {
					putquick "PRIVMSG $service :OP $channel" -next
				} else {
					putquick "PRIVMSG $service :RECOVER $channel" -next
					putquick "PRIVMSG $service :OP $channel" -next
					set punish 1
				}
				#putlog "punish 3 => $punish"
			} elseif {($pre eq "+" && $chr == "b" && ([string match -nocase "$param" "$botname"] || [string match -nocase "*[lindex [split $botname @] 1]*" "*$param*"]))} {
				if {$known} {
					putquick "PRIVMSG $service :UNBANME $channel" -next
				} else {
					putquick "PRIVMSG $service :RECOVER $channel" -next
					putquick "PRIVMSG $service :UNBANME $channel" -next
					set punish 1
				}
				#putlog "punish 4 => $punish"
			} elseif {($chr eq "o" || $chr eq "v") && [string equal -nocase $nickname $param]} {
				if {$pre eq "+" && $chr eq "v" && $bitchmode && ![matchattr [nick2hand $param] ADnmovfS|nmovfS $channel]} {
					# bitchmode enabled and user does not having matching flags, reverse the mode without punishment
					lappend domode "${npre}${chr} $param"
				}
				# let users deop and (de)voice themselves without punishment
				continue
			} elseif {$pre eq "+" && $chr eq "b" && [string match -nocase "$param" "${nickname}!${hostname}"]} {
				if {![widebanmask $param]} {
					# remove self bans without punishment
					lappend domode "${npre}${chr} $param"
				} else {
					lappend domode "${npre}${chr} $param"
					set punish 1
				}
				#putlog "punish 5 => $punish"
			} else {
				if {$known && $bitchmode && $pre eq "+"} {
					if {$chr eq "o" && ![matchattr [nick2hand $param] ADnS|nmoS $channel]} {
						lappend domode "${npre}${chr} $param"
					} elseif {$chr eq "v" && ![matchattr [nick2hand $param] ADnmovfS|nmovfS $channel]} {
						lappend domode "${npre}${chr} $param"
					}
				}
				if {$known} { continue }
				if {$pre eq "-" && $bitchmode} {
					if {($chr eq "o" && [matchattr [nick2hand $param] ADnS|nmoS $channel]) || ($chr eq "v" && [matchattr [nick2hand $param] ADnmovfS|nmovfS $channel])} {
						# bitchmode enabled, victim has matching flags so reop/voice
						lappend domode "${npre}${chr} $param"; set punish 1; continue
					} else {
						# bitchmode enabled, do not reop/voice victims without matching flags
						set punish 1; continue
					}
				} else {
					lappend domode "${npre}${chr} $param"; set punish 1
				}
				#putlog "punish 6 => $punish"
			}
		}
	}
	#putlog "punish? $punish"
	if {$known} { set punish 0 }
	if {$punish eq 1 && [channel get $channel service_prot]} {
		set ban 1
		if {[string match -nocase *users.quakenet.org [set hostname *!*$hostname]]} {
			set hostname *!*@[lindex [split $hostname @] 1]
		}
		if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { set ban 0 }
		if {$ban && ![validbanmask $hostname]} { set ban 0 }
		if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
			channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
		}
		channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
		set map [list]
		lappend map ":violate: \{change channel modes ([sortmodes $sorted])\}"
		lappend map ":channel: $channel"
		lappend map ":id: $id"
		lappend map ":homechan: $homechan"
		set kmsg [string map [join $map] $kmsg]
		if {[botisop $channel]} {
			if {[onchan $nickname $channel]} {
				if {$ban} {
					putquick "MODE $channel -o+b $nickname $hostname" -next
				} else {
					putquick "MODE $channel -o $nickname" -next
				}
				putquick "KICK $channel $nickname :$kmsg" -next
			}
		}
		newchanban $channel $hostname $botnick "$kmsg" 120
	} elseif {$reop} {
		if {[botisop $channel] && [onchan $nickname $channel] && ![isop $nickname $channel]} {
			lappend domode "+o $nickname"
			#putquick "MODE $channel +o $nickname"
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
				putquick "MODE $channel [join $modes ""] [join $params " "]" -next
				set modes [list]; set params [list]
			}
		}
		if {[llength $modes]>0} {
			putquick "MODE $channel [join $modes ""] [join $params " "]" -next
			set modes [list]; set params [list]
		}
	}
}