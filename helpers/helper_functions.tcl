proc helper_loadini_cmd {file} {
	global botnick altnick
	variable cmdlist; variable cmdhelp; variable script
	array unset cmdlist; array set cmdlist {}
	array unset cmdhelp; array set cmdhelp {}
	if {[catch {set ini [::ini::open $file r]} err]} {
		putlog "${script}: Error loading commands ini file => ${file}:"
		foreach l [split $err \n] {
			if {$l == ""} { continue }
			putlog "$l"
		}
		putlog "End of commands ini error."
	} else {
		#foreach section [::ini::sections $ini] {
		#	if {$section == ""} { continue }
		#	foreach key [ini::keys $ini $section] {
		#		if {$key == ""} { continue }
		#		set section [string tolower $section]
		#		set key [string tolower $key]
		#		if {[catch {set value [::ini::value $ini $section $key]} err]} {
		#			continue
		#		} else {
		#			set cmdhelp($section,$key) $value
		#		}
		#	}
		#}
		set map [list]
		lappend map "%botnick% $botnick"
		lappend map "%altnick% $altnick"
		foreach section [::ini::sections $ini] {
			if {$section == ""} { continue }
			foreach {key value} [::ini::get $ini $section] {
				if {$key == ""} { continue }
				if {[string equal -nocase "type" $key] && [string equal -nocase "channel" $value]} { set value "chan" }
				if {[string equal -nocase "flags" $key] && $value == ""} { set value "|" }
				if {$value == ""} { continue }
				set cmdhelp($section,$key) [join [string map [join $map] $value]]
			}
			helper_reg_cmd $section $cmdhelp($section,type) $cmdhelp($section,flags)
		}
		::ini::close $ini
		putlog "${script}: Successfully loaded commands ini file => $file"
	}
}

proc helper_reg_cmd {command type flags} {
	variable cmdlist; variable cmdhelp
	set type [string tolower $type]
	if {$type != "global" && $type != "channel" && $type != "chan"} { return -1 }
	if {$flags == ""} { return -2 }
	set command [string tolower $command]
	if {[llength [array names cmdlist *:$command]] <= 0} {
		set cmdlist(${type}:${command}) "$flags"
		return 1
	}
	return 0
}

proc helper_unreg_cmd {command type} {
	variable cmdlist; variable cmdhelp
	set type [string tolower $type]
	if {$type != "global" && $type != "channel"} { return -1 }
	set command [string tolower $command]
	if {[info exists cmdlist(${type}:${command})]} {
		unset cmdlist(${type}:${command})
		return 1
	}
	return 0
}

proc helper_help_cmd_tonick {command nickname} {
	variable cmdlist; variable cmdhelp; variable trigger
	if {[set handle [nick2hand $nickname]] == "" || $handle == "*"} { set trig $trigger }
	if {![info exists trig] && [set trig [getuser $handle XTRA mytrigger]] == ""} {
		setuser $handle XTRA mytrigger $trigger; set trig $trigger
	}
	set command [string tolower $command]
	if {[llength [array names cmdlist *:$command]] <= 0} { return 0 }
	if {[llength [array names cmdhelp $command,*]] <= 0} { return 0 }
	if {[info exists cmdhelp($command,syntax)]} {
		set map [list]; lappend map ":trigger: $trig"
		putserv "NOTICE $nickname :SYNTAX: [string map [join $map] $cmdhelp($command,syntax)]"
	}
	if {[string equal -nocase "deprecated" $cmdhelp($command,status)]} {
		set map [list]; lappend map ":trigger: $trig"
		putserv "NOTICE $nickname :DEPRECATED: [string map [join $map] $cmdhelp($command,description)]"
		return
	}
	if {[info exists cmdhelp($command,description)]} {
		if {[llength [split [set description $cmdhelp($command,description)] %%]] > 1} {
			set i 0
			foreach line [split $description %%] {
				if {$line == ""} { continue }
				set map [list]; lappend map ":trigger: $trig"; set line [string map [join $map] $line]
				if {$i == 0} {
					putserv "NOTICE $nickname :DESCRIPTION: $line"; set i 1
				} else {
					putserv "NOTICE $nickname :$line"
				}
			}; unset i
		} else {
			set map [list]; lappend map ":trigger: $trig"
			putserv "NOTICE $nickname :DESCRIPTION: [string map [join $map] $description]"
		}
	}
	if {[info exists cmdhelp($command,options)]} {
		if {[llength [split [set options $cmdhelp($command,options)] %%]] > 1} {
			set i 0
			foreach line [split $options %%] {
				if {$line == ""} { continue }
				set map [list]; lappend map ":trigger: $trig"; set line [string map [join $map] $line]
				if {$i == 0} {
					putserv "NOTICE $nickname :OPTIONS: $line"; set i 1
				} else {
					putserv "NOTICE $nickname :$line"
				}
			}; unset i
		} else {
			set map [list]; lappend map ":trigger: $trig"
			putserv "NOTICE $nickname :OPTIONS: [string map [join $map] $options]"
		}
	}
	return 1
}

proc helper_list_globalcmds_byhandle {handle} {
	variable cmdlist
	if {![validuser $handle]} { return [list] }
	set cmds [list]
	foreach {cmd flag} [array get cmdlist global:*] {
		if {[matchattr $handle $flag]} {
			lappend cmds [lindex [split $cmd :] 1]
		}
	}
	return [lsort [join $cmds " "]]
}

proc helper_list_channelcmds_byhandle {channel handle} {
	variable cmdlist
	if {![validchan $channel] || ![validuser $handle]} { return [list] }
	set cmds [list]
	foreach {cmd flag} [array get cmdlist chan:*] {
		if {$cmd == ""} { continue }
		if {[matchattr $handle $flag $channel]} {
			lappend cmds [lindex [split $cmd :] 1]
		}
	}
	return [lsort [join $cmds " "]]
}		

proc helper_xtra_set {what handle arg} {
	if {![validuser $handle]} { return }
	if {![string is integer [getuser $handle XTRA cmdcount]]} { setuser $handle XTRA cmdcount 0 }
	if {$what == "lastcmd"} {
		setuser $handle XTRA lastcmd "$arg"
		setuser $handle XTRA lastcmdset [clock seconds]
		setuser $handle XTRA cmdcount [expr {[getuser $handle XTRA cmdcount]+1}]
	}
}