namespace eval service {

	# USE /WHO AUTHNAME a%nuha for authname matching?
		
	variable start [clock clicks]
	
	variable script [lindex [split [info script] /] end]
	variable version "5.0.1.0 AUTH-MODULAR-GIT-BETA"
	variable author "r0t3n aka Eagle \( #r0t3n \)"    
	variable copyright "$script - v${version} - $author"
	
	variable cmdinifile "[pwd]/scripts/service/commands.ini"
	
	if {[catch {package require inifile 0.2.3} err]} {
		putlog "${script}: Error loading inifile package."
	} else {
		putlog "${script}: Successfully loaded inifile package."
	}
	
	# from http://wiki.tcl.tk/1474
	proc globr {{dir .} args} {
		set res {}
		foreach i [lsort [glob -nocomplain -dir $dir *]] {
			if {[file isdirectory $i]} {
				eval [list lappend res] [eval [linsert $args 0 globr $i]]
			} else {
				if {[llength $args]} {
					foreach arg $args {
						if {[string match $arg $i]} {
							lappend res $i
							break
						}
					}
				} else {
					lappend res $i
				}
			}
		}
		return $res
	}
	
	proc loadedmodules {} {
		set loaded [list]
		set modules [globr scripts/service/modules/ *.module]
		foreach module $modules {
			if {$module eq ""} { continue }
			set module [lindex [split [file tail $module] .] 0]
			if {[ismodule $module]} {
				lappend loaded $module
			}
		}
		return $loaded
	}
	
	proc availablemodules {} {
		set mods [list]
		set modules [globr scripts/service/modules/ *.module]
		foreach module $modules {
			if {$module eq ""} { continue }
			lappend mods [lindex [split [file tail $module] .] 0]
		}
		return $mods
	}		
	
	proc loadmodules {} {
		set modules [globr scripts/service/modules/ *.module]
		if {[llength $modules] <= 0} {
			putlog "No service modules detected"; return
		} else {
			putlog "Detected [llength $modules] module(s): [join $modules ", "]"
			foreach module $modules {
				if {$module eq ""} { continue }
				set name [lindex [split [file tail $module] .] 0]
				putlog "Attempting to load '$name' module (Path: $module):"
				if {[catch {source $module} err]} {
					putlog "Error loading module '$name' (Path: $module):"
					foreach li $err {
						putlog "${name} error: $li"
					}
					putlog "${name} end of error."
				} else {
					putlog "${name} module successfully loaded."
				}
			}
		}
		namespace ensemble create
	}
	
	proc loadmodule {module} {
		set module [string tolower $module]
		if {[string match "*/*" $module]} {
			if {![file exists $module]} {
				set name [lindex [split [file tail $module] .] 0]
				putlog "Path does not exist: $path"; return -1
			} elseif {[ismodule $name]} {
				# reload module
				unloadmodule $name
				loadmodule $module
			} else {
				if {[catch {source $module} err]} {
					putlog "Error loading module '$name' (Path: $module):"
					foreach li $err {
						putlog "${name} error: $li"
					}
					putlog "${name} end of error."; return 0
				} else {
					putlog "${name} module successfully loaded."; return 1
				}
			}
		} else {
			# is a name
			if {![file exists [set path scripts/service/modules/${module}/${module}.module]]} {
				putlog "${module} can not find module path: $path"; return -1
			} elseif {[ismodule $module]} {
				# reload module
				unloadmodule $module
				loadmodule $module
			} else {
				if {[catch {source $path} err]} {
					putlog "Error loading module '$module' (Path: $path):"
					foreach li $err {
						putlog "${module} error: $li"
					}
					putlog "${module} end of error."; return 0
				} else {
					putlog "${module} module successfully loaded."; return 1
				}
			}
		}
		namespace ensemble create
		return -2
	}		
	
	proc unloadmodule {module} {
		set module [string tolower $module]
		if {[namespace exists $module]} {
			catch {${module}::__unload__}
			namespace delete $module
			return 1
		} else {
			return 0
		}
	}
	
	proc ismodule {module} {
		set module [string tolower $module]
		return [namespace exists $module]
	}
		
	array set networkservices {
		{Q} {chanserv}
		{S} {spamscan}
		{P} {proxyscan}
		{U} {gamebot}
		{H} {helpbot}
		{T} {trojanscan}
		{WOWBOT} {gameserv}
		{SNAILBOT} {gameserv}
		{CATBOT} {gameserv}
		{FISHBOT} {gameserv}
	}
	
	array set cmdlist {}
	array set cmdhelp {}
	
	variable configpath [string map { {.tcl} {} } [info script]]
	putlog "confilepath: $configpath"
	variable configfile "${configpath}.conf"
	putlog "configfile: ${configpath}.conf"
	set r [catch {source $configfile} error]
	
	if {!$r || $error == ""} { 
		putlog "Service.tcl - $version - Loaded '$configfile' as configuration file - errors: (none)"
		variable loaded "1"
	} else { 
		putlog "Service.tcl - $version - Couldn't load '$configfile' as a configuration file - error: $error"
		die "Service.tcl - $version - Couldn't load '$configfile' as a configuration file - error: $error"
	}	
	
	set file [open [info script] r]
	variable linecount [llength [split [read -nonewline $file] \n]]
	close $file
	
	bind evnt - {*} [namespace current]::onevnt
	
	bind pubm - {*} [namespace current]::onpubm
	#bind msg nm {rejoin} [namespace current]::onmsg onmsg_rejoin
	
	bind join - {*} [namespace current]::onjoin
	bind part - {*} [namespace current]::onpart
	bind sign - {*} [namespace current]::onquit
	bind splt - {*} [namespace current]::onsplt
	bind rejn - {*} [namespace current]::onrejn
	
	foreach raw [list MODE KICK TOPIC NICK INVITE 315] {
		bind raw - $raw [namespace current]::onraw
	}
	
	bind need - {*} [namespace current]::onneed
	bind flud - {*} [namespace current]::onflud
	
	bind time - {?0 * * * *} [namespace current]::autosave
	bind time - {?5 * * * *} [namespace current]::autosave
	
	bind time - {* * * * *} [namespace current]::automsg

	# The main flag, if this flag is not set, the whole script won't work
	setudef flag service

	setudef flag service_prot; # The protection flag
	setudef flag service_prot_hard; # The hard protection flag
	setudef flag service_spamscan; # The spamscan flag
	setudef flag service_flood; # The antiflood flag
	setudef flag service_flyby; # The flyby flag
	setudef flag service_ao; # The auto-op flag
	setudef flag service_av; # The auto-voice flag
	setudef flag service_autolimit; # The auto-limit flag
	setudef flag service_authban; # The authbans flag
	setudef flag service_badchan; # The badchannel flag
	setudef flag service_vip; # The vip flag
	setudef flag service_vips; # The show vip skin flag
	setudef flag service_vipn; # The notice vip skin flag
	setudef flag service_vip_authed; # The vip authed only flag
	setudef flag service_vip_authbl; # the vip auth blacklist flag
	setudef flag service_vip_chanmode; # the vip show vip channel status flag
	setudef flag service_vip_dynamicmode; # turns vip mode dynamic, user is given the highest status found from vipchannels
	setudef flag service_clonescan; # The onjoin clonescan flag
	setudef flag service_known; # The known-only flag
	setudef flag service_bitchmode; # The bitchmode flag
	setudef flag service_badword; # The badwords flag
	setudef flag service_welcome; # The welcome/greet flag
	setudef flag service_welcome_notice; # The welcome notice flag
	setudef flag service_startup; # The startup flag
	
	setudef flag service_topic_save
	setudef flag service_topic_force
	setudef flag service_topic_Q
	setudef str service_topic_skin
	setudef str service_topic_current
	setudef str service_topic_map

	setudef str service_badwords
	setudef str service_badword_kickmsg
	setudef int service_badword_bantime
	setudef int service_badword_bwkid
	setudef int service_badword_bwid
	
	
	setudef flag service_peak
	setudef int service_peak_count
	setudef int service_peak_time
	setudef str service_peak_nick
	
	setudef flag service_automsg
	setudef flag service_automsg_moderate
	setudef int service_automsg_last
	setudef int service_automsg_counter
	setudef int service_automsg_interval
	setudef str service_automsg_method
	setudef str service_automsg_messages
	setudef str service_automsg_maps
	
	# keep for backwards compatibility -- remove in the near future
	setudef str service_automsg_line1
	setudef str service_automsg_line2
	setudef str service_automsg_line3

	setudef flag service_key

	setudef flag service_enforcemodes
	setudef str service_enforcedmodes

	setudef flag service_netsplit
	setudef str service_netsplit_time

	setudef str service_servicebot
	setudef str service_chanmode_limit
	setudef str service_chanmode_key
	setudef str service_chanmode_key
	setudef str service_kickmsg_kick
	setudef str service_kickmsg_ban
	setudef str service_kickmsg_protkick
	setudef str service_kickmsg_userkick
	setudef str service_kickmsg_userban
	setudef str service_kickmsg_gban
	setudef str service_kickmsg_badchan
	setudef str service_kickmsg_authban
	setudef str service_kickmsg_defaultban
	setudef str service_kickmsg_spamkick
	setudef str service_kickmsg_spamban
	setudef str service_kickmsg_known
	setudef str service_vipskin; # The vipskin string which holds the vip skin
	setudef str service_vipm; # The vipmode string which holds the vip mode
	setudef str service_vipc; # The vipc chanflag which holds the vip channels
	setudef str service_vip_authblist; # the vip auth blacklist str which holds the blacklist authnames
	setudef str service_bantime_flood; # The antiflood bantime
	setudef str service_clonescan_bantime
	setudef str service_clonescan_maxclones
	setudef str service_clonescan_hosttype
	setudef str service_flood_massjoin
	setudef str service_badchans
	setudef str service_authbans
	setudef str service_welcome_skin

	setudef int service_kid
	setudef int service_kid_known
	setudef int service_gkid
	setudef int service_sid
	setudef int service_limit
	setudef int service_vipid; # The vipid integer which holds the current vip id
	setudef int service_stype; # The spamscan_type integer which holds the spamscan excempt type
	setudef int service_bid
	setudef int service_aid
	setudef int service_jid

	setudef int service_userid

	proc onevnt {type} {
		switch -exact -- $type {
			"init-server" {
				putquick "SBNC :partall" -next
				foreach channel [channels] {
					channel set $channel +service_startup
				}
			}
			"pre-rehash" {
				foreach bind [binds *[namespace current]*] {
					if {$bind == ""} { continue }
					catch {unbind [lindex $bind 0] [lindex $bind 1] [lindex $bind 2] [lindex $bind 4]}
				}
				namespace delete [namespace current]
				save
			}
			"default" {
				return 0
			}
		}
		return 0
	}

	proc isnetworkservice {arg} {
		variable networkservices
		return [info exists networkservices([string toupper $arg])]
	}

	proc ischannelservice {arg} {
		variable networkservices
		if {[info exists networkservices([set arg [string toupper $arg]])]} {
			if {$networkservices($arg) == "chanserv"} {
				return 1
			}
		}
		return 0
	}

	proc getnetworkservice {channel {type "chanserv"}} {
		variable networkservices
		if {![validchan $channel]} { return }
		foreach {service typ} [array get networkservices] {
			if {$service == "" || $typ == ""} { continue }
			if {[string equal -nocase $type $typ]} {
				if {[onchan $service $channel]} {
					return $service
				}
			}
		}
		return
	}
	
	proc getnetworkservices {channel} {
		variable networkservices
		if {![validchan $channel]} { return }
		set services [list]
		foreach service [array names networkservices] {
			if {$service == ""} { continue }
			if {[onchan $service $channel]} {
				lappend services $service
			}
		}
		return $services
	}

	proc autosave {minute hour day month year} {
		variable script
		putlog "\[ $script - auto \] - Performing autosave..."
		save
	}

	foreach channel [channels] {
		if {[botonchan $channel]} {
			if {[set tmp [getnetworkservice $channel "chanserv"]] != ""} {
				channel set $channel service_servicebot $tmp
			}
		}
		foreach ban [list *!*@ *!*@* *!**@ *!**@* *@*] {
			catch {killchanban $channel $ban}
			pushmode $channel -b $ban
		}
		flushmode $channel
	}

	
	#rename newban anewban
	#proc newban {ban creator comment {lifetime "60"} {options "none"}} { 
	#	if {$ban == "*!*@" || $ban == "*!*@*" || $ban == "*!**@*" || $ban == "*!**@"} { 
	#		putlog "newban: (bad banmask: $ban) - $ban $creator '$comment' [expr {[info exists lifetime] ? "$lifetime" : ""}] [expr {[info exists options] ? "$options" : ""}]"
	#	} else { 
	#		anewban $ban $creator $comment $lifetime $options
	#	} 
	#}


	#rename newchanban anewchanban
	#proc newchanban {channel ban creator comment {lifetime "60"} {options "none"}} { 
	#	if {$ban == "*!*@" || $ban == "*!*@*" || $ban == "*!**@*" || $ban == "*!**@"} { 
	#		putlog "newchanban: (bad banmask: $ban) - $channel $ban $creator '$comment' [expr {[info exists lifetime] ? "$lifetime" : ""}] [expr {[info exists options] ? "$options" : ""}]"
	#	} else { 
	#		anewchanban $channel $ban $creator $comment $lifetime $options
	#	} 
	#}

	foreach user [userlist] {
		if {$user == ""} { return }
		if {[getuser $user XTRA mytrigger] == ""} {
			setuser $user XTRA mytrigger "$trigger"
			setuser $user XTRA mytriggerset "[clock seconds]"
		}
		if {[getuser $user XTRA mytriggerset] == ""} { 
			setuser $user XTRA mytriggerset "[clock seconds]"
		}
		if {[getuser $user XTRA userid] == ""} {
			channel set $adminchan service_userid "[set userid [expr {[channel get $adminchan service_userid]+1}]]"
			setuser $user XTRA userid "$userid"
		}
		if {[getuser $user XTRA loggedin] == ""} {
			setuser $user XTRA loggedin 0
		}
		if {[getuser $user XTRA lasthost] == ""} {
			setuser $user XTRA lasthost "N/A"
		}
		if {[getuser $user XTRA email] == ""} {
			setuser $user XTRA email "N/A"
		}
		if {[getuser $user XTRA cmdcount] == ""} {
			setuser $user XTRA cmdcount 0
		}
		if {[getuser $user XTRA lastcmd] == ""} {
			setuser $user XTRA lastcmd "N/A"
		}
	}

	proc putservlog {text} {
		global botnick
		if {![file isdir [file join [pwd]/logs/service $botnick]]} {
			file mkdir -force [file join [pwd]/logs/service $::botnick]
		}
		set file [open [file join [pwd]/logs/service $::botnick [clock format [unixtime] -format %d%m%y].log] a]
		puts $file "\[[clock format [unixtime] -format %H:%M:%S]\] $text"
		close $file
	}
	
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
		if {$what == "lastcmd"} {
			setuser $handle XTRA lastcmd "$arg"
			setuser $handle XTRA lastcmdset "[clock seconds]"
			setuser $handle XTRA cmdcount "[expr {[getuser $handle XTRA cmdcount]+1}]"
		}
	}

	# The central proc, holds all the commands for all triggers

	proc onpubm {nickname hostname handle channel text {lastbind "pubm"}} {
		global botnick; variable triggers; variable kickmsg
		#if {$lastbind == ""} {
		#	set lastbind pubm
		#}
		if {$lastbind != "msgm" && [lsearch -exact "$triggers" [string index [set option [lindex [split $text] 0]] 0]] == "-1" && ![string match -nocase $botnick $option]} {
			if {[channel get $channel service_badword] && [set words [string tolower [channel get $channel service_badwords]]] != "" && ![matchattr $handle nm|nmo $channel]} {
				set list [list]
				foreach word [string tolower $text] {
					if {$word == ""} { continue }
					if {[lsearch -exact $words $word] != -1} {
						lappend list $word
						putlog "detected badword $word from $nickname on $channel"
					}
				}
				if {[llength $list]<=0} { return }
				if {[set kmsg [channel get $channel service_badword_kickmsg]] == ""} {
					channel set $channel service_badword_kickmsg "[set kmsg $kickmsg(badword)]"
				}
				channel set $channel service_badword_bwkid "[set bwkid [expr {[channel get $channel service_badword_bwkid] + 1}]]"
				channel set $channel service_badword_bwid "[set bwid [expr {[channel get $channel service_badword_bwid] + [llength $list]}]]"
				if {![botisop $channel]} { return }
				regsub -all :nickname: $kmsg "$nickname" kmsg
				regsub -all :hostname: $kmsg "$hostname" kmsg
				regsub -all :badword: $kmsg "[join $list ", "]" kmsg
				regsub -all :found: $kmsg "[llength $list]" kmsg
				regsub -all :channel: $kmsg "$channel" kmsg
				regsub -all :id: $kmsg "$bwkid" kmsg
				regsub -all :bid: $kmsg "$bwid" kmsg
				if {[string match -nocase *users.quakenet.org [set banmask *!*[string trimleft $hostname ~]]]} {
					set banmask *!*@[lindex [split $hostname @] 1]
				}
				putserv "MODE $channel -o+b $nickname $banmask"
				putserv "KICK $channel $nickname :$kmsg"
				if {[set bantime [channel get $channel service_badword_bantime]] == "0"} {
					channel set $channel service_badword_bantime "[set bantime 1]"
				}
				utimer [expr {$bantime * 60}] [list pushmode $channel -b $banmask]
			}
			return 0
		} else {
			set cont 0
			if {$lastbind == "msgm"} {
				set lastbind "/msg $botnick "
				set command [lindex [split $text] 0]
				#set text [join [lrange $text 1 end]]
				set text [join [lreplace [split $text] 0 0]]
				set cont 1
			} elseif {[string match -nocase $botnick $option]} {
				set lastbind "$botnick "
				set command [lindex [split $text] 1]
				#set text [join [lrange $text 2 end]]
				set text [join [lreplace [split $text] 0 1]]
				set cont 1
			} else {
				set lastbind "[string index $option 0]"
				set command "[string range $option 1 end]"
				#set text [join [lrange [split $text] 1 end]]
				set text [join [lreplace [split $text] 0 0]]
				set mytrig [getuser $handle XTRA mytrigger]
				if {$lastbind == "$mytrig" || ($command == "mytrigger" || $command == "mytrig" || $command == "trig" || $command == "trigger")} {
					set cont 1
				}
			}
			if {!$cont} { return 0 }
			if {[getuser $handle XTRA cmdcount] == ""} { setuser $handle XTRA cmdcount "0" }
			switch -exact -- $command {
				"adduser" - "add" {
					variable global_user_levels; variable channel_user_levels; variable trigger; variable adminchan; variable kickmsg
					# SYNTAX: adduser nickname handle ?-global|#channel? <level>
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {[llength $text] < 3} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}${command} <nickname> <handle> ?-global|#channel? <level>."
						return
					}
					set who [lindex [split $text] 0]
					set hand [lindex [split $text] 1]
					set where [lindex [split $text] 2]
					set global 0
					if {[string index $where 0] == "#"} {
						if {![validchan $where]} {
							putserv "NOTICE $nickname :ERROR: Invalid channel '$channel' specified."; return
						} else {
							set level [string tolower [lindex [split $text] 3]]
						}
					} elseif {[string equal -nocase "-global" $where]} {
						set level [string tolower [lindex [split $text] 3]]
						if {![info exists global_user_levels($level)]} {
							putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names global_user_levels] ", "])"; return
						}
						set levels $global_user_levels($level)
						set global 1
					} else {
						set where $channel
						set level [string tolower [lindex [split $text] 2]]
					}
					if {!$global} {
						if {![info exists channel_user_levels($level)]} {
							putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names channel_user_levels] ", "])"; return
						} else {
							set levels $channel_user_levels($level)
						}
					}
					set mf [lindex [split $levels] 0]; # flags required
					set af [lindex [split $levels] 1]; # flags provided
					if {$global && ![matchattr $handle $mf]} {
						putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to add '$who' (#$hand) as 'global $level'."; return
					} elseif {![matchattr $handle $mf $where]} {
						putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to add '$who' (#$hand) as '$where $level'."; return
					}
					if {![onchan $who]} {
						putserv "NOTICE $nickname :ERROR: User '$who' is not on any of my channels."; return
					} elseif {[validuser [nick2hand $who]]} {
						putserv "NOTICE $nickname :ERROR: User '$who' is already added as '[nick2hand $who]' - please use the ACCESS command to further modify access."; return
					} elseif {[string length $hand] <= 2 && [string length $hand] > 9} {
						putserv "NOTICE $nickname :ERROR: Handle length must be between 2 to 9 characters long."; return
					} elseif {[getchanhost $who] == ""} {
						putserv "NOTICE $nickname :ERROR: Could not grab hostname for $who - carn't proceed."; return
					} else {
						if {[string match -nocase *users.quakenet.org [set host *!*[string trimleft [getchanhost $who] ~]]]} {
							set host *!*@[lindex [split $host @] 1]
						}
						adduser $hand $host
						if {$global} {
							chattr $hand $af
						} else {
							chattr $hand $af $where
						}
						setuser $hand XTRA mytrigger "$trigger"
						setuser $hand XTRA mytriggerset "[clock seconds]"
						channel set $adminchan service_userid "[set userid [expr {[channel get $adminchan service_userid]+1}]]"
						setuser $hand XTRA userid $userid
						setuser $hand XTRA email "N/A"
						setuser $hand XTRA loggedin 1
						setuser $hand XTRA lastlogin [clock seconds]
						setuser $hand XTRA lasthost "[string trimleft [getchanhost $who] ~]"
						setuser $hand XTRA cmdcount 0
						setuser $hand XTRA lastcmd "N/A"
						if {$global} {
							putserv "NOTICE $nickname :\002$who\002 ($hand) added as \002global $level\002."
							if {$level == "ban"} {
								set kmsg $kickmsg(gban)
								channel set $adminchan [set id [expr {[channel get $adminchan gkid] + 1}]]
								regsub -all :adminchan: $kmsg "$adminchan" kmsg
								regsub -all :id: $kmsg "$id" kmsg
								regsub -all :reason: $kmsg "Global Banned" kmsg
								newban $host $handle "$kmsg" 0
							} else {
								putserv "NOTICE $who :\002$nickname ($handle)\002 added you as \002global $level\002."
							}
						} else {
							putserv "NOTICE $nickname :\002$who\002 ($hand) added as \002$where $level\002."
							if {$level == "ban"} {
								newchanban $where $host $handle "$kickmsg(defaultban)" 0
							} else {
								putserv "NOTICE $who :\002$nickname ($handle)\002 added you as \002$where $level\002."
								if {![isop $who $where] && [botisop $where] && [matchattr $hand |nmo $where]} {
									pushmode $where +o $who
								} elseif {![isvoice $who $where] && [botisop $where] && [matchattr $hand |vf $where]} {
									pushmode $where +v $who
								}
							}
						}
						putserv "NOTICE $who :For security reasons, please type: /msg $::botnick password <password>. Your default mytrigger is set to: $trigger. To find out my commands, please type ${trigger}commands or $::botnick commands."
					}
				}
				"access" {
					# SYNTAX: %access <nickname|#handle> ?-global|#channel? ?level?
					variable global_user_levels; variable channel_user_levels
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {[llength $text] < 1} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command <nickname|#handle> ?-global|#channel? ?level?"
						return
					}
					set who [lindex [split $text] 0]
					set where [lindex [split $text] 1]
					set global 0
					
					if {[string index $who 0] == "#"} {
						if {![validuser [set hand [string trimleft $who #]]]} {
							putserv "NOTICE $nickname :ERROR: Handle '$hand' does not exist in my database."; return
						}
					} elseif {[set hand [nick2hand $who]] == "*"} {
						putserv "NOTICE $nickname :ERROR: Nickname '$who' does not match any of my users."; return
					}
					
					if {[string index $where 0] == "#"} {
						if {![validchan $where]} {
							putserv "NOTICE $nickname :ERROR: Invalid channel '$channel' specified."; return
						} else {
							set level [string tolower [lindex [split $text] 1]]
						}
					} elseif {[string equal -nocase "-global" $where]} {
						set level [string tolower [lindex [split $text] 2]]
						if {$level != "" && ![info exists global_user_levels($level)]} {
							putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names global_user_levels] ", "])"; return
						}
						set cl [accesslevel $hand]; # current level
						switch -exact -- $cl {
							0 {set before "Global Nothing"}
							1 {set before "Global Ban"}
							2 {set before "Global Voice"}
							3 {set before "Global Operator"}
							4 {set before "Global Master"}
							5 {set before "Global Owner"}
							6 {set before "Network Service"}
							7 {set before "Bot Developer"}
							8 {set before "Bot Administrator"}
						}
						#set levels $global_user_levels($level)
						set global 1
					} else {
						set where $channel
						set level [string tolower [lindex [split $text] 1]]
					}
					if {!$global} {
						if {$level != "" && ![info exists channel_user_levels($level)]} {
							putserv "NOTICE $nickname :Invalid userlevel '$level' specified. (Valid userlevels: [join [array names channel_user_levels] ", "])"; return
						} else {
							#set levels $channel_user_levels($level)
							set cl [accesslevel $hand $where]; # current level
							switch -exact -- $cl {
								0 {set before "unknown"}
								1 {set before "banned"}
								2 {set before "voice"}
								3 {set before "operator"}
								4 {set before "master"}
								5 {set before "owner"}
								6 {set before "unknown"}
							}
							# 6 == bot staff hack
						}
					}
					if {$level == ""} {
						if {$global} {
							if {[accesslevel $handle] == 0} {
								putserv "NOTICE $nickname: ERROR: You do not have the required privileges to view global access levels."; return
							}
							putserv "NOTICE $nickname :Global userlevel for '$who' is currently '$before'."; return
						} else {
							if {[accesslevel $handle $where] == 0} {
								putserv "NOTICE $nickname :ERROR: You do not have the required privileges to view $where access levels."; return
							}
							putserv "NOTICE $nickname :Channel userlevel for '$who' is currently '$where $before'."; return
						}
					} else {
						if {$global} {
							set levels $global_user_levels($level)
						} else {
							set levels $channel_user_levels($level)
						}
						set mf [lindex [split $levels] 0]; # flags required
						set af [lindex [split $levels] 1]; # flags provided
						set clear [expr {$level == "clear" || $level == "none" ? 1:0}]
						if {$global} {
							if {!$clear && [matchattr $hand $af]} {
								putserv "NOTICE $nickname :ERROR: User '$who' is already 'global $level'."; return
							} elseif {![matchattr $handle $mf]} {
								putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to modify '$who' to 'global $level'."; return
							}
						} else {			
							if {!$clear && [matchattr $hand $af $where]} {
								putserv "NOTICE $nickname :ERROR: User '$who' is already '$where $level'."; return
							} elseif {![matchattr $handle $mf $where]} {
								putserv "NOTICE $nickname :ERROR: You do not have the required priviledges to modify '$who' to '$where $level'."; return
							}
						}
						if {[string equal -nocase "clear" $level] || [string equal -nocase "none" $level]} { set level "nothing" }
						if {$global} {
							chattr $hand $af
							#set type [expr {[accesslevel $hand] > $cl ? "Upgraded" : "Downgraded"}]
							set type [expr {[accesslevel $hand] == $cl ? "Reset" : [expr {[accesslevel $hand] > $cl ? "Upgraded" : "Downgraded"}] }]
							if {[string equal -nocase "ban" $level]} {
								set kmsg $kickmsg(gban)
								channel set $adminchan [set id [expr {[channel get $adminchan gkid] + 1}]]
								regsub -all :adminchan: $kmsg "$adminchan" kmsg
								regsub -all :id: $kmsg "$id" kmsg
								regsub -all :reason: $kmsg "Global Banned" kmsg
								foreach host [getuser $hand HOSTS] {
									if {$host == "" || $host == "*!*@*" || $host == "*!*@" || [string match -nocase "-telnet!*@*" $host]} { continue }
									newban $host $handle "$kickmsg" 0
								}
							}
							#putserv "NOTICE $nickname :Global Access level for '#$hand' has been \002$type\002 from \002$before\002 to \002Global Ban\002."
							putserv "NOTICE $nickname :$type user access for '$who' from '$before' to 'global $level'."
						} else {
							chattr $hand |$af $where
							set type [expr {[accesslevel $hand $where] == $cl ? "Reset" : [expr {[accesslevel $hand $where] > $cl ? "Upgraded" : "Downgraded"}] }]
							if {[string equal -nocase "ban" $level]} {
								foreach host [getuser $hand HOSTS] {
									if {$host == "" || $host == "*!*@*" || $host == "*!*@" || [string match -nocase "-telnet!*@*" $host]} { continue }
									newchanban $where $host $handle "$kickmsg(defaultban)" 0
								}
							}
							#putserv "NOTICE $nickname :Access level for '#$hand' has been \002$type\002 from \002$before\002 to \002Channel Ban\002."
							putserv "NOTICE $nickname :$type user access for '$who' from '$where $before' to '$where $level'."
						}
					}
				}
				"deluser" {
					# just call access with clear as level
					putserv "NOTICE $nickname :ERROR: please use '${lastbind}access <nickname|#handle> ?-global|#channel? clear' instead."
				}
				"whois" {
					if {![matchattr $handle nmovfS|Snmovf $channel]} {
						puthelp "NOTICE $nickname :You are not known to me and so you can't whois my users."
						return
					}
					helper_xtra_set "lastcmd" $handle "${lastbind}$command $text"
					set who [lindex [split $text] 0]
					set whoo [lindex [split $text] 1]
					if {$who == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command nickname|#handle ?nickname|#handle?."
						return
					}
					if {[string index $who 0] == "#"} {
						if {![validuser [set hand [string range $who 1 end]]]} {
							putserv "NOTICE $nickname :Handle '#$hand' does not exist in my database."
						} else {
							set nicks [expr {[set x [lsort -unique [hand2nicks $hand]]] == "" ? "N/A" : $x}]
						}
					} else {
						set hand [nick2hand $who]
						if {$hand == ""} {
							putserv "NOTICE $nickname :ERROR: '$who' is not on any of my channels."
						} elseif {$hand == "*"} {
							putserv "NOTICE $nickname :ERROR: '$who' is not known to my database."
						} else {
							set nicks [expr {[set x [lsort -unique [hand2nicks $hand]]] == "" ? "N/A" : $x}]
						}
					}
					if {$whoo != "" && ![string equal -nocase $who $whoo]} {
						putserv "ERROR: '$who' does not equal '$whoo' - Extended WHOIS fail."; set extended 0; return
					} else {
						set extended 1
					}
					putserv "NOTICE $nickname :Account information for $who (using [expr {[string index $who 0] == "#" ? "nickname(s): [join $nicks ", "]" : "nickname(s): [join $nicks ", "] (under handle: $hand)"}]):"
					set global [matchattr $handle ADnm]
					putserv "NOTICE $nickname :Userid: [getuser $hand XTRA userid][expr {$global ? " - Global userflags: +[chattr $hand]." : "."}]"
					set lvl [list]; set protected 0
					if {[matchattr $hand A]} { lappend lvl "Administrator" }
					if {[matchattr $hand D]} { lappend lvl "Developer" }
					if {[matchattr $hand n]} { lappend lvl "Owner" }
					if {[matchattr $hand m]} { lappend lvl "Master" }
					if {[llength $lvl] >= 1} {
						putserv "NOTICE $nickname :$who is a Bot [join $lvl ", "]."
						set protected 1
					}
					if {[matchattr $hand S]} { putserv "NOTICE $nickname :$who is a Network Service."; putserv "NOTICE $nickname :End of WHOIS."; return }
					if {!$global && $protected} { putserv "NOTICE $nickname :End of WHOIS."; return }
					if {$extended} {
						putserv "NOTICE $nickname :Last Login: [expr {[getuser $hand XTRA lastlogin] == "" ? "N/A" : "[clock format [getuser $hand XTRA lastlogin] -format "%D %T"]"}]"
					}
					if {$global && $extended} {
						#putserv "NOTICE $nickname :Further information for '$who':"
						putserv "NOTICE $nickname :Last hostname: [getuser $hand XTRA lasthost]"
						putserv "NOTICE $nickname :Email: [getuser $hand XTRA email] - Last set: [expr {[getuser $hand XTRA emailset] == "" ? "N/A" : "[clock format [getuser $hand XTRA emailset] -format "%D %T"]"}]"
						putserv "NOTICE $nickname :Trigger: [getuser $hand XTRA mytrigger] - Last set: [expr {[getuser $hand XTRA mytriggerset] == "" ? "N/A" : "[clock format [getuser $hand XTRA mytriggerset] -format "%D %T"]"}]"
						putserv "NOTICE $nickname :Commands Executed: [expr {[set x [getuser $hand XTRA cmdcount]] == "" ? "0" : $x}] command[expr {$x == "1" ? "" : "s"}] - Last command: [expr {[getuser $hand XTRA lastcmd] == "" ? "N/A" : [getuser $hand XTRA lastcmd]}] - When: [expr {[getuser $hand XTRA lastcmdset] == "" ? "N/A" : "[clock format [getuser $hand XTRA lastcmdset] -format "%D %T"]"}]"
						putserv "NOTICE $nickname :Has '[llength [getuser $hand HOSTS]]' hostmask(s) assigned."
						putserv "NOTICE $nickname :[join [getuser $hand HOSTS] ", "]."
					}
					set list [list]
					foreach channel [channels] {
						if {[matchattr $handle ADnm|mnovf $channel] && [matchattr $who |mnovf $channel]} {
							lappend list "$channel [lindex [split [chattr $who $channel] |] 1]"
						}
					}
					if {[llength $list] < 1} {
						putserv "NOTICE $nickname :'$who' is not known on any of my channels."
					} else {
						putserv "NOTICE $nickname :'$who' is known in '[llength $list]' of my channel(s): (#channel +-flags)"
						putserv "NOTICE $nickname :[join $list ", "]."
					}
					putserv "NOTICE $nickname :End of WHOIS."
				}
				"whoami" {
					if {[matchattr $handle S]} { return }
					if {![validuser $handle]} { putserv "NOTICE $nickname :You are not known to me."; return }
					helper_xtra_set "lastcmd" $handle "${lastbind}$command $text"
					set nicks [expr {[set x [lsort -unique [hand2nicks $handle]]] == "" ? "N/A" : $x}] 
					putserv "NOTICE $nickname :Account information for $nickname (using nickname(s): [join $nicks ", "] (under handle: $handle)):"
					set global [matchattr $handle ADnmovf]
					putserv "NOTICE $nickname :Userid: [getuser $handle XTRA userid][expr {$global ? " - Global userflags: +[chattr $handle]" : "."}]"
					set lvl [list]
					if {[matchattr $handle A]} { lappend lvl "Administrator" }
					if {[matchattr $handle D]} { lappend lvl "Developer" }
					if {[matchattr $handle n]} { lappend lvl "Owner" }
					if {[matchattr $handle m]} { lappend lvl "Master" }
					if {[matchattr $handle o]} { lappend lvl "Operator" }
					if {[matchattr $handle vf]} { lappend lvl "Friend" }
					if {[llength $lvl] >= 1} {
						putserv "NOTICE $nickname :You're a Bot [join $lvl ", "]."
					}
					putserv "NOTICE $nickname :Last Login: [expr {[getuser $handle XTRA lastlogin] == "" ? "N/A" : "[clock format [getuser $handle XTRA lastlogin] -format "%D %T"]"}] - Last Hostname: [getuser $handle XTRA lasthost]"
					putserv "NOTICE $nickname :Email: [getuser $handle XTRA email] - Last set: [expr {[getuser $handle XTRA emailset] == "" ? "N/A" : "[clock format [getuser $handle XTRA emailset] -format "%D %T"]"}]"
					putserv "NOTICE $nickname :Trigger: [getuser $handle XTRA mytrigger] - Last set: [expr {[getuser $handle XTRA mytriggerset] == "" ? "N/A" : "[clock format [getuser $handle XTRA mytriggerset] -format "%D %T"]"}]"
					putserv "NOTICE $nickname :Commands Executed: [expr {[set x [getuser $handle XTRA cmdcount]] == "" ? "0" : $x}] command[expr {$x == "1" ? "" : "s"}] - Last command: [expr {[getuser $handle XTRA lastcmd] == "" ? "N/A" : [getuser $handle XTRA lastcmd]}] - When: [expr {[getuser $handle XTRA lastcmdset] == "" ? "N/A" : "[clock format [getuser $handle XTRA lastcmdset] -format "%D %T"]"}]"
					putserv "NOTICE $nickname :You have '[llength [getuser $handle HOSTS]]' hostmask(s) assigned to your account."
					putserv "NOTICE $nickname :[join [getuser $handle HOSTS] ", "]."

					set list [list]
					foreach channel [channels] {
						if {[matchattr $handle |nmovf $channel]} {
							lappend list "$channel [lindex [split [chattr $handle $channel] |] 1]"
						}
					}
					if {[llength $list] < 1} {
						putserv "NOTICE $nickname :You are not known on any of my channels."
					} else {
						putserv "NOTICE $nickname :You are known in the following [llength $list] channel(s): (#channel +-flags)"
						putserv "NOTICE $nickname :[join $list ", "]."
					}
					putserv "NOTICE $nickname :End of WHOAMI."
				}
				"protection" - "protect" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set status [channel get $channel service_prot]
					set hard [channel get $channel service_prot_hard]
					set cmd [lindex [split $text] 0]
					switch -exact -- $cmd {
						"on" - "enable" {
							if {$status} {
								putserv "NOTICE $nickname :$channel protection is already enabled."
							} elseif {[set sb [getnetworkservice $channel "chanserv"]] == ""} {
								putserv "NOTICE $nickname :No network channel service bot present at $channel."
							} else {
								channel set $channel service_servicebot $sb
								channel set $channel +service_prot
								if {[string match *l* [getchanmode $channel]]} {
									if {[string match *k* [getchanmode $channel]]} {
										channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 2]
									} else {
										channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 1]
									}
								}
								putserv "NOTICE $nickname :Done (Network Service: $sb)."
							}
						}
						"off" - "disable" {
							if {!$status} {
								putserv "NOTICE $nickname :$channel protection is already disabled."
							} else {
								channel set $channel -service_prot
								putserv "NOTICE $nickname :Done."
							}
						}
						"status" {
							putserv "NOTICE $nickname :$channel protection is \002[expr {$status ? "enabled" : "disabled"}]\002 - hard protection is \002[expr {$hard ? "enabled" : "disable"}]\002."
						}
						"hard" {
							switch -exact -- [set sub [lindex [split $text] 1]] {
								"on" - "enable" {
									if {$hard} {
										putserv "NOTICE $nickname :Hard protection is already enabled."
									} else {
										channel set $channel +service_prot_hard
										putserv "NOTICE $nickname :Hard protection is now enabled."
									}
								}
								"off" - "disable" {
									if {!$hard} {
										putserv "NOTICE $nickname :Hard protection is already disabled."
									} else {
										channel set $channel -service_prot_hard
										putserv "NOTICE $nickname :Hard protection is now disabled."
									}
								}
								"status" {
									if {$hard} {
										putserv "NOTICE $nickname :Hard protection is: \002enabled\002."
									} else {
										putserv "NOTICE $nickname :Hard protection is :\002disabled\002."
									}
								}
								"default" {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd on|off|status."
								}
							}
						}
						"default" {
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|status."
						}
					}
				}
				"enforcemode" - "enforcemodes" {
					set status [channel get $channel service_enforcemodes]
					set enforcedmodes [string map { k, {} l, {} } [channel get $channel service_enforcedmodes]]
					switch -exact -- [set cmd [lindex [split $text] 0]] {
						"on" {
							if {$status} {
								putserv "NOTICE $nickname :ERROR: $channel enforcemodes is already enabled."
							} else {
								channel set $channel +service_enforcemodes
								putserv "NOTICE $nickname :Done. $channel enforcemodes is now enabled."
							}
						}
						"off" {
							if {!$status} {
								putserv "NOTICE $nickname :ERROR: $channel enforcemodes is already disabled."
							} else {
								channel set $channel -service_enforcemodes
								putserv "NOTICE $nickname :Done. $channel enforcemodes is now disabled."
							}
						}
						"status" {
							putserv "NOTICE $nickname :$channel enforcemodes is [expr {$status eq 1 ? "enabled" : "disabled:"}]. Enforcedmodes set to '$enforcedmodes'."
						}
						"set" {
							set valid [list C c D s t T r p u n N m M i l k]
							if {[lrange $text 1 end] eq ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command $cmd +-modes ?params?. (Valid modes: [lsort [join $valid ""]])"; return }
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
						}
						"default" {
							putserv "NOTICE $nickname :Syntax: ${lastbind}$command on|off|set|status ?arguments?."
						}
					}
				}
				"spamscan" {
					if {![matchattr $handle nm|nm $channel]} {	return	}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					putserv "NOTICE $nickname :INFO: Spamscan has been removed from service - Discontinued."; return
				}
				"flood" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set status [channel get $channel service_flood]
					set chan [join [channel get $channel flood-chan] :]
					set join [join [channel get $channel flood-join] :]
					set ctcp [join [channel get $channel flood-ctcp] :]
					set mjoin [join [channel get $channel service_flood_massjoin] :]
					set btime "[channel get $channel service_bantime_flood]"
					switch -exact -- [set cmd [lindex [split $text] 0]] {
						"on" {
							if {$status} {
								putserv "NOTICE $nickname :$channel anti-flood is already enabled."
							} else {
								channel set $channel +service_flood
								putserv "NOTICE $nickname :$channel anti-flood is now enabled."
							}
						}
						"off" {
							if {!$status} {
								putserv "NOTICE $nickname :$channel anti-flood is already disabled."
							} else {
								channel set $channel -service_flood
								putserv "NOTICE $nickname :$channel anti-flood is now disabled."
							}
						}
						"set" {
							switch -exact -- [set cmd_ [lindex [split $text] 1]] {
								"chan" {
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
								}
								"join" {
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
								}
								"ctcp" {
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
								}
								"massjoin" {
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
								}
								"default" {
									putserv "NOTICE $nickname :anti-flood settings are either 'chan' or 'join' or 'ctcp'."
								}
							}
						}
						"bantime" {
							set btime_ "[lindex [split $text] 1]"
							if {$btime_ == ""} {
								putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd <bantime>."
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
						}
						"status" {
							set status "[expr {$status == 1 ? "enabled" : "disabled:"}]"
							if {$btime == "" || $btime == "0"} {
								set btime [channel set $channel service_bantime_flood 2]
							}
							putserv "NOTICE $nickname :$channel anti-flood is \002$status\002. Flood-chan is set to '$chan' ([lindex [split $chan :] 0] lines in [lindex [split $chan :] 1] seconds). Flood-join is set to '$join' ([lindex [split $join :] 0] joins in [lindex [split $join :] 1] seconds). Flood-ctcp is set to '$ctcp' ([lindex [split $ctcp :] 0] ctcps in [lindex [split $ctcp :] 1] seconds). Flood-bantime is set to '$btime' minute(s)."
						}
						"default" {
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|set|bantime|status."
						}
					}
				}
				"flyby" - "autoop" - "ao" - "autovoice" - "av" - "known" - "bitchmode" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set command_ [string tolower $command]
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
				"clonescan" {
					variable bantime; variable clonescan; variable networkservices
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set status [channel get $channel service_clonescan]
					foreach {y z} "bantime $bantime(clonescan) maxclones $clonescan(maxclones) hosttype $clonescan(hosttype)" {
						if {[channel get $channel service_clonescan_$y] == "" && $z != ""} {
							channel set $channel service_clonescan_$y $z
						}
					}
					switch -exact -- [set option [lindex [split $text] 0]] {
						"on" - "enable" {
							if {$status} {
								putserv "NOTICE $nickname :$channel clonescan on-join is already enabled."
							} else {
								channel set $channel +service_clonescan
								putserv "NOTICE $nickname :$channel clonescan on-join is bow enabled."
							}
						}
						"off" - "disabled" {
							if {!$status} {
								putserv "NOTICE $nickname :$channel clonescan on-join is already disabled."
							} else {
								channel set $channel -service_clonescan
								putserv "NOTICE $nickname :$channel clonescan on-join is now disabled."
							}
						}
						"set" {
							switch -exact -- [set sub [lindex [split $text] 1]] {
								"bantime" {
									if {[set bantime [lindex [split $text] 2]] == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option $sub ?#bantime? (Where bantime is digits only)."
									} elseif {![regexp -nocase -- {\#([\d]{1,})} $bantime -> bantime]} {
										putserv "NOTICE $nickname :You must specify a valid bantime. You must enter # followed by your bantime in minutes (Where bantime is digits only)."
									} elseif {$bantime == [set curr [channel get $channel service_clonescan_bantime]]} {
										putserv "NOTICE $nickname :The new bantime matches the current bantime. Please select a different bantime and try again."
									} elseif {$bantime < 1} {
										putserv "NOTICE $nickname :The bantime must be 1 minute or higher."
									} else {
										channel set $channel service_clonescan_bantime "$bantime"
										putserv "NOTICE $nickname :New bantime of '$bantime minute(s)' set."
									}
								}
								"maxclones" {
									if {[set max [lindex [split $text] 2]] == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option $sub ?#maxclones? (Where maxclones is digits only)."
									} elseif {![regexp -nocase -- {\#([\d]{1,})} $max -> max]} {
										putserv "NOTICE $nickname :You must specify a valid entery. You must enter # followed by maxclones (Where maxclones is digits only)."
									} elseif {$max == [set curr [channel get $channel service_clonescan_maxclones]]} {
										putserv "NOTICE $nickname :The new maxclones matches the current maxclones. Please specify a different maxclones setting and try again."
									} elseif {$max < 3} {
										putserv "NOTICE $nickname :The maxclones setting must be 3 or higher."
									} else {
										channel set $channel service_clonescan_maxclones "$max"
										putserv "NOTICE $nickname :New maxclones setting of '$max clone(s)' set."
									}
								}
								"hosttype" {
									if {[set host [lindex [split $text] 2]] == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option $sub ?#hosttype? (Where hosttype must be digits only)."
									} elseif {![regexp -nocase {\#(1|2)} $host -> host]} {
										putserv "NOTICE $nickname :You must specify a valid hosttype entery. You must enter # followed by your hosttype (Hosttype #1 = *!*@evil.host - Hosttype #2 = *!*ident@evil.host (~ is striped from hosts))."
									} elseif {$host == [set curr [channel get $channel service_clonescan_hosttype]]} {
										putserv "NOTICE $nickname :The new hosttype setting matches the current hosttype. Please specify a different hosttype setting and try again."
									} else {
										channel set $channel service_clonescan_hosttype "$host"
										putserv "NOTICE $nickname :New hosttype setting of '$host [expr {$host == 1 ? "*!*" : "*!*ident"}]@evil.host' set."
									}
								}
								"default" {
									putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option bantime ?#bantime?|maxclones ?#maxclones?|hosttype ?#hosttype?."
								}
							}
						}
						"status" {
							putserv "NOTICE $nickname :Clonescan on-join is: \002[expr {$status == 1 ? "enabled" : "disabled"}]\002. Bantime is \002[channel get $channel service_clonescan_bantime]\002, maxclones is \002[channel get $channel service_clonescan_maxclones]\002, and hosttype is \002[channel get $channel service_clonescan_hosttype]\002."
						}
						"scan" {
							putserv "NOTICE $nickname :Performing clonescan for $channel... for big channels this could take several minutes..."
							array set clones {}
							set total [llength [chanlist $channel]]
							set count 0
							foreach x [chanlist $channel] {
								if {[isbotnick $x] || [isnetworkservice $x]} { continue }
								set xh [string tolower [lindex [split [getchanhost $x $channel] @] 1]]
								if {![info exists clones($xh)]} {
									set clones($xh) "$x"
								} else {
									set clones($xh) "$clones($xh) $x"
								}
							}
							set l [string equal -nocase "-list" [lindex [split $text] 1]]
							foreach {h n} [array get clones] {
								set n [lsort -unique "[string tolower $n]"]
								if {[llength $n] > 1} {
									incr count [set z [expr {[llength $n] - 1}]]
									if {$l} {
										putserv "NOTICE $nickname :(${z}) clone(s) from (${h}) on ${channel}: [join $n ", "]"
									}
								}
							}
							array unset clones
							set bots [list]
							foreach bot [array names networkservices] {
								if {$bot == ""} { continue }
								if {[onchan $bot $channel]} {
									lappend bots "$bot"
								}
							}
							set final [expr {$total - 1 - [llength $bots] - $count}]
							putserv "NOTICE $nickname :$channel - Total: $total - Clones detected: $count - [expr {[llength $bots]+1}] bot(s) removed from list: [join "$botnick $bots" ", "] - Final usercount: $final."
						}
						"default" {
							putserv "NOTICE $nickname :Syntax: ${lastbind}$command on|off|set|scan|status."
						}
					}
				}
				"welcome" {
					variable welcomeskin
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set status [channel get $channel service_welcome]
					set notice [channel get $channel service_welcome_notice]
					if {[set skin [channel get $channel service_welcome_skin]] == ""} {
						channel set $channel service_welcome_skin "[set skin $welcomeskin]"
					}
					switch -exact -- [set cmd [lindex [split $text] 0]] {
						"on" {
							if {$status} {
								putserv "NOTICE $nickname :$channel welcome is already enabled."
							} else {
								channel set $channel +service_welcome
								putserv "NOTICE $nickname :$channel welcome is now enabled."
							}
						}
						"off" {
							if {!$status} {
								putserv "NOTICE $nickname :$channel welcome is already disabled."
							} else {
								channel set $channel -service_welcome
								putserv "NOTICE $nickname :$channel welcome is now disabled."
							}
						}
						"notice" {
							switch -exact -- [lindex [split $text] 1] {
								"on" {
									if {$notice} {
										putserv "NOTICE $nickname :$channel welcome notice is already enabled."
									} else {
										channel set $channel +service_welcome_notice
										putserv "NOTICE $nickname :$channel welcome notice is now enabled."
									}
								}
								"off" {
									if {!$notice} {
										putserv "NOTICE $nickname :$channel welcome notice is already disabled."
									} else {
										channel set $channel -service_welcome_notice
										putserv "NOTICE $nickname :$channel welcome notice is now disabled."
									}
								}
								"status" {
									putserv "NOTICE $nickname :$channel welcome notice is: \002[expr {$notice ? "enabled" : "disabled"}]\002."
								}
								"default" {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd on|off|status."
								}
							}
						}
						"set" {
							set newskin [join [lrange $text 1 end]]
							if {$skin == ""} {
								putserv "NOTICE $nickname :Current: $skin."
								putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd ?skin?."
							} elseif {[string length $newskin] < 10} {
								putserv "NOTICE $nickname :Welcome skin must be more than 10 letters."
							} elseif {[string length $newskin] > 250} {
								putserv "NOTICE $nickname :Welcome skin must be less than 250 letters."
							} elseif {[string equal -nocase $skin $newskin]} {
								putserv "NOTICE $nickname :The new welcome skin is the same as the current one."
							} else {
								channel set $channel service_welcome_skin "$newskin"
								putserv "NOTICE $nickname :Done. Welcome Skin set to: $newskin."
							}
						}
						"status" {
							putserv "NOTICE $nickname :$channel welcome is: \002[expr {$status ? "enabled" : "disabled"}]. $channel welcome notice is: \002[expr {$notice ? "enabled" : "disabled"}]."
						}
						"default" {
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|notice|set|status ?on/off/skin?."
						}
					}
				}
				"badword" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set status [channel get $channel service_badword]
					set words [channel get $channel service_badwords]
					set time [channel get $channel service_badword_bantime]
					if {$time == ""} { 
						channel set $channel service_badword_bantime "[set time 1]"
					}
					switch -exact -- [set cmd [lindex [split $text] 0]] {
						"on" {
							if {$status} {
								putserv "NOTICE $nickname :$channel badwords is already enabled."
							} else {
								channel set $channel +service_badword
								putserv "NOTICE $nickname :$channel badwords is now enabled."
							}
						}
						"off" {
							if {!$status} {
								putserv "NOTICE $nickname :$channel badwords is already disabled."
							} else {
								channel set $channel -service_badword
								putserv "NOTICE $nickname :$channel badwords is now disabled."
							}
						}
						"add" {
							set badword [lrange $text 1 end]
							if {$badword == ""} { 
								putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd ?badword?."
							} elseif {[llength $badword] > 1} {
								putserv "NOTICE $nickname :A badword may only consist of one word."
							} elseif {[regexp -nocase {\*} $badword]} {
								putserv "NOTICE $nickname :A badword is not to incldue '\*'."
							} elseif {[lsearch -exact [string tolower $words] [string tolower $badword]] != -1} {
								putserv "NOTICE $nickname :Badword '$badword' is already added to my badwords list."
							} else {
								channel set $channel service_badwords "[string tolower $words] [string tolower $badword]"
								putserv "NOTICE $nickname :Badword '$badword' added to my badwords list."
							}
						}
						"del" {
							set badword [lrange $text 1 end]
							if {$badword == ""} { 
								putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd ?badword?."
							} elseif {[llength $badword] > 1} {
								putserv "NOTICE $nickname :A badword may only consist of one word."
							} elseif {[regexp -nocase {\*} $badword]} {
								putserv "NOTICE $nickname :A badword is not to incldue '\*'."
							} elseif {[set index [lsearch -exact [string tolower $words] [string tolower $badword]]] == -1} {
								putserv "NOTICE $nickname :Badword '$badword' is not added to my badwords list."
							} else {
								channel set $channel service_badwords "[lreplace $words $index $index]"
								putserv "NOTICE $nickname :Badword '$badword' removed from my badwords list."
							}
						}
						"list" {
							set list [list]
							putserv "NOTICE $nickname :$channel badwords list:"
							foreach badword $words {
								if {$badword == ""} { continue }
								lappend list $badword
								if {[llength $badword] > 20} {
									putserv "NOTICE $nickname :[join $list ", "]"
									set list [list]
								}
							}
							if {[llength $list] > 0} {
								putserv "NOTICE $nickname :[join $list ", "]."
							}
							putserv "NOTICE $nickname :End of badwords list. (Total: [llength $words])"
						}
						"status" {
							putserv "NOTICE $nickname :$channel badwords is: \002[expr {$status ? "enabled" : "disabled"}]. $channel badwords-bantime is: \002$time minute(s)\002."
						}
						"bantime" {
							set bantime [lindex [split $text] 1]
							if {$bantime == ""} {
								putserv "NOTICE $nickname :Current: $time minute(s)."
								putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $cmd ?integer?."
							} elseif {![string is integer $bantime]} {
								putserv "NOTICE $nickname :Bantime must consist of digits only."
							} elseif {$bantime < 1 || $bantime > 30} {
								putserv "NOTICE $nickname :Bantime must be between 1 and 30 minutes."
							} elseif {$bantime == $time} {
								putserv "NOTICE $nickname :The new bantime is the same as the current."
							} else {
								channel set $channel service_badword_bantime $bantime
								putserv "NOTICE $nickname :Bantime set to '$bantime' minute(s)."
							}
						}
						"check" {
							set badword [lindex [split $text] 1]
							if {[lsearch -exact [string tolower $words] [string tolower $badword]] != -1} {
								putserv "NOTICE $nickname :'$badword' is a badword."
							} else {
								putserv "NOTICE $nickname :'$badword' is not a badword."
							}
						}
						"default" {
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|add|del|list|check|bantime|status ?badword?."
						}
					}
				}
				"antiadvertise" - "advert" - "advertise" {
					if {![matchattr $handle nm|nm $channel]} {	return	}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					putserv "NOTICE $nickname :INFO: Anti-advertise has been removed from service - Discontinued."; return
				}		
				"status" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set option [lindex [split $text] 0]; set color 0
					if {[string equal -nocase "-color" $option] || [string equal -nocase "-colour" $option]} {
						set color 1
					}
					array set status {}
					set status(Protection) [expr {[channel get $channel service_prot] ? "enabled" : "disabled"}]
					set status(Hard-protection) [expr {[channel get $channel service_prot_hard] ? "enabled" : "disabled"}]
					set status(Flyby) [expr {[channel get $channel service_flyby] ? "enabled" : "disabled"}]
					set status(Auto-op) [expr {[channel get $channel service_ao] ? "enabled" : "disabled"}]
					set status(Auto-voice) [expr {[channel get $channel service_av] ? "enabled" : "disabled"}]
					set status(Autolimit) [expr {[channel get $channel service_autolimit] ? "enabled" : "disabled"}]
					set status(Flood) [expr {[channel get $channel service_flood] ? "enabled" : "disabled"}]
					set status(Vip) [expr {[channel get $channel service_vip] ? "enabled" : "disabled"}]
					set status(Vip-skin) [expr {[channel get $channel service_vips] ? "enabled" : "disabled"}]
					set status(Vip-notice) [expr {[channel get $channel service_vipn] ? "notice" : "channel"}]
					set status(Badchan) [expr {[channel get $channel service_badchan] ? "enabled" : "disabled"}]
					set status(Authban) [expr {[channel get $channel service_authban] ? "enabled" : "disabled"}]
					set status(Welcome) [expr {[channel get $channel service_welcome] ? "enabled" : "disabled"}]
					set status(Known) [expr {[channel get $channel service_known] ? "enabled" : "disabled"}]
					set status(Bitchmode) [expr {[channel get $channel service_bitchmode] ? "enabled" : "disabled"}]
					set status(Badword) [expr {[channel get $channel service_badword] ? "enabled" : "disabled"}]
					set status(Auto-msg) [expr {[channel get $channel service_automsg] ? "enabled" : "disabled"}]
					set status(Peak) [expr {[channel get $channel service_peak] ? "enabled" : "disabled"}]
					set status(Enforce-modes) [expr {[channel get $channel service_enforcemodes] ? "enabled" : "disabled"}]
					set status(Enforced-modes) [string map { k, {} l, {} } [channel get $channel service_enforcedmodes]]
					putserv "NOTICE $nickname :Service status for ${channel}:"
					set li [list]
					foreach {type} [lsort [array names status]] {
						if {$type == ""} { continue }
						set stat $status($type)
						if {$stat == ""} { continue }
						if {$color} {
							if {$stat == "enabled"} { 
								set stat "\00303$stat\003"
							} elseif {$stat == "disabled"} {
								set stat "\00304$stat\003"
							} else {
								set stat "\00308$stat\003"
							}
						}
						lappend li "${type}: \002${stat}\002"
						if {[llength $li]>=7} {
							putserv "NOTICE $nickname :\([join $li "\) - \("]\)"
							set li [list]
						}
					}
					if {[llength $li]>=1} {
						putserv "NOTICE $nickname :\([join $li "\) - \("]\)."
					}
					#putserv "NOTICE $nickname :Service status for $channel: (Protection: \002$prot\002 (Hard protection: \002$hard\002)) - (Vip-scanner: \002$vip\002 (Vip-skin: \002$vips\002) (Vip message type: \002$vipn\002)) - (Badchan: \002$badchan\002) - (Authban: \002$authban\002) - (Badword: \002$badword\002) -"
					#putserv "NOTICE $nickname : (Anti-Advertise: \002$advert\002) - (Welcome: \002$welcome\002) - (Known-only: \002$known\002) - (Spamscan: \002$spam\002) - (Anti-Flood: \002$flood\002) - (Flyby: \002$flyby\002) - (Auto-op: \002$ao\002) - (Auto-voice: \002$av\002) - (Auto-limit: \002$al\002) - (Bitchmode: \002$bitchmode\002)."
				}
				"chanflags" {
					variable chanflags
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set flags [lindex [split $text] 0]
					array set current { {+} {} {-} {} }
					foreach {x y} [array get chanflags] {
						if {$x == "" || $y == ""} { continue }
						if {[channel get $channel [lindex [split $chanflags($x)] 0]]} {
							lappend current(+) $x
						} else {
							lappend current(-) $x
						}
					}
					if {$flags == ""} {
						putserv "NOTICE $nickname :Current: [join "+ [lsort -unique [join $current(+)]] - [lsort -unique [join $current(-)]]" ""]."
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command +-flags. Available flags: [join [lsort -unique [array names chanflags]] ""]."
					} else {
						if {[string index $flags 0] != "+" && [string index $flags 0] != "-"} {
							set flags "+$flags"
						}
						set unknown [list]
						foreach flag [split $flags ""] {
							if {$flag == "" || $flag == "+" || $flag == "-"} { continue }
							if {![info exists chanflags($flag)]} {
								lappend unknown $flag
							}
						}
						if {[llength $unknown] > 0} {
							putserv "NOTICE $nickname :Invalid or disallowed flag(s) '[join $unknown ", "]' specified."
						} else {
							array set done { {+} {} {-} {} }
							set lastmode ""
							foreach flag [split $flags ""] {
								if {$flag == "+" || $flag == "-"} { 
									set lastmode "$flag"
									continue
								}
								if {$lastmode == "+" && ![channel get $channel [lindex [split $chanflags($flag)] 0]]} {
									lappend done(+) $flag
									channel set $channel +[lindex [split $chanflags($flag)] 0]
								} elseif {$lastmode == "-" && [channel get $channel [lindex [split $chanflags($flag)] 0]]} {
									lappend done(-) $flag
									channel set $channel -[lindex [split $chanflags($flag)] 0]
								}
							}
							array set after { {+} {} {-} {} }
							foreach {x y} [array get chanflags] {
								if {$x == "" || $y == ""} { continue }
								if {[channel get $channel [lindex [split $chanflags($x)] 0]]} {
									lappend after(+) $x
								} else {
									lappend after(-) $x
								}
							}
							putserv "NOTICE $nickname :Done. Before: [join "+ [lsort -unique $current(+)] - [lsort -unique $current(-)]" ""] - After: [join "+ [lsort -unique "$after(+) $done(+)"] - [lsort -unique "$after(-) $done(-)"]" ""] - Changes: [join "+ [lsort -unique $done(+)] - [lsort -unique $done(-)]" ""]."
						}
					}
				}
				"automsg" {
					if {![matchattr $handle nm|nm $channel]} {
						putserv "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set status [channel get $channel service_automsg]
					set last [channel get $channel service_automsg_last]
					set counter [channel get $channel service_automsg_counter]
					set interval [channel get $channel service_automsg_interval]
					set moderate [channel get $channel service_automsg_moderate]
					set method [channel get $channel service_automsg_method]
					set messages [channel get $channel service_automsg_messages]
					set maps [channel get $channel service_automsg_maps]
					switch -exact -- [set option [lindex [split $text] 0]] {
						"on" - "enable" {
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
						}
						"off" - "disable" {
							if {!$status} {
								putserv "NOTICE $nickname :$channel automsg is already disabled."
							} else {
								channel set $channel -service_automsg
								putserv "NOTICE $nickname :$channel automsg is now disabled."
							}
						}
						"list" {
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
						}
						"interval" {
							set int [lindex [split $text] 1]
							if {[string index $int 0] != "#" || ![string is integer [set int [string trimleft $int #]]] || ($int<5 || $int>1440)} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option <#interval>. (Where interval must be a number between 5-1440)"
							} elseif {$int eq $interval} {
								putserv "NOTICE $nickname :ERROR: Interval is already set to '#$int' minute(s)."; return
							} else {
								channel set $channel service_automsg_interval $int
								putserv "NOTICE $nickname :Done. Auto-message interval for $channel set to '#$int' minute(s)."
							}
						}
						"moderate" {
							switch -exact -- [set sopt [lindex [split $text] 1]] {
								"on" - "enable" {
									if {$moderate} {
										putserv "NOTICE $nickname :$channel auto-message moderate is already enabled."
									} else {
										channel set $channel +service_automsg_moderate
										putserv "NOTICE $nickname :$channel auto-message moderate is now enabled."
									}
								}
								"off" - "disable" {
									if {!$moderate} {
										putserv "NOTICE $nickname :$channel auto-message moderate is already disabled."
									} else {
										channel set $channel -service_automsg_moderate
										putserv "NOTICE $nickname :$channel auto-message moderate is now disabled."
									}
								}
								"status" {
									putserv "NOTICE $nickname :$channel auto-message moderate is: \002[expr {$moderare ? "enabled" : "disabled"}]\002."
								}
								"default" {
									putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option on|off|status."
								}
							}
						}
						"status" {
							putserv "NOTICE $nickname :$channel auto-message is: \002[expr {$status ? "enabled" : "disabled"}]\002 with [llength $messages] auto-message(s) and [expr {[llength $maps]+2}] map(s) saved. Interval is set to: \002#$interval\002 minute(s). Moderate is: \002[expr {$moderate ? "enabled" : "disabled"}]\002. Method is: \002$method\002."
						}
						"group" {
							putserv "NOTICE $nickname :Coming Soon!"; return
						}
						"add" {
							if {$text eq ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command ?#position? <message>."; return }
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
						}
						"remove" {
							if {$text eq ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command <#id>."; return }
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
						}
						"map" {
							set locked [list :botnick: :channel:]
							switch -exact -- [set sopt [lindex [split $text] 1]] {
								"add" {
									set m [lindex [split $text] 2]
									set v [join [lrange $text 3 end]]
									if {$m == "" || $v == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $sopt <map> <value>."
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
								}
								"remove" {
									set m [lindex [split $text] 2]
									if {$m == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $sopt <map>."
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
								}
								"list" {
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
								}
								"default" {
									putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option add|remove|list ?map? ?value?."
								}
							}
						}
						"method" {
							set valid [list random loop default]
							if {[set method [string tolower [lindex [split $text] 1]]] eq ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command ?method?. (Valid methods: [lsort [join $valid ", "]])"
							} elseif {![lsearch -exact $valid $method]==-1} {
								putserv "NOTICE $nickname :ERROR: Invalid method '$method' - Valid methods: [lsort [join $valid ", "]]."
							} else {
								channel set $channel service_automsg_method $method
								putserv "NOTICE $nickname :Done. $channel auto-message method set to '$method'."
							}
						}
						"default" {
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|add|remove|list|interval|moderate|group|method|map ?arguements?."
						}
					}
				}
				"mytrigger" - "mytrig" - "trig" - "trigger" {
					variable triggers
					if {![validuser [nick2hand $nickname]]} {
						puthelp "NOTICE $nickname :You're not known to my userbase, so you can't set a trigger."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set trigger [join [lindex [split $text] 0]]
					if {$trigger == ""} {
						putserv "NOTICE $nickname :Current mytrigger: [expr {[getuser $handle XTRA mytrigger] == "" ? "not set" : "[getuser $handle XTRA mytrigger]"}] (Triggers: [join "$triggers" ", "])."
					} elseif {[lsearch -exact "$triggers" $trigger] == "-1"} {
						putserv "NOTICE $nickname :Invalid trigger '$trigger'. Valid triggers are: [join "$triggers" ", "]."
					} else {
						setuser $handle XTRA mytrigger "$trigger"
						putserv "NOTICE $nickname :Trigger changed to '$trigger'."
					}
				}
				"version" {
					variable script; variable author; variable version; variable linecount
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set modules [loadedmodules]
					puthelp "NOTICE $nickname :$script v${version} by $author loaded! (Line Count: $linecount) ([llength $modules] module(s) loaded[expr {[llength $modules]>0  ? ": [join $modules ", "]" : ""}])."
				}
				"invite" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set invite [lindex [split $text] 0]
					if {$invite == ""} {
						putserv "NOTICE $nickname :Syntax: ${lastbind}$command <nickname>."
					} elseif {[onchan $invite $channel]} {
						putserv "NOTICE $nickname :ERROR: $invite is already on $channel."
					} elseif {![botisop $channel]} {
						putserv "NOTICE $nickname :I need op to do that!"
					} else {
						puthelp "INVITE $invite $channel"
						putserv "NOTICE $nickname :Invited $invite to $channel."
					}
				}
				"vip" {
					variable vipskin; variable vipmode
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return 
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					switch -exact -- [set option [lindex [split $text] 0]] {
						"add" {
							set chan [lindex [split $text] 1]
							set status [lindex [split $text] 2]
							if {$chan == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option #channel @/+."
							} else {
								if {[string index $chan 0] != "#"} {
									set chan "#$chan"
								}
								if {$status == ""} {
									set status "@"
								}
								if {![regexp {^\@|\+$} $status]} {
									putserv "NOTICE $nickname :Vip status must be one of '@ +'. (@ means ops only | + means both ops and voice)"
									return
								}
								set vlist [string tolower [channel get $channel service_vipc]]
								set index ""
								foreach x $vlist {
									if {$x == ""} { continue }
									if {[string equal -nocase $chan [string range $x 1 end]]} {
										set index [lsearch -exact $vlist $x]; break
									}
								}
								if {$index == ""} {
									lappend vlist ${status}${chan}
									channel set $channel service_vipc $vlist
									set service::vip::vipchannels([string tolower $channel],[string tolower $chan]) $status
									putserv "NOTICE $nickname :Vip channel '$chan' has been added with status '$status' successfully."
								} else {
									set vstatus [string index [lindex [split $vlist] $index] 0]
									if {$vstatus == $status} { 
										putserv "NOTICE $nickname :Vip channel '$chan' is already added as status '$status'."
									} else {
										set vlist [lreplace $vlist $index $index ${status}${chan}]
										channel set $channel service_vipc $vlist
										putserv "NOTICE $nickname :Vip channel '$chan' was already added as status '$vstatus' but has now been modifed to '$status'."
									}
								}
							}
						}
						"del" {
							set chan [lindex [split $text] 1]
							if {$chan == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option #channel."
							} else {
								if {[string index $chan 0] != "#"} {
									set chan "#$chan"
								}
								set vlist [string tolower [channel get $channel service_vipc]]
								set index "-1"
								foreach x $vlist {
									if {$x == ""} { continue }
									if {[string equal -nocase $chan [string range $x 1 end]]} {
										set index [lsearch -exact $vlist $x]; break
									}
								}
								if {$index == "-1"} {
									putserv "NOTICE $nickname :Vip channel '$chan' does not exist."
								} else {
									set vlist [lreplace $vlist $index $index]
									channel set $channel service_vipc $vlist
									if {[info exists service::vip::vipchannels([string tolower $channel],[string tolower $chan])]} {
										unset service::vip::vipchannels([string tolower $channel],[string tolower $chan])
									}
									putserv "NOTICE $nickname :Vip channel '$chan' was removed successfully."
								}
							}
						}
						"list" {
							set status [lindex [split $text] 1]
							if {$status != "" && ($status != "@" || $status != "+")} {
								putserv "NOTICE $nickname :Invalid status '$status'. Status must be one of '@ +'."; return
							}
							set total [llength [channel get $channel service_vipc]]
							set i 0; set op 0; set voice 0; set list [list]
							foreach vchan [channel get $channel service_vipc] {
								if {$vchan == ""} { continue }
								if {$status != "" && [string equal -nocase $status [string index $vchan 0]]} {
									lappend list $vchan; incr i
								} else {
									if {[string index $vchan 0] == "@"} {
										incr op
									} else {
										incr voice
									}
									lappend list "$vchan"
								}
								if {[llength $list] == "20"} {
									putserv "NOTICE $nickname :[join $list ", "]"
									set list [list]
								}
							}
							if {[llength $list] > 0} {
								putserv "NOTICE $nickname :[join $list ", "]."
							}
							if {$status != ""} {
								putserv "NOTICE $nickname :End of vip list. (${i}/$total $status)"
							} else {
								putserv "NOTICE $nickname :End of vip list. (Total: $total - @: $op - +: $voice)"
							}
						}
						"skin" {
							if {[channel get $channel service_vipskin] == ""} {
								channel set $channel service_vipskin "$vipskin"
							}
							set skin [lrange $text 1 end]
							if {$skin == ""} {
								putserv "NOTICE $nickname :$channel vip-skin: [join [channel get $channel service_vipskin]] - Keyword(s) available: :nickname: :hostname: :channel: :vipchannel: :status: :id:."
							} else {
								if {[string length $skin] < "2"} {
									putserv "NOTICE $nickname :The minimum vip-skin length allowed is 2."
								} elseif {[string length $skin] > "300"} {
									putserv "NOTICE $nickname :The maxium vip-skin length allowed is 300. The current skin length is [string length $skin]."
								} else {
									channel set $channel service_vipskin "$skin"
									putserv "NOTICE $nickname :$channel vip-skin set to: [join [channel get $channel service_vipskin]]."
								}
							}
						}
						"set" {
							switch -exact -- [set opt [lindex [split $text] 1]] {
								"skin" {
									switch -exact -- [set cmd [lindex [split $text] 2]] {
										"on" {
											if {[channel get $channel service_vips]} {
												putserv "NOTICE $nickname :$channel vip-skin is already enabled."
											} else {
												channel set $channel +service_vips
												putserv "NOTICE $nickname :$channel vip-skin is now enabled."
											}
										}
										"off" {
											if {![channel get $channel service_vips]} {
												putserv "NOTICE $nickname :$channel vip-skin is already disabled."
											} else {
												channel set $channel -service_vips
												putserv "NOTICE $nickname :$channel vip-skin is now disabled."
											}
										}
										"status" {
											putserv "NOTICE $nickname :$channel vip-skin is [expr {[channel get $channel service_vips] ? "enabled" : "disabled"}]."
										}
										"default" {
											putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option $opt on|off|status."
										}
									}
								}
								"notice" {
									switch -exact -- [set cmd [lindex [split $text] 2]] {
										"on" {
											if {[channel get $channel service_vipn]} {
												putserv "NOTICE $nickname :$channel vip-notice is already enabled."
											} else {
												channel set $channel +service_vipn
												putserv "NOTICE $nickname :$channel vip-notice is now enabled."
											}
										}
										"off" {
											if {![channel get $channel service_vipn]} {
												putserv "NOTICE $nickname :$channel vip-notice is already disabled."
											} else {
												channel set $channel -service_vipn
												putserv "NOTICE $nickname :$channel vip-notice is now disabled."
											}
										}
										"status" {
											putserv "NOTICE $nickname :$channel vip-notice is [expr {[channel get $channel service_vipn] ? "enabled" : "disabled"}]."
										}
										"default" {
											putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option $opt on|off|status."
										}
									}
								}
								"authed" {
									switch -exact -- [set cmd [lindex [split $text] 2]] {
										"on" {
											if {[channel get $channel service_vip_authed]} {
												putserv "NOTICE $nickname :$channel vip-authed is already enabled."
											} else {
												channel set $channel +service_vip_authed
												putserv "NOTICE $nickname :$channel vip-authed is now enabled."
											}
										}
										"off" {
											if {![channel get $channel service_vip_authed]} {
												putserv "NOTICE $nickname :$channel vip-authed is already disabled."
											} else {
												channel set $channel -service_vip_authed
												putserv "NOTICE $nickname :$channel vip-authed is now disabled."
											}
										}
										"status" {
											putserv "NOTICE $nickname :$channel vip-authed is [expr {[channel get $channel service_vip_authed] ? "enabled" : "disabled"}]."
										}
										"default" {
											putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option $opt on|off|status."
										}
									}
								}
								"chanmode" {
									switch -exact -- [set cmd [lindex [split $text] 2]] {
										"on" {
											if {[channel get $channel service_vip_chanmode]} {
												putserv "NOTICE $nickname :$channel vip-chanmode is already enabled."
											} else {
												channel set $channel +service_vip_chanmode
												putserv "NOTICE $nickname :$channel vip-chanmode is now enabled."
											}
										}
										"off" {
											if {![channel get $channel service_vip_chanmode]} {
												putserv "NOTICE $nickname :$channel vip-chanmode is already disabled."
											} else {
												channel set $channel -service_vip_chanmode
												putserv "NOTICE $nickname :$channel vip-chanmode is now disabled."
											}
										}
										"status" {
											putserv "NOTICE $nickname :$channel vip-chanmode is [expr {[channel get $channel service_vip_chanmode] ? "enabled" : "disabled"}]."
										}
										"default" {
											putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option $opt on|off|status."
										}
									}
								}
								"dynamicmode" {
									switch -exact -- [set cmd [lindex [split $text] 2]] {
										"on" {
											if {[channel get $channel service_vip_dynamicmode]} {
												putserv "NOTICE $nickname :$channel vip-dynamicmode is already enabled."
											} else {
												channel set $channel +service_vip_dynamicmode
												putserv "NOTICE $nickname :$channel vip-dynamicmode is now enabled."
											}
										}
										"off" {
											if {![channel get $channel service_vip_dynamicmode]} {
												putserv "NOTICE $nickname :$channel vip-dynamicmode is already disabled."
											} else {
												channel set $channel -service_vip_dynamicmode
												putserv "NOTICE $nickname :$channel vip-dynamicmode is now disabled."
											}
										}
										"status" {
											putserv "NOTICE $nickname :$channel vip-dynamicmode is [expr {[channel get $channel service_vip_dynamicmode] ? "enabled" : "disabled"}]."
										}
										"default" {
											putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option $opt on|off|status."
										}
									}
								}
								"default" {
									putserv "NOTICE $nickname :Vip-skin is: \002[expr {[channel get $channel service_vips] ? "enabled" : "disabled"}]\002. Vip-notice is: \002[expr {[channel get $channel service_vipn] ? "enabled" : "disabled"}]\002. Vip-authed is: \002[expr {[channel get $channel service_vip_authed] ? "enabled" : "disabled"}]\002. Vip-chanmode is: \002[expr {[channel get $channel service_vip_chanmode] ? "enabled" : "disabled"}]\002. Vip-dynamicmode is: \002[expr {[channel get $channel service_vip_dynamicmode] ? "enabled" : "disabled"}]\002."
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option skin|notice|authed|chanmode|dynamicmode ?on|off|status?."
								}
							}
						}
						"authbl" {
							switch -exact -- [set cmd [lindex [split $text] 1]] {
								"add" {
									set authname [string tolower [lindex [split $text] 2]]
									if {$authname == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option authname."
										return
									}
									set blist [string tolower [channel get $channel service_vip_authblist]]
									set index "-1"
									foreach x $blist {
										if {$x == ""} { continue }
										if {[string equal -nocase $authname $x]} {
											set index [lsearch -exact $blist $x]; break
										}
									}
									if {$index == "-1"} {
										lappend $blist $authname
										channel set $channel service_vip_authblist $blist
										putserv "NOTICE $nickname :Vip authname '$authname' was successfully blacklisted."
									} else {
										putserv "NOTICE $nickname :Vip authname '$authname' is already blacklisted."
									}
								}
								"del" {
									set authname [string tolower [lindex [split $text] 2]]
									if {$authname == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option authname."
										return
									}
									set blist [string tolower [channel get $channel service_vip_authblist]]
									set index "-1"
									foreach x $blist {
										if {$x == ""} { continue }
										if {[string equal -nocase $authname $x]} {
											set index [lsearch -exact $blist $x]; break
										}
									}
									if {$index == "-1"} {
										putserv "NOTICE $nickname :Vip authname '$authname' is not blacklisted."
									} else {
										set blist [lreplace $blist $index $index]
										channel set $channel service_vip_authblist $blist
										putserv "NOTICE $nickname :Vip authname '$authname' was successfully removed from my blacklist."
									}
								}
								"list" {
									set total 0
									set list [list]
									foreach auth [channel get $channel service_vip_authblist] {
										if {$auth == ""} { continue }
										incr total
										lappend list "$auth"
										if {[llength $list] == "20"} {
											putserv "NOTICE $nickname :[join $list ", "]"
											set list [list]
										}
									}
									if {[llength $list] > 0} {
										putserv "NOTICE $nickname :[join $list ", "]."
									}
									putserv "NOTICE $nickname :End of vip blacklist. (Total: $total)"
								}
								"on" {
									if {[channel get $channel service_vip_authbl]} {
										putserv "NOTICE $nickname :$channel vip-authbl is already enabled."
									} else {
										channel set $channel +service_vip_authbl
										putserv "NOTICE $nickname :$channel vip-authbl is now enabled."
									}
								}
								"off" {
									if {![channel get $channel service_vip_authbl]} {
										putserv "NOTICE $nickname :$channel vip-authbl is already disabled."
									} else {
										channel set $channel -service_vip_authbl
										putserv "NOTICE $nickname :$channel vip-authbl is now disabled."
									}
								}
								"status" {
									putserv "NOTICE $nickname :$channel vip-authbl is [expr {[channel get $channel service_vip_authbl] ? "enabled" : "disabled"}]. ([llength [channel get $channel service_vip_authblist]] auth(s) blacklisted)"
								}
								"default" {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option add|del|list|on|off|status."
								}
							}
						}
						"mode" {
							if {[channel get $channel service_vipm] == ""} {
								channel set $channel service_vipm "$vipmode"
							}
							set status "[lindex [split $text] 1]"
							if {$status == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option @/+."
							} elseif {![regexp {\@|\+} $status]} {
								putserv "NOTICE $nickname :Vip-mode must be one of '@ +'."
							} elseif {$status == [channel get $channel service_vipm]} {
								putserv "NOTICE $nickname :Vip-mode is already set to '$status'."
							} else {
								channel set $channel service_vipm "$status"
								putserv "NOTICE $nickname :Vip-mode is now set to '$status'."
							}
						}
						"on" {
							if {[channel get $channel service_vip]} {
								putserv "NOTICE $nickname :Vip is already \002enabled\002."
							} else {
								channel set $channel +service_vip
								putserv "NOTICE $nickname :Vip is now \002enabled\002."
							}
						}
						"off" {
							if {![channel get $channel service_vip]} {
								putserv "NOTICE $nickname :Vip is already \002disabled\002."
							} else {
								channel set $channel -service_vip
								putserv "NOTICE $nickname :Vip is now \002disabled\002."
							}
						}
						"default" {
							set vip [expr {[channel get $channel service_vip] ? "enabled" : "disabled"}]
							set vips [expr {[channel get $channel service_vips] ? "enabled" : "disabled"}]
							set vipn [expr {[channel get $channel service_vipn] ? "enabled" : "disabled"}]
							set vipa [expr {[channel get $channel service_vip_authed] ? "enabled" : "disabled"}]
							set vipab [expr {[channel get $channel service_vip_authbl] ? "enabled" : "disabled"}]
							set vipcm [expr {[channel get $channel service_vip_chanmode] ? "enabled" : "disabled"}]
							set vipdm [expr {[channel get $channel service_vip_dynamicmode] ? "enabled" : "disabled"}]
							if {[set vipm [channel get $channel service_vipm]] == ""} {
								channel set $channel service_vipm "[set vipm $vipmode]"
							}
							if {[set vipid [channel get $channel service_vipid]] == ""} {
								channel set $channel service_vipid "[set vipid 0]"
							}
							putserv "NOTICE $nickname :Vip is: \002$vip\002 - Vip-skin is: \002$vips\002 - Vip-notice is: \002$vipn\002 - Vip-mode is: \002$vipm\002 - Vip-id is: \002#$vipid\002 - Vip-channel(s): \002[llength [channel get $channel service_vipc]]\002."
							putserv "NOTICE $nickname :Vip-authed is: \002$vipa\002 - Vip-authblacklist is: \002$vipab\002 - \002[llength [channel get $channel service_vip_authblist]] blacklisted auth(s)\002. Vip-chanmode is: \002$vipcm\002. Vip-dynamicmode is: \002$vipdm\002."
							putserv "NOTICE $nickname :Syntax: ${lastbind}$command on|off|add|del|set|list|authbl|mode ?arguments?."
						}
					}
				}
				"badchan" {
					variable homechan; variable adminchan; variable helpchan
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return 
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					switch -exact -- [set option [lindex [split $text] 0]] {
						"add" {
							set chan [lindex [split $text] 1]
							if {$chan == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option #channel."
							} else {
								if {[string index $chan 0] != "#"} {
									set chan "#$chan"
								}
								if {[string equal -nocase $chan $channel]} {
									putserv "NOTICE $nickname :Error: You can't bad channel your own channel!"
									return
								}
								if {[string equal -nocase $homechan $chan] || [string equal -nocase $adminchan $chan] || [string equal -nocase $helpchan $chan]} {
									putserv "NOTICE $nickname :Error: Can't add '$chan' to my bad channel list. (Protected channel)"
									return
								}
								set found 0
								set list [list]
								foreach bchan [channel get $channel service_badchans] {
									if {$bchan == ""} { continue }
									if {[string equal -nocase $chan $bchan]} {
										putserv "NOTICE $nickname :Bad Channel '$chan' is already added."
										set found 1
									} else {
										lappend list "$bchan"
									}
								}
								if {!$found} {
									channel set $channel service_badchans "[channel get $channel service_badchans] $chan"
									putserv "NOTICE $nickname :Bad Channel '$chan' added successfully."
								}
							}
						}
						"del" {
							set chan [lindex [split $text] 1]
							if {$chan == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option del #channel."
							} else {
								if {[string index $chan 0] != "#"} {
									set chan "#$chan"
								}
								set found 0
								set list [list]
								foreach bchan [channel get $channel service_badchans] {
									if {$bchan == ""} { continue }
									if {[string equal -nocase $chan $bchan]} {
										set found 1
									} else {
										lappend list "$bchan"
									}
								}
								if {$found} {
									channel set $channel service_badchans "[join $list " "]"
									putserv "NOTICE $nickname :Removed bad channel '$chan' successfully."
								} else {
									putserv "NOTICE $nickname :Bad Channel '$chan' is not added."
								}
							}
						}
						"list" {
							set total 0
							set list [list]
							foreach bchan [channel get $channel service_badchans] {
								if {$bchan == ""} { continue }
								incr total
								lappend list "$bchan"
								if {[llength $list] == "20"} {
									putserv "NOTICE $nickname :[join $list ", "]"
									set list [list]
								}
							}
							if {[llength $list] > 0} {
								putserv "NOTICE $nickname :[join $list ", "]."
								set list [list]
							}
							putserv "NOTICE $nickname :End of bad channels list. (Total: $total)"
						}
						"on" {
							if {[channel get $channel service_badchan]} {
								putserv "NOTICE $nickname :Bad Channel is already \002enabled\002."
							} else {
								channel set $channel +service_badchan
								putserv "NOTICE $nickname :Bad Channel is now \002enabled\002."
							}
						}
						"off" {
							if {![channel get $channel service_badchan]} {
								putserv "NOTICE $nickname :Bad Channel is already \002disabled\002."
							} else {
								channel set $channel -service_badchan
								putserv "NOTICE $nickname :Bad Channel is now \002disabled\002."
							}
						}
						"default" {
							set status [expr {[channel get $channel service_badchan] ? "enabled" : "disabled"}]
							set badchans [llength [channel get $channel service_badchans]]
							if {[set id [channel get $channel service_bid]] == ""} {
								channel set $channel service_bid "[set id 0]"
							}
							putserv "NOTICE $nickname :Bad Channel is: \002$status\002 - Bad Channel(s): \002$badchans\002 - Bad Channel ID: \002#$id\002."
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|add|del|list ?arguments?."
						}
					}
				}
				"authban" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return 
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					switch -exact -- [set option [lindex [split $text] 0]] {
						"add" {
							set auth [lindex [split $text] 1]
							if {$auth == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option authname."
							} elseif {[regexp -- {(.+)!(.+)@(.+)} $auth]} {
								putserv "NOTICE $nickname :Error: Your input matches a hostmask layout, if you want to ban a hostmask please use the BAN command."
							} else {
								if {[string match -nocase *users.quakenet.org $hostname] && [string equal -nocase $auth [lindex [split [lindex [split $hostname @] 1] .] 0]]} {
									putserv "NOTICE $nickname :Error: You can't ban your own authname!"
									return
								}
								if {[matchattr [finduser *!*@$auth.users.quakenet.org] nmobSBF]} {
									putserv "NOTICE $nickname :Error: You can't ban this authname - Protected authname."
									return
								}
								set found 0
								set list [list]
								foreach bauth [channel get $channel service_authbans] {
									if {$bauth == ""} { continue }
									if {[string equal -nocase $auth $bauth]} {
										putserv "NOTICE $nickname :Authname '$auth' is already added."
										set found 1
									} else {
										lappend list "$bauth"
									}
								}
								if {!$found} {
									channel set $channel service_authbans "[channel get $channel service_authbans] $auth"
									putserv "NOTICE $nickname :Authname '$auth' added successfully."
								}
							}
						}
						"del" {
							set auth [lindex [split $text] 1]
							if {$auth == ""} {
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option del authname."
							} elseif {[regexp -- {(.+)!(.+)@(.+)} $auth]} {
								putserv "NOTICE $nickname :Error: Your input matches a hostmask layout, if you want to unban a hostmask please use the UNBAN command."
							} else {
								set found 0
								set list [list]
								foreach bauth [channel get $channel service_authbans] {
									if {$bauth == ""} { continue }
									if {[string equal -nocase $auth $bauth]} {
										set found 1
									} else {
										lappend list "$bauth"
									}
								}
								if {$found} {
									channel set $channel service_authbans "[join $list " "]"
									putserv "NOTICE $nickname :Removed authname '$auth' successfully."
								} else {
									putserv "NOTICE $nickname :Authname '$auth' is not added."
								}
							}
						}
						"list" {
							set total 0
							set list [list]
							foreach bauth [channel get $channel service_authbans] {
								if {$bauth == ""} { continue }
								incr total
								lappend list "$bauth"
								if {[llength $list] == "20"} {
									putserv "NOTICE $nickname :[join $list ", "]"
									set list [list]
								}
							}
							if {[llength $list] > 0} {
								putserv "NOTICE $nickname :[join $list ", "]."
								set list [list]
							}
							putserv "NOTICE $nickname :End of authbans list. (Total: $total)"
						}
						"on" {
							if {[channel get $channel service_authban]} {
								putserv "NOTICE $nickname :Authbans is already \002enabled\002."
							} else {
								channel set $channel +service_authban
								putserv "NOTICE $nickname :Authbans is now \002enabled\002."
							}
						}
						"off" {
							if {![channel get $channel service_authban]} {
								putserv "NOTICE $nickname :Authbans is already \002disabled\002."
							} else {
								channel set $channel -service_authban
								putserv "NOTICE $nickname :Authbans is now \002disabled\002."
							}
						}
						"default" {
							set status [expr {[channel get $channel service_authban] ? "enabled" : "disabled"}]
							set authbans [llength [channel get $channel service_authbans]]
							if {[set id [channel get $channel service_aid]] == ""} {
								channel set $channel service_aid "[set id 0]"
							}
							putserv "NOTICE $nickname :Authbans is: \002$status\002 - Authname(s): \002$authbans\002 - Authbans ID: \002#$id\002."
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|add|del|list ?arguments?."
						}
					}
				}
				"op" - "voice" - "deop" - "devoice" {
					if {![matchattr $handle ADnm|nmovf $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {![botisop $channel]} {
						putserv "NOTICE $nickname :$channel ${command}: I need op to do that!"
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
						}
					} else {
						set pre [expr {([string equal -nocase "op" $command] || [string equal -nocase "voice" $command]) ? "+" : "-"}]
						set mode [expr {([string equal -nocase "op" $command] || [string equal -nocase "deop" $command]) ? "o" : "v"}]
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
									}
									if {[llength $matched] eq 6} {
										putlog "Wildcard matched: [join $matched " "]"
										putlog "MODE $channel ${pre}[string repeat $mode 6] [join $matched " "]"
										putquick "MODE $channel ${pre}[string repeat $mode 6] [join $matched " "]"; set matched [list]
									}
								}
								if {[llength $matched] > 0} {
									putlog "Wildcard matched: [join $matched " "]"
									putlog "MODE $channel ${pre}[string repeat $mode [llength $matched]] [join $matched " "]"
									putquick "MODE $channel ${pre}[string repeat $mode [llength $matched]] [join $matched " "]"; set matched [list]
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
								}
								if {[llength $users] eq 6} {
									putquick "MODE $channel ${pre}[string repeat $mode 6] [join $users " "]"; set users [list]
								}
							}
						}
						if {[llength $users]>0} {
							putquick "MODE $channel ${pre}[string repeat $mode [llength $users]] [join $users " "]"; set users [list]
						}
						putquick "NOTICE $nickname :Done. (Not on ${channel}: [expr {[llength $notonchan]<=0 ? "N/A" : [join $notonchan ", "]}] - Blocked: [expr {[llength $blocked]<=0 ? "N/A" : [join $blocked ", "]}])"
					}
				}
				"mode" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					#modes = bCcdDiklmnNoprstuv
					if {$text == ""} {
						putserv "NOTICE $nickname :${lastbind}$command +-modes."
					} elseif {![regexp {\+|\-} [string index $text 0]]} {
						putserv "NOTICE $nickname :Mode(s) must start with a '+' or '-'."
					} else {
						putserv "MODE $channel $text"
					}
				}
				"topic" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					set skin [channel get $channel service_topic_skin]
					set current [channel get $channel service_topic_current]
					set maps [channel get $channel service_topic_map]
					set q [channel get $channel service_topic_Q]
					set save [channel get $channel service_topic_save]
					set force [channel get $channel service_topic_force]
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					switch -exact -- [set option [lindex [split $text] 0]] {
						"skin" {
							set nskin [join [lrange $text 1 end]]
							if {$nskin eq ""} {
								putserv "NOTICE $nickname :Current skin: $skin"
								putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option <skin>. (Words enclosed in :'s are keywords (example - :channel: :news:))"
							} elseif {[string equal $skin $nskin]} {
								putserv "NOTICE $nickname :ERROR: Skin already set to '$skin'."
							} else {
								channel set $channel service_topic_skin [set skin $nskin]
								# detect keywords??
								# process the new skin??
								putserv "NOTICE $nickname :Done. $channel topic skin set to '$nskin'."
							}
						}
						"keyword" - "keywords" - "map" {
							set locked [list :botnick: :channel:]
							switch -exact -- [set sopt [lindex [split $text] 1]] {
								"add" - "set" {
									set m [lindex [split $text] 2]
									set v [join [lrange $text 3 end]]
									if {$m == "" || $v == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $sopt <map> <value>."
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
								}
								"remove" - "del" - "unset" {
									set m [lindex [split $text] 2]
									if {$m == ""} {
										putserv "NOTICE $nickname :Syntax: ${lastbind}$command $sopt <map>."
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
								}
								"list" {
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
								}
								"default" {
									putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option add|remove|list ?keyword? ?value?."
								}
							}
						}
						"preview" {
							if {$skin eq ""} { putserv "NOTICE $nickname :ERROR: No topic skin set for $channel."; return }
							set maps [linsert [linsert $maps end ":channel: $channel"] end ":botnick: $::botnick"]
							set topic [string map [join $maps] $skin]
							putserv "NOTICE $nickname :Topic preview for $channel:"
							putserv "NOTICE $nickname :$topic"
						}
						"set" {
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
						}
						"q" - "Q" {
							switch -exact -- [set cmd [lindex [split $text] 1]] {
								"on" - "enable" {
									if {$q} {
										putserv "NOTICE $nickname :$channel topic Q is already enabled."
									} else {
										channel set $channel +service_topic_Q
										putserv "NOTICE $nickname :$channel topic Q is now enabled."
									}
								}
								"off" - "disable" {
									if {!$q} {
										putserv "NOTICE $nickname :$channel topic Q is already disabled."
									} else {
										channel set $channel -service_topic_Q
										putserv "NOTICE $nickname :$channel topic Q is now disabled."
									}
								}
								"status" {
									putserv "NOTICE $nickname :$channel topic Q is: \002[expr {$q == "1" ? "enabled" : "disabled"}]\002."
								}
								"default" {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option on|off|status."
								}
							}
						}
						"save" {
							switch -exact -- [set cmd [lindex [split $text] 1]] {
								"on" - "enable" {
									if {$save} {
										putserv "NOTICE $nickname :$channel topic save is already enabled."
									} else {
										channel set $channel +service_topic_save
										putserv "NOTICE $nickname :$channel topic save is now enabled."
									}
								}
								"off" - "disable" {
									if {!$save} {
										putserv "NOTICE $nickname :$channel topic save is already disabled."
									} else {
										channel set $channel -service_topic_save
										putserv "NOTICE $nickname :$channel topic Q is now disabled."
									}
								}
								"status" {
									putserv "NOTICE $nickname :$channel topic save is: \002[expr {$save == "1" ? "enabled" : "disabled"}]\002."
								}
								"default" {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option on|off|status."
								}
							}
						}
						"force" {
							switch -exact -- [set cmd [lindex [split $text] 1]] {
								"on" - "enable" {
									if {$force} {
										putserv "NOTICE $nickname :$channel topic force is already enabled."
									} else {
										channel set $channel +service_topic_force
										putserv "NOTICE $nickname :$channel topic force is now enabled."
									}
								}
								"off" - "disable" {
									if {!$force} {
										putserv "NOTICE $nickname :$channel topic force is already disabled."
									} else {
										channel set $channel -service_topic_force
										putserv "NOTICE $nickname :$channel topic force is now disabled."
									}
								}
								"status" {
									putserv "NOTICE $nickname :$channel topic force is: \002[expr {$force == "1" ? "enabled" : "disabled"}]\002."
								}
								"default" {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command $option on|off|status."
								}
							}
						}
						"status" {
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
						}
						"default" {
							putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command skin|keyword|preview|set|Q|save|force|status ?arguments?."
						}
					}
				}
				"chanlev" {
					if {![matchattr $handle ADnm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set who [lindex [split $text] 0]
					set flags [lindex [split $text] 1]
					if {$who == "" || $flags == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command <nickname|#authname> <+-flags>."
					} elseif {[string equal -nocase $botnick $who]} {
						putserv "NOTICE $nickname :ERROR: You can't modify my own chanlev!"
					} elseif {![regexp -nocase -- {\+|\-} $flags]} {
						putserv "NOTICE $nickname :Invalid flags format. You need to indicate a + and/or - sign."
					} elseif {![onchan Q $channel]} {
						putserv "NOTICE $nickname :ERROR: Q is not present on $channel."
					} else {
						putserv "PRIVMSG Q :CHANLEV $channel $who $flags"
						putserv "NOTICE $nickname :Done."
					}
				}
				"autolimit" {
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set limit [lindex [split $text] 0]
					if {$limit == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|status|#limit."
					} else {
						set status [channel get $channel service_autolimit]
						switch -exact -- $limit {
							"on" {
								if {$status} {
									putserv "NOTICE $nickname :$channel autolimit is already enabled."
								} else {
									channel set $channel +service_autolimit
									channel set $channel service_limit "10"
									set curr [llength [chanlist $channel]]
									set newlimit [expr {$curr + 10}]
									pushmode $channel +l $newlimit
									putserv "NOTICE $nickname :Done."
								}
							}
							"off" {
								if {!$status} {
									putserv "NOTICE $nickname :$channel autolimit is already disabled."
								} else {
									channel set $channel -service_autolimit
									channel set $channel service_limit ""
									putserv "NOTICE $nickname :Done."
								}
							}
							"status" {
								if {$status} {
									putserv "NOTICE $nickname :$channel autolimit is enabled."
									putserv "NOTICE $nickname :Current setting: #[channel get $channel service_limit]."
								} else {
									putserv "NOTICE $nickname :$channel autolimit is disabled."
								}
							}
							"default" {
								if {[string index $limit 0] == "#"} {
									set limit [string trimleft $limit #]
									if {$limit < 3} {
										putserv "NOTICE $nickname :The limit must be 3 or higher."
									} elseif {[channel get $channel service_limit] == $limit} {
										putserv "NOTICE $nickname :The new limit must be different from the current limit."
									} else {
										channel set $channel service_limit "$limit"
										if {[string match *l* [getchanmode $channel]]} {
											if {[string match *k* [getchanmode $channel]]} {
												set curr [lindex [split [getchanmode $channel]] 2]
											} else {
												set curr [lindex [split [getchanmode $channel]] 1]
											}
											set newlimit [expr {[llength [chanlist $channel]] + $limit}]
											if {$newlimit != "$curr"} {
												pushmode $channel +l $newlimit
											}
										} else {
											pushmode $channel +l [expr {[llength [chanlist $channel]] + $limit}]
										}
										putserv "NOTICE $nickname :New limit successfully set to: #$limit."
									}
								} else {
									putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command on|off|status|#limit."
								}
							}
						}
					}
				}
				"addchan" - "join" - "+chan" {
					if {![matchattr $handle nm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {[set chan [lindex [split $text] 0]] == "" || [string index $chan 0] != "#"} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command #channel."
					} elseif {[validchan $chan]} {
						putserv "NOTICE $nickname :$chan is already added to my channel list."
					} elseif {[llength [channels]] >= "20"} {
						putserv "NOTICE $nickname :Im full up! I have ([llength [channels]]/20) channels in my list."
					} else {
						channel add $chan
						chattr $handle |+amnov $chan
						putserv "NOTICE $nickname :Channel ($chan) successfully added to my channel list."
					}
				}
				"delchan" - "remchan" - "part" - "-chan" {
					if {![matchattr $handle nm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {[set chan [lindex [split $text] 0]] == "" || [string index $chan 0] != "#"} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command #channel."
					} elseif {![validchan $chan]} {
						putserv "NOTICE $nickname :$chan is not added to my channel list."
					} else {
						channel remove $chan
						putserv "NOTICE $nickname :Channel ($chan) successfully removed from my channel list."
					}
				}
				"channels" {
					if {![matchattr $handle nm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set on 0
					set active 0
					set inactive 0
					set users 0
					set op 0
					set voice 0
					set reg 0
					set result ""
					foreach c [channels] {
						set status ""
						set count ""
						set services ""
						if {[botonchan $c]} {
							incr on 1
						}
						if {[channel get $c inactive]} {
							incr inactive 1
						} else {
							incr active 1
						}
						if {[botisop $c]} {
							incr op 1
							set status "@"
						} elseif {[botisvoice $c]} {
							incr voice 1
							set status "+"
						} else {
							incr reg 1
							set status ""
						}
						incr users [set count [llength [chanlist $c]]]
						if {[set services [getnetworkservices $c]] == ""} {
							set services "None"
						}
						if {[botonchan $c]} {
							lappend result "${status}${c} \(Channel Count: $count user(s) - Userlist Count: [llength [userlist |almnov $c]] user(s) - Channel Service(s): [join $services ", "]\)"
						} else {
							lappend result "${c} \(currently not on $c\)"
						}
					}
					puthelp "NOTICE $nickname :Channels Count: \([llength [channels]]/20\) channel(s). Im currently on $on of these channels. Statistics (Active on $active - Inactive on $inactive - Operator on $op - Voice on $voice, Regular on $reg - Total user count of all channels: $users user(s))."
					if {[string equal -nocase "-list" [lindex $text 0]]} {
						puthelp "NOTICE $nickname :[join $result " - "]"
					} else {
						foreach line $result {
							if {$line == ""} { return }
							puthelp "NOTICE $nickname :$line"
						}
					}
					puthelp "NOTICE $nickname :Im using [format %.0f [expr (([llength [channels]].0 * 100.0) / 20.0)]]% of my total channel capacity."
				}
				"hop" {
					if {![matchattr $handle nm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set chan [lindex [split $text] 0]
					if {$chan == "" || [string index $chan 0] != "#"} {
						putserv "NOTICE $nickname :Usage: ${lastbind}$command ?#channel?."
					} elseif {![validchan $chan]} {
						putserv "NOTICE $nickname :Channel '$chan' is not a valid channel."
					} else {
						if {[botonchan $chan]} {
							putserv "PART $chan"
						}
						putserv "JOIN $chan"
						putserv "NOTICE $nickname :Successfully hop'd on $chan."
					}
				}
				"peak" {
					set status [channel get $channel service_peak]
					if {![matchattr $handle ADnm|nm $channel]} {
						if {$status} {
							putserv "NOTICE $nickname :The current peak for $channel is [channel get $channel service_peak_count]. It was set on [clock format [set ts [channel get $channel service_peak_time]]] ([duration [expr {[clock seconds]-$ts}]] ago) by [channel get $channel service_peak_nick]."
						} else {
							putserv "NOTICE $nickname :Peak is currently disabled for $channel."
						}
						return
					}
					set scmd [string tolower [lindex [split $text] 0]]
					switch -exact -- $scmd {
						"on" {
							if {$status} {
								putserv "NOTICE $nickname :Peak for $channel is already enabled."
							} else {
								channel set $channel +service_peak
								putserv "NOTICE $nickname :Peak for $channel is now enabled."
								if {[set peak [channel get $channel service_peak_count]]>=[llength [chanlist $channel]] && [set ts [channel get $channel service_peak_time]]>0 && [set by [channel get $channel service_peak_nick]] != ""} {
									putserv "NOTICE $nickname :Restoring saved peak stats for ${channel}. (Peak $peak by $by on [clock format $ts] ([duration [expr {[clock seconds]-$ts}]]))"
									putserv "PRIVMSG $channel :Restoring saved peak stats for ${channel}. (Peak $peak by $by on [clock format $ts] ([duration [expr {[clock seconds]-$ts}]]))"
								} else {
									channel set $channel service_peak_count [set peak [llength [chanlist $channel]]]
									channel set $channel service_peak_time [set ts [clock seconds]]
									array set x {}
									foreach user [chanlist $channel] {
										if {$user == ""} { continue }
										if {[set jt [getchanjoin $user $channel]]>0} {
											lappend x($jt) $user
										}
									}
									set jt [lindex [split [lsort [array names x]]] 0]
									if {$jt == ""} {
										channel set $channel service_peak_nick [set by $nickname]
									} elseif {[llength $x($jt)]>1} {
										channel set $channel service_peak_nick [set by [lindex [split $x($jt)] [rand [llength $x($jt)]]]]
									} else {
										channel set $channel service_peak_nick [set by $x($jt)]
									}
									putserv "NOTICE $nickname :Set peak stats for ${channel}. (Peak $peak by $by on [clock format $ts] ([duration [expr {[clock seconds]-$ts}]]))"
									putserv "PRIVMSG $channel :Set peak stats for ${channel}. (Peak $peak by $by on [clock format $ts] ([duration [expr {[clock seconds]-$ts}]]))"
								}
							}
						}
						"off" {
							if {!$status} {
								putserv "NOTICE $nickname :Peak for $channel is already disabled."
							} else {
								channel set $channel -service_peak
								putserv "NOTICE $nickname :Peak for $channel is now disabled."
							}
						}
						"reset" {
							if {!$status} {
								putserv "NOTICE $nickname :Error: Peak is not enabled for $channel."; return
							}
							set peak [llength [chanlist $channel]]
							set ts [clock seconds]
							set by $nickname
							channel set $channel service_peak_count $peak
							channel set $channel service_peak_time $ts
							channel set $channel service_peak_nick $by
							putserv "NOTICE $nickname :Peak stats reset for ${channel}. (Peak $peak by $by on [clock format $ts] ([duration [expr {[clock seconds]-$ts}]]))"
							putserv "PRIVMSG $channel :Peak stats reset for ${channel}. (Peak $peak by $by on [clock format $ts] ([duration [expr {[clock seconds]-$ts}]]))"
						}
						"default" {
							if {$scmd == ""} {
								if {$status} {
									putserv "NOTICE $nickname :The current peak for $channel is [channel get $channel service_peak_count]. It was set on [clock format [set ts [channel get $channel service_peak_time]]] ([duration [expr {[clock seconds]-$ts}]] ago) by [channel get $channel service_peak_nick]."
								} else {
									putserv "NOTICE $nickname :Peak is currently disabled for $channel."
								}
							} else {
								putserv "NOTICE $nickname :Syntax: ${lastbind}${command} on|off|reset."
							}
						}
					}
				}
				"tcl" - "debug" {
					if {![matchattr $handle ADn|]} { return }
					#putserv "NOTICE $nickname :Please use '${::botnick}:: ?options? <code>' instead."
					debug::onchanmsg $nickname $hostname $handle $channel $text "${lastbind}${command}"
					return 0
				}
				"errorinfo" {
					variable tcldebug
					if {![matchattr $handle [lindex [split $tcldebug] 0]]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					array set options {
						{clear} {0}
						{notice} {0}
						{quick} {0}
					}
					for {set i 0; set unknown [list]; set tonick $text} {$i < [llength $text]} {incr i} {
						set opt [lindex [split $text] $i]
						if {$opt eq "--"} { break }
						if {[string equal -nocase "-c" $opt] || [string equal -nocase "--clear" $opt]} {
							set options(clear) [expr {1-$options(clear)}]; set tonick [lreplace $text $i $i]
						} elseif {[string equal -nocase "-n" $opt] || [string equal -nocase "--notice" $opt]} {
							set options(notice) [expr {1-$options(notice)}]; set tonick [lreplace $text $i $i]
						} elseif {[string equal -nocase "-q" $opt] || [string equal -nocase "--quick" $opt]} {
							set options(quick) [expr {1-$options(quick)}]; set tonick [lreplace $text $i $i]
						} elseif {[string range $opt 0 1] eq "--"} {
							lappend unknown [string range $opt 2 end]
						}
					}
					if {[llength $unknown] >= 1} {
						putserv "NOTICE $nickname :ERROR: Unknown option(s) specified: [join $unknown ", "]. (Available options: [lsort [join [array names options] ", "]])"; return
					}
					if {![info exists ::errorInfo]} {
						putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] No errorInfo set."; return
					}
					if {$options(clear)} {
						catch {unset ::errorInfo}
						putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] errorInfo cleared."; return
					}
					if {[llength [split $::errorInfo \n]] > 1} {
						if {$options(quick)} {
							putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] Multi-line error:"
						} else {
							puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] Multi-line error:"
						}	
						foreach line [split $::errorInfo \n] {
							if {$line eq ""} { continue }
							if {$options(quick)} {
								putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :$line"
							} else {
								puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :$line"
							}
						}
						if {$options(quick)} {
							putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] End of multi-line error."
						} else {
							puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] End of multi-line error."
						}
					} else {
						if {$options(quick)} {
							putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] $result"
						} else {
							puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] $result"
						}
					}
				}					
				"kick" {
					variable kickmsg; variable defaultreason
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set who [lindex [split $text] 0]
					set reason [lrange $text 1 end]
					if {$who == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command nickname \?reason\?."
					} elseif {![onchan $who $channel]} {
						putserv "NOTICE $nickname :$who isn't on $channel."
					} elseif {![botisop $channel]} {
						putserv "NOTICE $nickname :I need op to do that!"
					} elseif {[isbotnick $who]} {
						putserv "NOTICE $nickname :You can't kick me!"
					} elseif {[isnetworkservice $who]} {
						putserv "NOTICE $nickname :You can't kick a network service!"
					} else {
						if {[channel get $channel service_kickmsg_kick] == ""} {
							channel set $channel service_kickmsg_kick "$kickmsg(userkick)"
						}
						channel set $channel service_kid "[expr {[channel get $channel service_kid] + 1}]"
						set kmsg [channel get $channel service_kickmsg_kick]
						set id [channel get $channel service_kid]
						regsub -all :nickname: $kmsg $nickname kmsg
						regsub -all :channel: $kmsg $channel kmsg
						if {$reason == ""} {
							regsub -all :reason: $kmsg "$defaultreason" kmsg
						} else {
							regsub -all :reason: $kmsg "$reason" kmsg
						}
						regsub -all :id: $kmsg $id kmsg
						putquick "KICK $channel $who :$kmsg"
					}
				}
				"ban" - "kb" {
					variable kickmsg; variable defaultreason
					if {![matchattr $handle ADnm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set mask [lindex [split $text] 0]
					set time [lindex [split $text] 1]
					set reason [lrange $text 2 end]
					if {$mask == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command nickname|hostname ?bantime? ?reason?. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
						return
					}
					if {[regexp {(.+)!(.+)@(.+)} $mask]} {
						if {![regexp {[\d]{1,}(m|h|d|w|y)|^0$} $time]} {
							#putserv "NOTICE $nickname :No bantime specified. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
							set time "1h"
							set reason [lrange $text 1 end]
						}
						if {$mask == "*!*@*" || $mask == "*!*@" || $mask == "*!**@" || $mask == "*!**@*"} {
							putserv "NOTICE $nickname :Invalid banmask '$mask'."
						} elseif {[matchattr [set hand [host2hand $mask]] ADnm] && ![matchattr $handle ADn]} {
							putserv "NOTICE $nickname :You are not allowed to ban my bot owner/master."
						} elseif {[matchattr $hand |n $channel] && ![matchattr $handle |n $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel owner."
						} elseif {[matchattr $hand |m $channel] && ![matchattr $handle |n $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel master."
						} elseif {[matchattr $hand |o $channel] && ![matchattr $handle |nm $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel operator."
						} elseif {[matchattr $hand |v $channel] && ![matchattr $handle |nmo $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel voice."
						} elseif {[matchattr $hand N]} {
							putserv "NOTICE $nickname :You can't ban a protected nick/user."
						} elseif {[isban $mask $channel]} {
							putserv "NOTICE $nickname :Banmask '$mask' is already banned on $channel."
						} else {
							if {[channel get $channel service_kickmsg_ban] == ""} {
								channel set $channel service_kickmsg_ban "$kickmsg(userban)"
							}
							channel set $channel service_kid "[set id [expr {[channel get $channel service_kid] + 1}]]"
							set kmsg [channel get $channel service_kickmsg_ban]
							regsub -all :nickname: $kmsg $nickname kmsg
							regsub -all :channel: $kmsg $channel kmsg
							if {$reason == ""} {
								regsub -all :reason: $kmsg "$defaultreason" kmsg
							} else {
								regsub -all :reason: $kmsg "$reason" kmsg
							}
							regsub -all :bantime: $kmsg $time kmsg
							regsub -all :id: $kmsg $id kmsg
							putquick "MODE $channel +b $mask"
							newchanban $channel $mask $handle "$kmsg" [expr {[set bt [tduration $time]]/60}]
							if {$time == "0"} {
								putserv "NOTICE $nickname :Banmask ($mask) added to my banlist (Expires: Never!)."
							} else {
								putserv "NOTICE $nickname :Banmask ($mask) added to my banlist for $time (Expires: [clock format [expr {[unixtime]+$bt}] -format "%a %d %b %Y at %H:%M:%S %Z"])."
							}
						}
					} elseif {![onchan $mask $channel]} {
						putserv "NOTICE $nickname :$mask isn't on $channel."
					} elseif {[string equal -nocase $botnick $mask]} {
						putserv "NOTICE $nickname :You can't ban me!"
					} else {
						if {![regexp {[\d]{1,}(m|h|d|w|y)|^0$} $time]} {
							#putserv "NOTICE $nickname :No bantime specified. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
							set time "1h"
							set reason [lrange $text 1 end]
						}
						if {[matchattr [set hand [nick2hand $mask]] ADnm] && ![matchattr $handle ADn]} {
							putserv "NOTICE $nickname :You are not allowed to ban my bot owner/master."
						} elseif {[matchattr $hand |n $channel] && ![matchattr $handle |n $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel owner."
						} elseif {[matchattr $hand |m $channel] && ![matchattr $handle |n $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel master."
						} elseif {[matchattr $hand |o $channel] && ![matchattr $handle |nm $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel operator."
						} elseif {[matchattr $hand |v $channel] && ![matchattr $handle |nmo $channel]} {
							putserv "NOTICE $nickname :You don't have enough access to ban a channel voice."
						} elseif {[matchattr $hand N]} {
							putserv "NOTICE $nickname :You can't ban a protected nick/user."
						} else {
							if {[string match -nocase *users.quakenet.org [set host *!*[string trimleft [getchanhost $mask $channel] ~]]]} {
								set host *!*@[lindex [split $host @] 1]
							}
							if {[channel get $channel service_kickmsg_ban] == ""} {
								channel set $channel service_kickmsg_ban "$kickmsg(userban)"
							}
							channel set $channel service_kid "[set id [expr {[channel get $channel service_kid] + 1}]]"
							set kmsg [channel get $channel service_kickmsg_ban]
							regsub -all :nickname: $kmsg $nickname kmsg
							regsub -all :channel: $kmsg $channel kmsg
							if {$reason == ""} {
								regsub -all :reason: $kmsg "$defaultreason" kmsg
							} else {
								regsub -all :reason: $kmsg "$reason" kmsg
							}
							regsub -all :bantime: $kmsg $time kmsg
							regsub -all :id: $kmsg $id kmsg
							putquick "MODE $channel +b $host"
							putquick "KICK $channel $mask :$kickmsg"
							newchanban $channel $host $handle "$kmsg" [expr {[set bt [tduration $time]]/60}]
							if {$time == "0"} {
								putserv "NOTICE $nickname :$mask ($host) added to my banlist (Expires: Never!)."
							} else {
								putserv "NOTICE $nickname :$mask ($host) added to my banlist for $time (Expires: [clock format [expr {[unixtime]+$bt}] -format "%a %d %b %Y at %H:%M:%S %Z"])."
							}
						}
					}
				}
				"unban" - "ub" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set mask [lindex [split $text] 0]
					if {$mask == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command #id|hostname."
					} elseif {$mask == "\*" || [string equal -nocase all $mask]} {
						putserv "NOTICE $nickname :To unbanall, please use the '${lastbind}banclear' command (To unban all permbans too, please use '${lastbind}banclear all')." 
					} elseif {[regexp {^#[0-9]{1,}$} $mask]} {
						set mask [string trimleft $mask #]
						if {[llength [banlist $channel]] == "0"} {
							putserv "NOTICE $nickname :No registered bans for $channel."
						} elseif {$mask == "0" || $mask > [llength [banlist $channel]]} {
							putserv "NOTICE $nickname :Invalid ban id #$mask."
						} else {
							set id "0"
							set ban "0"
							foreach bann [banlist $channel] {
								if {$bann == ""} { return }
								incr id
								if {$id == $mask} {
									set ban [lindex $bann 0]
								}
							}
							if {$ban == "0"} {
								putserv "NOTICE $nickname :Ban ID #$mask does not exist."
							} elseif {[killchanban $channel $ban]} {
								putserv "NOTICE $nickname :Ban ID #$mask ($ban) successfully removed from $channel banlist."
								if {[ischanban $channel $ban] && [botisop $channel]} {
									pushmode $channel -b $ban
									flushmode $channel
								}
							} else {
								putserv "NOTICE $nickname :Error removing ban id #$mask ($ban) from $channel banlist."
							}
						}
					} elseif {[regexp {(.+)!(.+)@(.+)} $mask]} {
						set found "0"
						foreach ban [banlist $channel] {
							if {[string match -nocase $mask [lindex $ban 0]]} {
								set found 1
								break
							}
						}
						if {$found} {
							if {[killchanban $channel $mask]} {
								putserv "NOTICE $nickname :Banmask $mask successfully removed from $channel banlist."
								if {[ischanban $channel $mask] && [botisop $channel]} {
									pushmode $channel -b $mask
									flushmode $channel
								}
							}
						} else {
							set found "0"
							foreach chanban [chanbans $channel] {
								if {[string match -nocase $mask [lindex $chanban 0]]} {
									set found 1
									break
								}
							}
							if {$found} {
								if {![botisop $channel]} {
									putserv "NOTICE $nickname :I need op to unban $mask."
								} else {
									pushmode $channel -b $mask
									flushmode $channel
									putserv "NOTICE $nickname :Channel ban $mask removed."
								}
							} else {
								putserv "NOTICE $nickname :Banmask $mask does not exist."
							}
						}
					}
				}
				"banlist" - "bl" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTIVE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {$text == ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command -global|-all|-perm|-temp|-chan."; return }
					array set options {
						{global} {0}
						{all} {0}
						{perm} {0}
						{temp} {0}
						{chan} {0}
					}
					foreach option [split $text " "] {
						if {$option == ""} { continue }
						if {[string equal -nocase -global $option]} {
							set options(global) 1
						} elseif {[string equal -nocase -all $option]} {
							set options(all) 1
						} elseif {[string equal -nocase -perm $option]} {
							set options(perm) 1
						} elseif {[string equal -nocase -temp $option]} {
							set options(temp) 1
						} elseif {[string equal -nocase -chan $option]} {
							set options(chan) 1
						} else {
							putserv "NOTICE $nickname :ERROR: Invalid option '$option' specified. (Valid options are: -global|-all|-perm|-temp|-chan)"; return
						}
					}
					if {$options(global)} {
						if {![matchattr $handle nm]} { return }
						if {$options(chan)} {
							putserv "NOTICE $nickname :ERROR: Invalid option '-chan' specified with '-global' option."; return
						}
						if {($options(perm) == "0" && $options(temp) == "0") && !$options(all)} {
							putserv "NOTICE $nickname :ERROR: Please specify '-perm', '-temp' or '-all' along with '-global' option."; return
						}	
						if {[llength [banlist]]<=0} {
							putserv "NOTICE $nickname :There are no global bans."; return
						}
						putserv "NOTICE $nickname :#ID - Banmask - Creator - Expire Time:"
						set id 0; set perm 0; set nonperm 0
						foreach ban [banlist] {
							if {$ban == ""} { continue }
							incr id
							# 0 = mask / 5 = creator - 2 = expirets
							set mask [lindex $ban 0]; set creator [lindex $ban 5]; set expirets [lindex $ban 2]
							if {[ispermban $mask] && ($options(perm) || $options(all))} {
								incr perm
								putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
							} elseif {![ispermban $mask] && ($options(temp) || $options(all))} {
								incr nonperm
								putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
							}
						}
						putserv "NOTICE $nickname :End of global banlist (Total: $id Permanent: $perm Non-permanent: $nonperm)."
					} else {
						if {($options(perm) == "0" && $options(temp) == "0" && $options(chan) == "0") && !$options(all)} {
							putserv "NOTICE $nickname :ERROR: Please specify '-perm', '-temp', '-chan' or '-all'."; return
						}
						if {$options(chan) || $options(all)} {
							# {*!*@test.com r0t3n!r0t3n@away.users.quakenet.org 14} {*!*@test1.com Q!TheQBot@CServe.quakenet.org 5}
							set cb 0
							putserv "NOTICE $nickname :#ID - Banmask - Creator - Created:"
							foreach ban [chanbans $channel] {
								if {$ban == ""} { continue }
								set mask [lindex $ban 0]; set creator [lindex $ban 1]; set created [lindex $ban 2]
								if {![isban $ban $channel] && ($options(chan) || $options(all))} {
									incr cb
									putserv "NOTICE $nickname :#$cb - $mask - $creator - [clock format [expr {[clock seconds]-$created}] -format "%a %d %b %Y at %H:%M:%S %Z"] ([duration $created] ago)."
								}
							}
							putserv "NOTICE $nickname :End of $channel external-banlist (Total: $cb)."
						}
						if {$options(perm) || $options(temp) || $options(all)} {
							if {[llength [banlist $channel]]<=0} {
								putserv "NOTICE $nickname :There are no $channel bans."; return
							}
							putserv "NOTICE $nickname :#ID - Banmask - Creator - Expire Time:"
							set id 0; set perm 0; set nonperm 0
							foreach ban [banlist $channel] {
								if {$ban == ""} { continue }
								incr id
								# 0 = mask / 5 = creator - 2 = expirets
								set mask [lindex $ban 0]; set creator [lindex $ban 5]; set expirets [lindex $ban 2]
								if {[ispermban $mask] && ($options(perm) || $options(all))} {
									incr perm
									putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
								} elseif {![ispermban $mask] && ($options(temp) || $options(all))} {
									incr nonperm
									putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
								}
							}
							putserv "NOTICE $nickname :End of $channel internal-banlist (Total: $id Permanent: $perm Non-permanent: $nonperm)."
						}
					}
				}
				"baninfo" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					# if hostmask, check global before channel				
					# if #id check for -global or -chan option				
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {$text == ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command -global|-chan #id|hostmask."; return }
					array set options {
						{global} {0}
						{chan} {0}
					}
					set mask ""; set id 0
					foreach option [split $text " "] {
						if {$option == ""} { continue }
						if {[string index $option 0] == "-"} {
							set option [string range $option 1 end]
							if {[string equal -nocase "global" $option]} {
								set options(global) 1
							} elseif {[string equal -nocase "chan" $option]} {
								set options(chan) 1
							}
						} elseif {$mask == ""} {
							set mask $option
						}
					}
					if {[string index $mask 0] == "#" && (![string is integer [set  id [string range $mask 1 end]]] || $id<=0)} {
						putserv "NOTICE $nickname :ERROR: #ID must be an integer greater than 0."; return
					}
					if {$id>=1 && (!$options(global) || !$options(chan))} {
						putserv "NOTICE $nickname :ERROR: You need to supply the '-global' or '-chan' option along with #id."; return
					} elseif {![regexp {(.+)!(.+)@(.+)} $mask]} {
						putserv "NOTICE $nickname :ERROR: Invalid banmask '$mask' specified."; return
					}
					# 0 = mask / 5 = creator / 3 = createdts / 2 = expirets
					if {$options(global)} {
						if {![matchattr $handle ADnm]} { return }
						set i 0; set f 0
						foreach ban [banlist] {
							if {$ban == ""} { continue }
							incr i
							if {$i == $id || [string equal -nocase $mask [lindex $ban 0]]} {
								set f 1; set bmask [lindex $ban 0]; set creator [lindex $ban 5]; set createdts [lindex $ban 3]; set expirets [lindex $ban 2]; set reason [lindex $ban 1]
								putserv "NOTICE $nickname :(#$i) - Banmask: $bmask - Created by: $creator on [clock format $createdts -format "%a %d %b %Y at %H:%M:%S %Z"] - Expires: [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format [lindex $ban 2] -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }] - Reason: ${reason}."
								break
							}
						}
						if {!$f} {
							putserv "NOTICE $nickname :Global ban [expr {$id>0 ? "id '#$id'" : "mask '$mask'"}] does not exist."; return
						}
					} elseif {$options(chan)} {
						set i 0; set f 0
						foreach ban [banlist $channel] {
							if {$ban == ""} { continue }
							incr i
							if {$i == $id || [string equal -nocase $mask [lindex $ban 0]]} {
								set f 1; set bmask [lindex $ban 0]; set creator [lindex $ban 5]; set createdts [lindex $ban 3]; set expirets [lindex $ban 2]; set reason [lindex $ban 1]
								putserv "NOTICE $nickname :(#$i) - Banmask: $bmask - Created by: $creator on [clock format $createdts -format "%a %d %b %Y at %H:%M:%S %Z"] - Expires: [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format [lindex $ban 2] -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }] - Reason: ${reason}."
								break
							}
						}
						if {!$f} {
							putserv "NOTICE $nickname :$channel ban [expr {$id>0 ? "id '#$id'" : "mask '$mask'"}] does not exist."; return
						}
					} else {
						set i 0; set f 0
						foreach ban [banlist] {
							if {$ban == ""} { continue }
							incr i
							if {[string equal -nocase $mask [lindex $ban 0]]} {
								set f 1; set bmask [lindex $ban 0]
								if {![matchattr $handle ADnm]} {
									putserv "NOTICE $nickname :You do not have the required privileges to view the global ban information for '$mask'."; break
								} else {								
									set creator [lindex $ban 5]; set createdts [lindex $ban 3]; set expirets [lindex $ban 2]; set reason [lindex $ban 1]
									putserv "NOTICE $nickname :Global (#$i) - Banmask: $bmask - Created by: $creator on [clock format $createdts -format "%a %d %b %Y at %H:%M:%S %Z"] - Expires: [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format [lindex $ban 2] -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }] - Reason: ${reason}."
									break
								}
							}
						}
						set i 0
						foreach ban [banlist $channel] {
							if {$ban == ""} { continue }
							incr i
							if {[string equal -nocase $mask [lindex $ban 0]]} {
								set f 1; set bmask [lindex $ban 0]; set creator [lindex $ban 5]; set createdts [lindex $ban 3]; set expirets [lindex $ban 2]; set reason [lindex $ban 1]
								putserv "NOTICE $nickname :$channel (#$i) - Banmask: $bmask - Created by: $creator on [clock format $createdts -format "%a %d %b %Y at %H:%M:%S %Z"] - Expires: [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format [lindex $ban 2] -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }] - Reason: ${reason}."
								break
							}
						}
						if {!$f} {
							putserv "NOTICE $nickname :Banmask '$mask' does not exist in my banlists."; return
						}
					}					
				}
				"banclear" - "bc" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTIVE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {$text == ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command -global|-all|-list|-perm|-temp|-chan|#MINUTES (if #MINUTES is specified, only bans added <= MINUTES ago will be removed)."; return }
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
				"gban" - "gb" {
					variable homechan; variable adminchan; variable kickmsg
					if {![matchattr $handle nm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set mask [lindex [split $text] 0]
					set time [lindex [split $text] 1]
					set reason [lrange $text 2 end]
					if {$mask == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command nickname|hostname ?bantime? ?reason?. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
						return
					}
					if {[regexp {(.+)!(.+)@(.+)} $mask]} {
						if {![regexp {[\d]{1,}(m|h|d|w|y)|^0$} $time]} {
							#putserv "NOTICE $nickname :No bantime specified. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
							set time "1h"
							set reason [lrange $text 1 end]
						}
						if {$mask == "*!*@*" || $mask == "*!*@" || $mask == "*!**@" || $mask == "*!**@*"} {
							putserv "NOTICE $nickname :Invalid banmask '$mask'."
						} elseif {[matchattr [set hand [host2hand $mask]] nm] && ![matchattr $handle n]} {
							putserv "NOTICE $nickname :You are not allowed to ban my bot owner/master."
						} elseif {[matchattr $hand N]} {
							putserv "NOTICE $nickname :You can't global ban a protected nick/user."
						} elseif {[isban $mask]} {
							putserv "NOTICE $nickname :Banmask '$mask' is already global banned."
						} else {
							if {[channel get $adminchan service_kickmsg_gban] == ""} {
								channel set $adminchan service_kickmsg_gban "$kickmsg(gban)"
							}
							channel set $adminchan service_gkid "[set id [expr {[channel get $adminchan service_gkid] + 1}]]"
							set kmsg "$kickmsg(gban)"
							regsub -all :nickname: $kmsg $nickname kmsg
							regsub -all :channel: $kmsg $channel kmsg
							regsub -all :homechan: $kmsg $homechan kmsg
							if {$reason == ""} {
								regsub -all :reason: $kmsg "Violated $homechan rules!" kmsg
							} else {
								regsub -all :reason: $kmsg "$reason" kmsg
							}
							regsub -all :bantime: $kmsg $time kmsg
							regsub -all :id: $kmsg $id kmsg
							newban $mask $handle "$kmsg" [expr {[set bt [tduration $time]]/60}] none
							if {$time == "0"} {
								putserv "NOTICE $nickname :Banmask ($mask) added to my banlist (Expires: Never!)."
							} else {
								putserv "NOTICE $nickname :Banmask ($mask) added to my banlist for $time (Expires: [clock format [expr {[unixtime]+$bt}] -format "%a %d %b %Y at %H:%M:%S %Z"])."
							}
						}
					} elseif {![onchan $mask]} {
						putserv "NOTICE $nickname :$mask isn't on any of my channels."
					} else {
						if {![regexp {[\d]{1,}(m|h|d|w|y)|^0$} $time]} {
							#putserv "NOTICE $nickname :No bantime specified. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
							set time "1h"
							set reason [lrange $text 1 end]
						}
						if {[matchattr [set hand [nick2hand $mask]] nm] && ![matchattr $handle n]} {
							putserv "NOTICE $nickname :You are not allowed to ban my bot owner/master."
						} elseif {[matchattr $hand N]} {
							putserv "NOTICE $nickname :You can't global ban a protected nick/user."
						} else {
							if {[string match -nocase *users.quakenet.org [set host *![getchanhost $mask]]]} {
								set host *!*@[lindex [split $host @] 1]
							}
							if {[set kickmsg [channel get $adminchan service_kickmsg_gban]] == ""} {
								channel set $adminchan service_kickmsg_gban "[set kmsg $kickmsg(gban)]"
							}
							channel set $adminchan service_gkid "[set id [expr {[channel get $adminchan service_gkid] + 1}]]"
							regsub -all :nickname: $kmsg $nickname kmsg
							regsub -all :channel: $kmsg $channel kmsg
							regsub -all :homechan: $kmsg $homechan kmsg
							if {$reason == ""} {
								regsub -all :reason: $kmsg "Violated $homechan rules!" kmsg
							} else {
								regsub -all :reason: $kmsg "$reason" kmsg
							}
							regsub -all :bantime: $kmsg $time kmsg
							regsub -all :id: $kmsg $id kmsg
							foreach chan [channels] {
								if {[onchan $mask $chan] && [botisop $chan]} {
									putserv "MODE $chan +b $host"
									putserv "KICK $chan $mask :$kmsg"
									utimer 10 [list pushmode $chan -b $host]
								}
							}
							newban $host $handle "$kmsg" [expr {[set bt [tduration $time]]/60}] none
							if {$time == "0"} {
								putserv "NOTICE $nickname :$mask ($host) added to my banlist (Expires: Never!)."
							} else {
								putserv "NOTICE $nickname :$mask ($host) added to my banlist for $time (Expires: [clock format [expr {[unixtime]+$bt}] -format "%a %d %b %Y at %H:%M:%S %Z"])."
							}
						}
					}
				}
				"gunban" - "gub" {
					if {![matchattr $handle nm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set mask [lindex [split $text] 0]
					if {$mask == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command #id|hostname."
					} elseif {[string index $mask 0] == "#" && [string is integer [set mask [string trimleft $mask #]]]} {
						if {[llength [banlist]] == "0"} {
							putserv "NOTICE $nickname :No registered global bans."
						} elseif {$mask == "0" || $mask > [llength [banlist]]} {
							putserv "NOTICE $nickname :Invalid ban id #$mask."
						} else {
							set id "0"
							set ban "0"
							foreach bann [banlist] {
								if {$bann == ""} { return }
								incr id
								if {$id == $mask} {
									set ban [lindex $bann 0]
								}
							}
							if {$ban == "0"} {
								putserv "NOTICE $nickname :Ban ID #$mask does not exist."
							} elseif {[killban $ban]} {
								putserv "NOTICE $nickname :Ban ID #$mask ($ban) successfully removed from global banlist."
								if {[ischanban $channel $ban] && [botisop $channel]} {
									pushmode $channel -b $ban
								}
							} else {
								putserv "NOTICE $nickname :Error removing ban id #$mask ($ban) from global banlist."
							}
						}
					} elseif {[regexp {(.+)!(.+)@(.+)} $mask]} {
						set found "0"
						foreach ban [banlist] {
							if {[string match -nocase $mask [lindex $ban 0]]} {
								set found 1
								break
							}
						}
						if {$found} {
							if {[killban $mask]} {
								putserv "NOTICE $nickname :Banmask $mask successfully removed from global banlist."
								if {[ischanban $channel $mask] && [botisop $channel]} {
									pushmode $channel -b $mask
								}
							}
						} else {
							putserv "NOTICE $nickname :Banmask '$mask' does not exist."
						}
					}
				}
				"userlist" {
					if {![matchattr $handle nm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					
					
					if {$text == ""} { putserv "NOTICE $nickname :Syntax: ${lastbind}$command -global|-chan|-all|#level (where level is a bot defined user level)."; return }
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
				"say" {
					if {![matchattr $handle ADnm|nmo $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {$text == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command <messaege>."
					} else {
						putserv "PRIVMSG $channel :$text"
					}
				}
				"spam" - "broadcast" {
					variable homechan; variable adminchan; variable helpchan
					if {![matchattr $handle ADnm]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					if {$text == ""} {
						putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command <message>."
					} else {
						set list ""
						set id "0"
						foreach chan [channels] {
							if {$chan == ""} { return }
							if {![string equal -nocase $homechan $chan] && ![string equal -nocase $adminchan $chan] && ![string equal -nocase $helpchan $chan]} {
								puthelp "PRIVMSG $chan :\(broadcast\) $text"
								incr id 1
							}
						}
						putserv "NOTICE $nickname :Done. Broadcasted to ($id/[llength [channels]]) Successfully."
					}
				}
				"saveops" {
					variable saveops
					if {![matchattr $handle nm|nm $channel]} {
						puthelp "NOTICE $nickname :You have no access to this command."
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					array set options {
						{clear} {0}
						{save} {0}
						{op} {0}
						{list} {0}
					}
					foreach {opt} [split $text] {
						if {$opt eq ""} { continue }
						if {$opt eq "--"} { set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]; break }
						if {[string equal -nocase "-c" $opt] || [string equal -nocase "--clear" $opt]} {
							set options(clear) [expr {1-$options(clear)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
						} elseif {[string equal -nocase "-s" $opt] || [string equal -nocase "--save" $opt]} {
							set options(save) [expr {1-$options(save)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
						} elseif {[string equal -nocase "-o" $opt] || [string equal -nocase "--op" $opt]} {
							set options(op) [expr {1-$options(op)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
						} elseif {[string equal -nocase "-l" $opt] || [string equal -nocase "--list" $opt]} {
							set options(list) [expr {1-$options(list)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
						} elseif {[string index $opt 0] eq "-" || [string range $opt 0 1] eq "--"} {
							lappend unknown $opt; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
						}
					}
					if {[info exists unknown]} {
						putserv "NOTICE $nickname :Unknown option(s) specified: [join $unknown " "]. (Available options: --[join [lsort [array names options]] ", --"])"; return
					}
					if {$options(clear)} {
						set conflict [list]
						if {$options(save)} { lappend conflict "save" }
						if {$options(list)} { lappend conflict "list" }
						if {$options(op)} { lappend conflict "op" }
						if {[llength $conflict]>=1} {
							putserv "NOTICE $nickname :ERROR: Options Conflict - You can not use '[join [lsort $conflict] " "]' along with 'clear'."; return
						}
					}
					if {$options(list)} {
						set conflict [list]
						if {$options(save)} { lappend conflict "save" }
						if {$options(clear)} { lappend conflict "clear" }
						if {$options(op)} { lappend conflict "op" }
						if {[llength $conflict]>=1} {
							putserv "NOTICE $nickname :ERROR: Options Conflict - You can not use '[join [lsort $conflict] " "]' along with 'list'."; return
						}
					}
					set c 0; set ch [string tolower $channel]
					if {$options(clear)} {
						foreach e [array names saveops $ch:*] {
							if {$e eq ""} { continue }
							unset saveops($e); incr c
						}
						putserv "NOTICE $nickname :Cleared '$c' saved op(s) for $channel."; return
					}
					if {$options(list)} {
						putserv "NOTICE $nickname :Saved op(s) list for $channel:"
						foreach e [lsort [array names saveops $ch,*]] {
							if {$e eq ""} { continue }
							set ni [lindex [split [lindex [split $e ,] 1] !] 0]
							set ho [lindex [split [lindex [split $e ,] 1] !] 1]
							set ts $saveops($e)
							putserv "NOTICE $nickname :$ni ($ho) saved [clock format $ts] ([duration [expr {[clock seconds]-$ts}]] ago)"
							incr c
						}
						putserv "NOTICE $nickname :End of saved op(s) list for $channel. ($c saved op(s))."; return
					}
					if {$options(op)} {
						if {![botisop $channel]} {
							putserv "NOTICE $nickname :ERROR: I need op on $channel to (re)op saved op(s)."; return
						}
						set opli [list]
						foreach e [array names saveops $ch,*] {
							if {$e eq ""} { continue }
							set ni [lindex [split [lindex [split $e ,] 1] !] 0]
							set ho [lindex [split [lindex [split $e ,] 1] !] 1]
							if {[onchan $ni $channel] && [string equal -nocase $ho [string trimleft [getchanhost $ni $channel] ~]] && ![isop $ni $channel]} {
								lappend opli $ni; incr c
							}
							unset saveops($e)
							if {[llength $opli]==6} {
								putserv "MODE $channel +oooooo [join $opli " "]"; set opli [list]
							}
						}
						if {[llength $opli]>=1} {
							putserv "MODE $channel +[string repeat "o" [llength $opli]] [join $opli " "]"; unset opli
						}
						if {!$options(save)} {
							putserv "NOTICE $nickname :Op'd $c saved op(s) on $channel. Saved op(s) list cleared, please use ${lastbind}$command --save to save the current channel ops."; return
						} else {
							set cc $c
						}
					}
					if {$options(save)} {
						set ts [clock seconds]
						foreach ni [chanlist $channel] {
							if {$ni eq ""} { continue }
							if {[isbotnick $ni] || ![isop $ni $channel]} { continue }
							set ho [string trimleft [getchanhost $ni $channel] ~]
							set e ${ni}!${ho}
							if {[info exists saveops(${ch},${e})]} { continue }
							set saveops(${ch},${e}) $ts; incr c
						}
						if {$options(op) && [info exists cc]} {
							putserv "NOTICE $nickname :Op'd $cc saved op(s) on $channel. Saved $c op(s) for $channel."
						} else {
							putserv "NOTICE $nickname :Saved $c op(s) for $channel."
						}
						return
					}
					putserv "NOTICE $nickname :Syntax: ${lastbind}$command ?--options?. (Available options: --[join [lsort [array names options]] ", --"])"
				}
				"clearop" {
					onpubm $nickname $hostname $handle $channel "${lastbind}saveops --clear"			
				}
				"saveop" {
					onpubm $nickname $hostname $handle $channel "${lastbind}saveops --save"
				}
				"reop" {
					onpubm $nickname $hostname $handle $channel "${lastbind}saveops --op --save"
				}
				"auth" {
					if {![matchattr $handle ADnm]} {
						putserv "NOTICE $nickname :You dont have access to this command!"
						return
					}
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					### Recode ###
					putserv "NOTICE $nickname :Defunct -- Being reimplementated"; return
					### Recode ###
					if {[string match -nocase *users.quakenet.org $::botname]} {
						putserv "NOTICE $nickname :I'm already authed!"
					} elseif {![info exists ::qscript(auth)] || ![info exists ::qscript(pass)]} {
						putserv "NOTICE $nickname :Error: error trying to auth to Q..."
					} elseif {![string equal -nocase [join [lrange [split [lindex [split $::server :] 0] .] end-1 end] .] quakenet.org]} {
						putserv "NOTICE $nickname :Error: network/server does not end in 'quakenet.org'..."
					} else {
						putserv "NOTICE $nickname :Authing with Q... this may take a few seconds depending on queue times."
						puthelp "MODE $::botnick +ixR-ws"
						puthelp "AUTH :$::qscript(auth) $::qscript(pass)"
						puthelp "NOTICE $nickname :Sent auth to Q..."
					}
				}
				"commands" {
					variable trigger
					if {![validuser $handle]} { return }
					helper_xtra_set "lastcmd" $handle "$channel ${lastbind}$command $text"
					set trig [getuser $handle XTRA mytrigger]
					if {$trig == ""} {
						setuser $handle XTRA $trigger
						set trig "$trigger"
					}
					set chancmds [helper_list_channelcmds_byhandle $channel $handle]
					if {[llength $chancmds] <= 0} {
						putserv "NOTICE $nickname :You have no $channel commands available to you."
					} else {
						putserv "Notice $nickname :The following $channel commands are available to you: (trigger: $trig)"
						putserv "NOTICE $nickname :[join [split $chancmds " "] ", "]"
					}
					set globcmds [helper_list_globalcmds_byhandle $handle]
					if {[llength $globcmds] > 0} {
						putserv "NOTICE $nickname :The following global commands are available to you: (trigger: $trig)"
						putserv "NOTICE $nickname :[join [split $globcmds " "] ", "]"
					}
					putserv "NOTICE $nickname :End of commands list."
				}
				"help" {
					variable trigger; variable cmdhelp
					if {![validuser $handle]} { return }
					set trig [getuser $handle XTRA mytrigger]
					if {$trig == ""} {
						setuser $handle XTRA $trigger
						set trig "$trigger"
					}
					set command [string tolower [lindex [split $text] 0]]
					set tonick [string tolower [lindex [split $text] 1]]
					if {$tonick == ""} {
						if {[llength [array names cmdhelp]] <= 0} {
							putserv "NOTICE $nickname :ERROR: No help information available."; return
						}
						if {![helper_help_cmd_tonick $command $nickname]} {
							putserv "NOTICE $nickname :ERROR: Invalid command '$command'. Please use ${lastbind}commands to get a list of available commands to you."
						}
					} elseif {![onchan $tonick]} {
						putserv "NOTICE $nickname :ERROR: '$tonick' is not on any of my channels."
					} else {
						if {[llength [array names cmdhelp]] <= 0} {
							putserv "NOTICE $nickname :ERROR: No help information available."
							putserv "NOTICE $tonick :ERROR: No help information available."; return
						}
						if {![helper_help_cmd_tonick $command $tonick]} {
							putserv "NOTICE $nickname :ERROR: Invalid command '$command'. Please use ${lastbind}commands to get a list of available commands to you."
						} else {
							putserv "NOTICE $nickname :Done. Sent help information for '$command' to '$tonick'."
						}
					}
				}
				"default" {
					variable kickmsg
					if {[channel get $channel service_badword] && [set words [channel get $channel service_badwords]] != "" && ![matchattr $handle nm|nm $channel]} {
						set list [list]
						foreach word $text {
							if {$word == ""} { continue }
							if {[lsearch -exact [string tolower $words] [string tolower $word]] != -1} {
								lappend list $word
								putlog "detected badword $word from $nickname"
							}
						}
						if {[llength $list] == "0"} { return }
						if {[set kmsg [channel get $channel service_badword_kickmsg]] == ""} {
							channel set $channel service_badword_kickmsg "[set kmsg $kickmsg(badword)]"
						}
						channel set $channel service_bwkid "[set bwkid [expr {[channel get $channel service_bwkid] + 1}]]"
						channel set $channel service_bwid "[set bwid [expr {[channel get $channel service_bwid] + [llength $list]}]]"
						if {![botisop $channel]} { return }
						regsub -all :nickname: $kmsg "$nickname" kmsg
						regsub -all :hostname: $kmsg "$hostname" kmsg
						regsub -all :badword: $kmsg "[join $list ", "]" kmsg
						regsub -all :found: $kmsg "[llength $list]" kmsg
						regsub -all :channel: $kmsg "$channel" kmsg
						regsub -all :id: $kmsg "$bwkid" kmsg
						regsub -all :bid: $kmsg "$bwid" kmsg
						if {[string match -nocase *users.quakenet.org [set banmask *!*[string trimleft $hostname ~]]]} {
							set banmask *!*@[lindex [split $hostname @] 1]
						}
						putserv "MODE $channel -o+b $nickname $banmask"
						putserv "KICK $channel $nickname :$kmsg"
						if {[set bantime [channel get $channel service_badword_bantime]] == "0"} {
							channel set $channel service_badword_bantime "[set bantime 1]"
						}
						utimer [expr {$bantime * 60}] [list pushmode $channel -b $banmask]
					}
				}
			}
		}
		return 0
	}

	proc onquit {nickname hostname handle channel {info ""}} {
		if {[isbotnick $nickname]} {
			foreach user [userlist] {
				setuser $user XTRA loggedin 0
			}
		} elseif {![onchan $nickname]} {
			setuser $handle XTRA loggedin 0
		}
		return 0
	}
	
	proc automsg {min hour day month year} {
		foreach channel [channels] {
			if {$channel == "" || ![botonchan $channel] || ![channel get $channel service_automsg]} { continue }
			set interval [channel get $channel service_automsg_interval]
			set counter [expr {[channel get $channel service_automsg_counter]+1}]
			#putlog "automsg: $channel -> $counter => $interval"
			if {$counter>=$interval} {
				channel set $channel service_automsg_counter 0
			} else {
				channel set $channel service_automsg_counter $counter; continue
			}
			set messages [channel get $channel service_automsg_messages]
			if {[llength $messages]<=0} { continue }
			set last [channel get $channel service_automsg_last]
			set moderate [channel get $channel service_automsg_moderate]
			set method [string tolower [channel get $channel service_automsg_method]]
			set maps [channel get $channel service_automsg_maps]
			if {![string is integer $last]} { set last -1 }
			if {$last>[llength $messages]} { set last -1 }			
			if {$method eq "random" || $method eq "rand"} {
				incr last
				if {[llength $messages]==1} {
					set last 0
				} else {
					if {$last>[llength $messages]} { set last 1 }
					if {$last>=0} { set messages [lreplace $messages $last-1 $last-1] }
					if {[set id [expr {[rand [llength $messages]]-1}]]<0} { set last 0 }
					if {$id>[llength $messages]} { set id 0 }
				}
				channel set $channel service_automsg_last [set id $last]
				set message \{[lindex $messages $id]\}
			} elseif {$method eq "loop" || $method eq "line"} {
				incr last
				if {$last == [llength $messages]} {
					set id $last
					if {$id<0 || $id>[expr {[llength $messages]-1}]} {
						set id 0
					}
				} elseif {$last > [llength $messages]} {
					set id 0
				} else {
					set id $last
					if {$id<0 || $id>[expr {[llength $messages]-1}]} {
						set id 0
					}
				}
				channel set $channel service_automsg_last $id
				set message \{[lindex $messages $id]\}
			} elseif {$method eq "default" || $method eq "multi" || $method eq "block" || $method eq "all" || $method eq ""} {
				set last -1
				channel set $channel service_automsg_last [set id $last]
				set message $messages
			}
			set color 0; set strip 0
			foreach msg $message {
				if {$msg eq ""} { continue }
				if {[string length [stripcodes bcu $msg]]<[string length $msg]} {
					set color 1; break
				}
			}
			set pre [list]; set post [list]
			set modes [getchanmode $channel]
			if {$color && [string match "*c*" $modes]} {
				lappend pre -c; lappend post +c
			}
			if {$moderate && ![string match "*m*" $modes]} {
				lappend pre +m; lappend post -m
			}
			if {[botisop $channel] && [llength $pre]>0} {
				putserv "MODE $channel [join $pre ""]"
			} elseif {![botisop $channel] && [string match "*c*" $modes] && $color} {
				set strip 1
			}
			set maps [linsert [linsert $maps end ":botnick: $::botnick"] end ":channel: $channel"]
			foreach msg $message {
				if {$msg eq ""} { continue }
				if {$strip} { set msg [stripcodes bcu $msg] }
				if {[llength $maps]>=1} {
					set msg [string map [join $maps] $msg]
				}
				foreach msg_ [split $msg \n] {
					if {$msg eq ""} { continue }
					putserv "PRIVMSG $channel :$msg_"
				}
			}
			if {[botisop $channel] && [llength $post]>0} {
				putserv "MODE $channel [join $post ""]"
			}
		}
		return 0
	}

	proc hand2nicks {handle} {
		set nicks [list]
		foreach channel [channels] {
			if {$channel == ""} { continue }
			foreach nick [chanlist $channel] {
				if {$nick == "" || [set x [nick2hand $nick]] == "" || $x == "*"} { continue }
				if {[string equal -nocase $handle $x]} {
					lappend nicks $nick
				}
			}
		}
		return [lsort -unique $nicks]
	}

	proc accesslevel {handle {channel ""}} {
		if {$channel == ""} {
			if {[matchattr $handle A]} {
				return 8
			} elseif {[matchattr $handle D]} {
				return 7
			} elseif {[matchattr $handle S]} {
				return 6
			} elseif {[matchattr $handle n]} {
				return 5
			} elseif {[matchattr $handle m]} {
				return 4
			} elseif {[matchattr $handle o]} {
				return 3
			} elseif {[matchattr $handle vf]} {
				return 2
			} elseif {[matchattr $handle B]} {
				return 1
			} else {
				return 0
			}
		} elseif {![validchan $channel]} {
			return 0
		} else {
			if {[matchattr $handle |n $channel]} {
				return 5
			} elseif {[matchattr $handle |m $channel]} {
				return 4
			} elseif {[matchattr $handle |o $channel]} {
				return 3
			} elseif {[matchattr $handle |vf $channel]} {
				return 2
			} elseif {[matchattr $handle |B $channel]} {
				return 1
			} elseif {[matchattr $handle ADSnm]} {
				# bot staff hack
				return 6
			} else {
				return 0
			}
		}
		return 0
	}

	proc tduration {string} {
		set result "0"
		array set duration {
			{minute} {60}
			{hour} {3600}
			{day} {86400}
			{week} {604800}
			{month} {2419200}
			{year} {31536000}
		}
		if {[regexp -nocase -- {([\d]{1,})m} $string full minute]} {
			set result "[expr {$result+($duration(minute)*$minute)}]"
		}
		if {[regexp -nocase -- {([\d]{1,})h} $string full hour]} {
			set result "[expr {$result+($duration(hour)*$hour)}]"
		}
		if {[regexp -nocase -- {([\d]{1,})d} $string full day]} {
			set result "[expr {$result+($duration(day)*$day)}]"
		}
		if {[regexp -nocase -- {([\d]{1,})w} $string full week]} {
			set result "[expr {$result+($duration(week)*$week)}]"
		}
		if {[regexp -nocase -- {([\d]{1,})y} $string full year]} {
			set result "[expr {$result+($duration(year)*$year)}]"
		}
		return "$result"
	}

	proc btduration {string} {
	  if {![regexp -- {[0-9]+(s|m|h|d|w|y)} $string]} { return 0 }
	  set duration 0
	  if {[regexp -- {([0-9]+)s} $string -> number]} {
		set duration [expr {$duration+$number}]
	  }
	  if {[regexp -- {([0-9]+)m} $string -> number]} {
		set duration [expr {$duration+($number*60)}]
	  }
	  if {[regexp -- {^([0-9]+)h$} $string -> number]} {
		set duration [expr {$duration+($number*3600)}]
	  }
	  if {[regexp -- {^([0-9]+)d$} $string -> number]} {
		set duration [expr {$duration+($number*86400)}]
	  }
	  if {[regexp -- {^([0-9]+)w$} $string -> number]} {
		set duration [expr {$duration+($number*604800)}]
	  }
	  if {[regexp -- {^([0-9]+)y$} $string -> number]} {
		set duration [expr {$duration+($number*31536000)}]
	  }
	  if {[regexp -- {-} $duration]} {
		return 0
	  }
	  return $duration
	}

	proc onmsg_rejoin {nickname hostname handle text} {
		if {![matchattr $handle nm]} { return 0 }
		if {[validchan [set channel [lindex [split $text] 0]]]} {
			channel set $channel +inactive
			putquick "PART $channel"
			after 2000
			channel set $channel -inactive
			putquick "JOIN $channel"
			putserv "NOTICE $nickname :Rejoined '$channel' successfully."
		} elseif {[llength [channels]] >= 20} {
			putserv "NOTICE $nickname :Could not (re)join '$channel' - I'm already 20/20."
		} else {
			channel add $channel
			chattr $handle |+amno $channel
			putserv "NOTICE $nickname :(Re)joined '$channel' successfully."
		}
		return 0
	}

	proc onjoin {nickname hostname handle channel} {
		variable onjoin; variable kickmsg; variable homechan; variable welcomeskin
		# channel peak
		if {[channel get $channel service_peak] && [set peak [channel get $channel service_peak_count]]<[set count [llength [chanlist $channel]]]} {
			channel set $channel service_peak_count [set peak $count]
			channel set $channel service_peak_time [set ts [clock seconds]]
			channel set $channel service_peak_nick [set by $nickname]
			putserv "PRIVMSG $channel :New $channel peak $peak set by ${nickname}."
		}
		# XTRA events		
		if {[isbotnick $nickname]} {
			foreach user [chanlist $channel] {
				if {[validuser [set handle [nick2hand $user]]] && ([getuser $handle XTRA loggedin]=="0" || [getuser $handle XTRA loggedin]=="")} {
					setuser $handle XTRA loggedin 1
					setuser $handle XTRA lastlogin "[clock seconds]"
					setuser $handle XTRA lasthost "[string trimleft $hostname ~]"
				}
			}
			if {[set service [getnetworkservice $channel chanserv]] != ""} {
				channel set $channel -service_netsplit
				channel set $channel service_servicebot $service
				chattr [nick2hand $service] +S|+S $channel
			}
			if {[string match *l* [getchanmode $channel]]} {
				if {[string match *k* [getchanmode $channel]]} {
					channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 2]
				} else {
					channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 1]
				}
			}
			return 0
		} elseif {[getuser $handle XTRA loggedin]=="0" || [getuser $handle XTRA loggedin]==""} {
			setuser $handle XTRA loggedin 1
			setuser $handle XTRA lastlogin "[clock seconds]"
			setuser $handle XTRA lasthost "[string trimleft $hostname ~]"
		}
		# Q
		if {[isnetworkservice $nickname] && [ischannelservice $nickname]} {
			channel set $channel -service_netsplit
			channel set $channel service_servicebot "$nickname"
			if {[validuser $handle]} { chattr $handle +S|+S $channel }
			return 0
		}
		# Known
		if {[channel get $channel service_known] && ![matchattr $handle nmS|RnmovfS $channel]} {
			if {[string match -nocase *users.quakenet.org [set hostname *!$hostname]]} {
				set hostname *!*@[lindex [split $hostname @] 1]
			}
			if {[set kickmsg [channel get $channel service_kickmsg_known]] == ""} {
				channel set $channel service_kickmsg_known "[set kmsg "$kickmsg(known)"]"
			}
			channel set $channel service_kid_known "[set id [expr {[channel get $channel service_kid_known] + 1}]]"
			regsub -all :channel: $kmsg "$channel" kmsg
			regsub -all :id: $kmsg "$id" kmsg
			if {[botisop $channel] && [onchan $nickname $channel]} {
				putquick "MODE $channel -o+b $nickname $hostname"
				putquick "KICK $channel $nickname :$kmsg"
				utimer 300 [list pushmode $channel -b $hostname]
			}
			return 0
		}
		# Clonescan
		if {[channel get $channel service_clonescan] && ![matchattr $handle nmS|RnmovfS $channel]} {
			set type [channel get $channel service_clonescan_hosttype]
			set max [channel get $channel service_clonescan_maxclones]
			set hostname [string trimleft $hostname ~]
			set hostname [expr {$type ? "*!*@[lindex [split $hostname @] 1]" : "*!*$hostname"}]
			set list [list]       
			foreach user [chanlist $channel] {       
				set host [string trimleft [getchanhost $user $channel] ~]
				set host [expr {$type ? "*!*@[lindex [split $host @] 1]" : "*!*$host"}]		
				if {[string equal -nocase $hostname $host]} {
					lappend list $user;
				}
			}
			if {[llength $list] >= $max} {
				if {[botisop $channel]} {
					channel set $channel service_kid "[set id [expr {[channel get $channel service_kid] + 1}]]"
					regsub -all :clones: $kickmsg(clonescan) "[llength $list]" kmsg
					regsub -all :maxclones: $kmsg "[channel get $channel service_clonescan_maxclones]" kmsg
					regsub -all :hostname: $kmsg "$hostname" kmsg
					regsub -all :channel: $kmsg "$channel" kmsg
					regsub -all :id: $kmsg "$id" kmsg
					regsub -all :homechan: $kmsg "$homechan" kmsg
					if {$hostname == "*!*@" || $hostname == "*!*@*"} {
						#putloglev do "onjoin_clonescan: (bad hostmask: $hostname) $nickname $hostname $handle $channel $list"
					}
					putserv "MODE $channel +b $hostname"
					foreach user $list {
						if {[onchan $user $channel] && [botisop $channel]} {
							putserv "KICK $channel $user :$kmsg"
						}
					}
					utimer [expr {[channel get $channel service_clonescan_bantime]*60}] [list puthelp "MODE $channel -b $hostname"]
				} else {
					putserv "PRIVMSG $channel :Clonescan: $nickname is a clone! The nicknames ( [join $list ", "] ) are sharing the same hostmask ( [lindex [split $hostname @] 1] ). (Clones/Maxclones: [llength $list]/[channel get $channel service_clonescan_maxclones])."
				}
				return 0
			}
		}
		# Usermodes
		if {![matchattr $handle d|d $channel]} {
			#set mode [list]; set arg [list]
			if {[matchattr $handle B|B $channel]} {
				if {[string match -nocase *users.quakenet.org [set hostname *!$hostname]]} {
					set hostname *!*@[lindex [split $hostname @] 1]
				}
				if {[channel get $channel service_kickmsg_defaultban] == ""} {
					channel set $channel service_kickmsg_defaultban "$kickmsg(defaultban)"
				}
				set kmsg [channel get $channel service_kickmsg_defaultban]
				channel set $channel service_kid "[set id [expr {[channel get $channel service_kid] + 1}]]"
				regsub -all :channel: $kmsg $channel kmsg
				regsub -all :id: $kmsg $id kmsg
				if {[botisop $channel] && [onchan $nickname $channel]} {
					putquick "MODE $channel -o+b $nickname $hostname"
					putquick "KICK $channel $nickname :$kmsg"
				}
				return 0
			} else {
				if {[matchattr $handle S|S $channel]} {
					#lappend mode "o"; lappend arg $nickname
					pushmode $channel +o $nickname
				} else {
					if {[matchattr $handle |o $channel] && [matchattr $handle |ap $channel]} {
						#lappend mode "o"; lappend arg $nickname
						pushmode $channel +o $nickname
					}
					if {[matchattr $handle |vf $channel] && [matchattr $handle |gp $channel]} {
						#lappend mode "v"; lappend arg $nickname
						pushmode $channel +v $nickname
					}
				}
				#if {[llength $mode]>=1} {
					#putquick "MODE $channel +[join $mode ""] [join $arg " "]"
				#}
			}
		}
		# Autolimit
		if {[channel get $channel service_autolimit]} {
			if {[string match *l* [getchanmode $channel]]} {
				if {[string match *k* [getchanmode $channel]]} {
					set curr [lindex [split [getchanmode $channel]] 2]
				} else {
					set curr [lindex [split [getchanmode $channel]] 1]
				}
				set newlimit [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]
				if {$newlimit == "$curr"} { return }
				if {[expr {$newlimit - $curr}] == "3" || [expr {$newlimit - $curr}] == "-3"} {
					pushmode $channel +l $newlimit
					channel set $channel service_chanmode_limit $newlimit
				}
			} else {
				pushmode $channel +l [set newlimit [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]]
				channel set $channel service_chanmode_limit $newlimit
			}
		}
		# Automodes
		if {![channel get $channel service_netsplit] && ![matchattr $handle d|d $channel] && [botisop $channel] && ([set ao [channel get $channel service_ao]] || [set av [channel get $channel service_av]])} {
			set mode [list]; set arg [list]
			if {$ao && $av} {
				lappend mode "ov"; lappend arg "$nickname $nickname"
			} elseif {$ao} {
				lappend mode "o"; lappend arg $nickname
			} elseif {$av} {
				lappend mode "v"; lappend arg $nickname
			}
			if {[llength $mode]>=1} { 
				pushmode $channel +[join $mode ""] [join $arg " "]
			}
		}
		# flush channel modes
		flushmode $channel
		# Welcome
		if {[channel get $channel service_welcome] && ![isbotnick $nickname]} {
			if {[set skin [channel get $channel service_welcome_skin]] == ""} {
				channel set $channel service_welcome_skin "[set skin $welcomeskin]"
			}
			regsub -all :nickname: $skin "$nickname" skin
			regsub -all :hostname: $skin "$hostname" skin
			regsub -all :date: $skin "[clock format [clock seconds] -format "%A %d/%m/%Y"]" skin
			set t [clock format [clock seconds] -format "%T"]
			regsub -all :time: $skin "[lindex [split $t :] 0]hr [lindex [split $t :] 1]min [lindex [split $t :] 2]sec" skin
			regsub -all :channel: $skin "$channel" skin
			channel set $channel service_jid "[set id [expr {[channel get $channel service_jid] + 1}]]"
			regsub -all :id: $skin "$id" skin
			if {$skin == ""} { return 0 }
			if {[channel get $channel service_welcome_notice]} {
				putserv "NOTICE $nickname :$skin"
			} else {
				putserv "PRIVMSG $channel :$skin"
			}
		}
		# authban/badchan/vip
		set chks [list]
		if {[channel get $channel service_authban] && [channel get $channel service_authbans] != ""} {
			lappend chks "authban"
		}
		if {[channel get $channel service_badchan] && [channel get $channel service_badchans] != ""} {
			lappend chks "badchan"
		}
		if {[channel get $channel service_vip] && [channel get $channel service_vipc] != ""} {
			lappend chks "vip"
		}
		#putlog "$nickname @ $channel chks => $chks"
		if {[llength $chks] >= 1} {
			#putlog "Delayed whois -> $nickname @ $channel -> $chks (0)"
			service whois delayedwhois $nickname $channel $chks 0
		}
		return 0
	}
	
	proc onpart {nickname hostname handle channel {reason {}}} {
		if {[isbotnick $nickname]} {
			foreach user [chanlist $channel] {
				if {[validuser [set handle [nick2hand $user]]] && ([getuser $handle XTRA loggedin]=="1" || [getuser $handle XTRA loggedin] == "") && ![onchan $user]} {
					setuser $handle XTRA loggedin 0
				}
			}
			return 0
		} elseif {([getuser $handle XTRA loggedin]=="1" || [getuser $handle XTRA loggedin] == "") && ![onchan $nickname]} {
			setuser $handle XTRA loggedin 0
		}
		if {[isnetworkservice $nickname] && [ischannelservice $nickname]} {
			channel set $channel +service_netsplit
			channel set $channel service_servicebot ""
			return 0
		}
		if {[channel get $channel service_flyby] && ![matchattr $handle nmovfS|nmovfS $channel] && [botisop $channel] && [expr {[clock seconds] - [getchanjoin $nickname $channel]}] < 10} {
			if {[string match -nocase *users.quakenet.org [set hostname *!*[string trimleft $hostname ~]]]} {
				set hostname *!*@[lindex [split $hostname @] 1]
			}
			pushmode $channel +b $hostname
			utimer 300 [list pushmode $channel -b $hostname]
		}
		if {[channel get $channel service_autolimit]} {
			if {[string match *l* [getchanmode $channel]]} {
				if {[string match *k* [getchanmode $channel]]} {
					set curr [lindex [split [getchanmode $channel]] 2]
				} else {
					set curr [lindex [split [getchanmode $channel]] 1]
				}
				set newlimit [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]
				if {$newlimit == "$curr"} { return }
				if {[expr {$newlimit - $curr}] == "3" || [expr {$newlimit - $curr}] == "-3"} {
					pushmode $channel +l $newlimit
				}
			} else {
				pushmode $channel +l [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]
			}
		}
		return 0
	}

	proc onraw_nick {from raw arg} {
		set nickname [lindex [split $from !] 0]
		set hostname [string trimleft [lindex [split $from !] 1] ~]
		set newnick [string trimleft $arg :]
		set handle [nick2hand $newnick]
		onnick_global $nickname $hostname $handle $newnick
		foreach channel [channels] {
			onnick_channel $nickname $hostname $handle $channel $newnick
		}
		return 0
	}
		
	proc onnick_global {nickname hostname handle newnick} {
		variable authnames
		if {[info exists authnames($nickname)]} {
			set authnames($newnick) "$authnames($nickname)"
			unset authnames($nickname)
		}
		return 0
	}

	proc onnick_channel {nickname hostname handle channel newnick} {
		variable saveops
		set ch [string tolower $channel]; set ni [string tolower $nickname]; set ho [string trimleft [getchanhost $newnick $channel] ~]; set neni [string tolower $newnick]
		if {[info exists saveops(${ch},${ni}!${ho})]} {
			set saveops(${ch},${neni}!${ho}) "$saveops(${ch},${ni}!${ho})"
			unset saveops(${ch},${ni}!${ho})
		}
		return 0
	}

	proc info_mode {nickname hostname handle channel mode victim {reason ""}} {
		global botnick botname; variable adminchan
		if {$nickname == ""} {
			set nickname "$hostname"
		}
		if {$mode == "+o" && [string equal -nocase $botnick $victim]} {
			putserv "PRIVMSG $adminchan :\00307\002INFO:\002 \003I've been \002OPED\002 on \002$channel\002 by \002$nickname\002"
		} elseif {$mode == "-o" && [string equal -nocase $botnick $victim]} {
			putserv "PRIVMSG $adminchan :\00307\002INFO:\002 \003I've been \002DEOPED\002 on \002$channel\002 by \002$nickname\002"
		} elseif {$mode == "+b" && [string match -nocase "*[lindex [split $botname @] 1]*" "*$victim*"]} {
			putserv "PRIVMSG $adminchan :\00304\002ERROR:\002 \003I've been \002BANNED\002 on \002$channel\002 by \002$nickname\002"
		} elseif {$mode == "kick" && [string equal -nocase $botnick $victim] && [info exists reason]} {
			putserv "PRIVMSG $adminchan :\00304\002ERROR:\002 \003I've been \002KICKED\002 on \002$channel\002 by \002$nickname\002 with the reason: \002[stripcodes bcu $reason]\002"
		}
		return 0
	}

	proc onraw_invite {from raw arg} {
		global botnick; variable adminchan; variable homechan
		set nickname [lindex [split $from !] 0]
		set hostname [lindex [split $from !] 1]
		if {[string equal -nocase $botnick [lindex [split $arg] 0]] && [string index [set channel [lindex [split $arg] 1]] 0] == "#"} {
			putserv "PRIVMSG $adminchan :\00307\002INFO:\002 \003I've been \002INVITED\002 by \002$nickname\002 to \002$channel\002"
			if {![validchan $channel]} {
				putserv "NOTICE $nickname :Your channel '${channel}' is unknown to me - Bot by $homechan."
			} else {
				putquick "JOIN $channel"
				puthelp "NOTICE $nickname :Invite successful - I (re)joined ${channel}."
			}
		}
		return 0
	}

	proc onraw_kick {from raw arg {lookup 0}} {
		global botnick server; variable kickmsg; variable homechan
		set nickname [lindex [split $from !] 0]
		set hostname [string trimleft [lindex [split $from !] 1] ~]
		set channel [lindex [split $arg] 0]
		set target [lindex [split $arg] 1]
		if {[isbotnick $nickname] || $nickname == "" || [string equal -nocase $nickname $target] || ![channel get $channel service_prot] || [channel get $channel service_startup] || ([string equal -nocase [lindex [split $server :] 0] $hostname] && $nickname == "")} { return 0 }
		set hostname [string trimleft [lindex [split $from !] 1] ~]
		set authname [service authname nick2auth $nickname]
		set handle [nick2hand $nickname]		
		if {$handle == "*" && $authname == "" && $lookup == 0} {
			putlog "onraw_kick: Performing auth lookup for $nickname @ $channel"
			if {[set op [isop $nickname $channel]]} {
				putquick "MODE $channel -o $nickname" -next
			}
			if {[llength [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] <= 0} {
				set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],1) "$op KICK $arg"
				putquick "WHO $nickname n%nuhat,139" -next; return 0
			} else {
				set id [expr {[lindex [split [lindex [split [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] end] ,] end] + 1}]
				set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],$id) "$op KICK $arg"
				return 0
			}
		} elseif {$lookup == 2} {
			set reop 1
		} else {
			set reop 0
		}
		if {$authname != "" && [validuser $authname]} { set handle $authname }
		set reason [lrange [string trimleft $arg :] 2 end]
		info_mode $nickname $hostname $handle $channel kick $target $reason
		set flags [expr {[channel get $channel service_prot_hard] ? "nmNbfS|nmS" : "nmNbfS|nmoS"}]
		if {[matchattr $handle $flags $channel]} {
			if {$reop && [botisop $channel] && ![isop $nickname $channel]} {
				putserv "MODE $channel +o $nickname"; return 0
			}
			return 0
		}
		set service [channel get $channel service_servicebot]
		if {[string match -nocase *users.quakenet.org [set hostname *!*$hostname]]} {
			set hostname *!*@[lindex [split $hostname @] 1]
		}
		if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { 
			#putloglev do "kickprot: (bad banmask: $hostname) $nickname [getchanhost $nickname $channel] $handle $channel $target $reason"
			return 0
		}
		if {[isbotnick $target]} {
			#putquick "PRIVMSG $service :CHANFLAGS $channel +b-p"
			putquick "PRIVMSG $service :RECOVER $channel" -next
			putquick "PRIVMSG $service :UNBANME $channel" -next
			putquick "JOIN $channel" -next
			putquick "PRIVMSG $service :OP $channel" -next
			set violate "\002\037kick/ban\037 me\002"
			if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
				channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
			}
			channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
			regsub -all :violate: $kmsg "$violate" kmsg
			regsub -all :channel: $kmsg "$channel" kmsg
			regsub -all :id: $kmsg "$id" kmsg
			regsub -all :homechan: $kmsg "$homechan" kmsg
			if {[botisop $channel] && [onchan $nickname $channel]} {
				putquick "MODE $channel -o+b $nickname $hostname"
				putquick "KICK $channel $nickname :$kmsg"
			}
			newchanban $channel $hostname $botnick "$kmsg" 120
			#putquick "PRIVMSG $service :CHANFLAGS $channel -b+p"
		} else {
			set violate "\002\037kick\037 anyone\002"
			if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
				channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
			}
			channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
			regsub -all :violate: $kmsg "$violate" kmsg
			regsub -all :channel: $kmsg "$channel" kmsg
			regsub -all :id: $kmsg "$id" kmsg
			regsub -all :homechan: $kmsg "$homechan" kmsg
			if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { 
				#putloglev do "kickprot: (bad banmask: $hostname) $nickname [getchanhost $nickname $channel] $handle $channel $target $reason"
				return
			}
			if {[botisop $channel] && [onchan $nickname $channel]} {
				putquick "MODE $channel -o+b $nickname $hostname"
				putquick "KICK $channel $nickname :$kmsg"
			}
			newchanban $channel $hostname $botnick "$kmsg" 120
		}
		return 0
	}

	proc checkraw {from raw arg} {
		variable homechan; variable adminchan; variable helpchan
		# 471 = channel is full
		# 473 = channel is invite-only
		# 474 = banned from channel
		# 475 = channel is +k
		# 477 = channel is +r
		# 479 = glined channel
		if {[string equal -nocase $homechan [lindex [split $arg] 0]]} { return 0 }
		if {[string equal -nocase $adminchan [lindex [split $arg] 0]]} { return 0 }
		if {[string equal -nocase $helpchan [lindex [split $arg] 0]]} { return 0 }
		switch -exact -- $raw {
			"471" - "473" - "474" - "475" {
				#if {[info exists service::errorcount([set channel [string tolower [lindex [split $arg] 1]]]:rejoin)]} {
					#    set count [expr {$service::errorcount($channel:rejoin) + 1}]
					#    set service::errorcount($channel:rejoin) "$count"
					#    if {$count >= "10"} {]
						#        putserv "PRIVMSG $service::adminchan :.suspend service $channel $service::suspend(rejoin)"
						#		catch {unset service::errorcount($channel:rejoin)}
						#    }
					#} else {
					#    set service::errorcount($channel:rejoin) "1"
					#}
			}
			"477" {
				putserv "PRIVMSG $adminchan :\00304ERROR\00304: I could not join [set channel [string tolower [lindex [split $arg] 1]]] (+r) - Im not authed!"
			}
			"479" {
				#putserv "PRIVMSG $adminchan :.suspend service [set channel [string tolower [lindex [split $arg] 1]]] $service::suspend(glined)"
				putserv "PRIVMSG $adminchan :Gline/Badchan reason for ${channel}: (Glined: [lrange $arg 1 end])."
			}
			"default" {
				#putserv "PRIVMSG $adminchan :Non-monitored raw line found - $from: $raw $arg."
			}
		}
		return 0
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
		if {$authname != "" && [validuser $authname] && [getuser $authname xtra isauth] eq 1} { set handle $authname }
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

	proc badbanmask {mask} {
		if {$mask eq ""} {
			return 1
		} elseif {[regexp -nocase -- {^([a-z0-9\?\*\^\_\`\{\}\[\]\|\\]{1,})(!{1,1})([a-z0-9\?\*\^\_\`\{\}\[\]\|\\]{1,})(@{1,1})([a-z0-9\?\*\.\-]{1,})$} $mask]} {
			return [widebanmask $mask]
		} else {
			return 1
		}
		return 0
	}
	
	proc widebanmask {mask} {
		if {$mask eq ""} { return 0 }
		return [regexp -nocase -- {^(\*|\?{1,})(!{1,1})(\*|\?{1,})(@{1,1})(\*|\?{1,})$} $mask]
	}
	
	proc validbanmask {mask} {
		if {[llength $mask]>1} { return 0 }
		set validnickident [list 63 94 95 96 123 125 91 93 124 92]; # *42
		set validhost [list 63 46 45]; # *42
		set ex 0; set at 0; set ti 0; set la 0
		set n 1; set i 0; set h 0; set r 1
		for {set c 0} {$c<[string length $mask]} {incr c; set la 0} {
			set ch [string index $mask $c]
			scan $ch %c as
			if {$c>=1} { scan [string index $mask [expr {$c-1}]] %c la }
			#putlog "#$c Char: $ch - Ascii: $as - Last: $la"
			if {$as >= 48 && $as <= 57} { continue }; # valid digit
			if {$as >= 65 && $as <= 90} { continue }; # valid uppercase letter
			if {$as >= 97 && $as <= 122} { continue }; # valid lowercase letter
			if {($n || $i) && [lsearch -exact $validnickident $as]!=-1} { continue }; # valid char for nickname and ident
			if {$h && [lsearch -exact $validhost $as]!=-1} { continue }; # valid char for hostmask
			if {$as == 33} {
				# we have ! -- we can only have one ! in a valid banmask
				if {$ex} { set r 0; break }; # ! already parsed -- invalid banmask
				set ex 1; set n 0; set i 1; set h 0; # valid -- pass on over to ident
			}
			if {$as == 64} {
			# we have @ -- we can only have one @ in a valid banmask
				if {!$ex} { set r 0; break }; # we have @ before ! -- invalid
				if {$at} { set r 0; break }; # @ already parsed -- invalid banmask
				set at 1; set n 0; set i 0; set h 1; # valid -- pass on over to hostmask
			}
			if {$as == 42 && $as == $la} {
				# we have two *'s side by side -- invalid
				set r 0; break
			}
			if {$as == 126} {
				# we have ~ -- only valid once for ident
				if {!$i} { set r 0; break }; # invalid
				if {$i && $ti} {  set r 0; break}; # invalid
				set ti 1; # valid
			}
		}
		if {$ex && $at && $r} { return [widebanmask $mask] }
		return 0
	}

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

	proc onneed {channel type} {
		variable homechan; variable adminchan; variable helpchan
		switch -exact -- $type {
			"op" {
				if {[string equal -nocase $homechan $channel]} { return 0 }
				if {[string equal -nocase $adminchan $channel]} { return 0 }
				if {[string equal -nocase $helpchan $channel]} { return 0 }
				putquick "PRIVMSG Q :OP $channel" -next
			}
			"unban" {
				if {[botonchan $channel] && ![botisop $channel]} {
					putquick "PRIVMSG Q :UNBANALL $channel" -next
				} else {
					putquick "PRIVMSG Q :INVITE $channel" -next
				}
			}
			"invite" {
				putquick "PRIVMSG Q :INVITE $channel" -next
			}
			"limit" {
				putquick "PRIVMSG Q :INVITE $channel" -next
			}
			"key" {
				putquick "PRIVMSG Q :INVITE $channel" -next
			}
		}
		return 0
	}

	proc onflud {nickname hostname handle type channel} {
		global botnick flood-msg; variable flood
		if {![validchan $channel]} { return }
		if {![channel get $channel service_flood]} { return 1 }
		if {[matchattr $handle nmNbfS|nmovf $channel]} { return 1 }
		if {[isbotnick $nickname] || [isnetworkservice $nickname]} { return 1 }
		if {[string match -nocase *quakenet.org [set bhost *!*[string trimleft $hostname ~]]]} {
			set bhost *!*@[lindex [split $hostname @] 1]
		}
		set chan [join [channel get $channel flood-chan] :]
		set join [join [channel get $channel flood-join] :]
		set msg "${flood-msg}"
		set ctcp [join [channel get $channel flood-ctcp] :]
		set btime [channel get $channel service_bantime_flood]
		if {$btime == "" || $btime == "0"} {
			channel set $channel service_bantime_flood "2"
			set btime "2"
		}
		switch -exact -- $type {
			"pub" {
				set reason "anti-flood: you exceeded [lindex [split $chan :] 0] line(s) in [lindex [split $chan :] 1] second(s) - banned for $btime minute(s)"
				if {[botisop $channel] && [onchan $nickname $channel]} {
					putquick "MODE $channel +b $bhost"
					putquick "KICK $channel $nickname :$reason"
					utimer [expr {60 * $btime}] [list puthelp "MODE $channel -b $bhost"]
				}
				newchanban $channel $botnick "$reason" $btime
			}
			"join" {
				set reason "anti-flood: you exceeded [lindex [split $join :] 0] join(s) in [lindex [split $join :] 1] second(s) - banned for $btime minute(s)"
				if {[botisop $channel]} {
					if {![info exists flood([set channel [string tolower $channel]])]} {
						set flood($channel) "1"
						set modes [getchanmode $channel]
						set lock ""
						foreach mode [split $flood(lockmodes) ""] {
							if {$mode != "" && ![string match "*$mode*" $modes]} {
								append lock $mode
							}
						}
						if {$lock == ""} {
							putquick "MODE $channel +b $bhost"
							putquick "KICK $channel $nickname :$reason"
							utimer [expr {60 * $btime}] [list puthelp "MODE $channel -b $bhost"]
						} else {
							putquick "MODE $channel +b$lock $bhost"
							putquick "KICK $channel $nickname :$reason"
							utimer [expr {60 * $btime}] [list puthelp "MODE $channel -b $bhost"]
							utimer 60 [list unlock $channel $lock $modes]
						}
					} else {
						putquick "MODE $channel +b $bhost"
						putquick "KICK $channel $nickname :$reason"
						utimer [expr {60 * $btime}] [list puthelp "MODE $channel -b $bhost"]
					}
					newchanban $channel $botnick "$reason" $btime
				}
			}
			"msg" {
				set reason "anti-flood: you exceeded [lindex [split $msg :] 0] msg(s) in [lindex [split $msg :] 1] second(s) - banned for $btime minute(s)"
			}
			"ctcp" {
				set reason "anti-flood: you exceeded [lindex [split $ctcp :] 0] ctcp(s) in [lindex [split $ctcp :] 1] second(s) - banned for $btime minute(s)"
				if {[botisop $channel] && [onchan $nickname $channel]} {
					putquick "MODE $channel +b $bhost"
					putquick "KICK $channel $nickname :$reason"
					utimer [expr {60 * $btime}] [list puthelp "MODE $channel -b $bhost"]
				}
				newchanban $channel $botnick "$reason" $btime
			}
		}
		return 1
	}

	proc onraw_topic {from raw arg {lookup 0}} {
		global botnick server; variable kickmsg; variable homechan
		set channel [lindex [split $arg] 0]
		set nickname [lindex [split $from !] 0]
		set hostname [lindex [split $from !] 1]
		set authname [service authname nick2auth $nickname]
		set handle [nick2hand $nickname]		
		if {$handle == "*" && $authname == "" && $lookup == 0} {
			putlog "onraw_topic: Performing auth lookup for $nickname @ $channel"
			if {[set op [isop $nickname $channel]]} {
				putquick "MODE $channel -o $nickname" -next
			}
			if {[llength [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] <= 0} {
				set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],1) "$op KICK $arg"
				putquick "WHO $nickname n%nuhat,139" -next; return 0
			} else {
				set id [expr {[lindex [split [lindex [split [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] end] ,] end] + 1}]
				set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],$id) "$op KICK $arg"
				return 0
			}
		} elseif {$lookup == 2} {
			set reop 1
		} else {
			set reop 0
		}
		if {$authname != "" && [validuser $authname]} { set handle $authname }
		set topic [join [lindex [split [lrange $arg 1 end] :] 1]]
		if {[string equal -nocase [lindex [split $server :] 0] $hostname] || $nickname == ""} { return 0 }
		if {[string equal -nocase $botnick $nickname]} {
			if {[channel get $channel service_topic_save]} {
				channel set $channel service_topic_current "$topic"
			} elseif {[channel get $channel service_topic_force]} {
				if {[set topc [channel get $channel service_topic_current]] != ""} {
					if {![string equal $topc $topic]} {
						if {[channel get $channel service_topic_Q]} {
							putquick "PRIVMSG Q :SETTOPIC $channel $topc"
						} else {
							putquick "TOPIC $channel :$topc"
						}
					}
				} else {
					if {[channel get $channel service_topic_Q]} {
						putquick "PRIVMSG Q :SETTOPIC $channel No topic saved."
					} else {
						putquick "TOPIC $channel :No topic saved."
					}
				}
			}
		}
		if {([channel get $channel service_prot_hard] && [matchattr $handle nmNS|nmS $channel]) || [matchattr $handle nmNoS|nmoS $channel] && $topic != ""} {
			if {$reop && [botisop $channel] && ![isop $nickname $channel]} {
				putserv "MODE $channel +o $nickname"
			}
			if {[channel get $channel service_topic_save]} {
				channel set $channel service_topic_current "$topic"
				putserv "NOTICE $nickname :Done. $channel topic saved to '$topic'."
			} elseif {[channel get $channel service_topic_force]} {
				if {[set topc [channel get $channel service_topic_current]] != ""} {
					if {[channel get $channel service_topic_Q]} {
						putquick "PRIVMSG Q :SETTOPIC $channel $topc"
					} else {
						putquick "TOPIC $channel :$topc"
					}
				} else {
					if {[channel get $channel service_topic_Q]} {
						putquick "PRIVMSG Q :SETTOPIC $channel No topic saved."
					} else {
						putquick "TOPIC $channel :No topic saved."
					}
				}
				putserv "NOTICE $nickname :ERROR: $channel topic is forced. (Use '$::botnick topic' to set the topic)"
			}
		} elseif {[channel get $channel service_prot] && ![channel get $channel service_startup]} {
			if {[string match -nocase *users.quakenet.org [set hostname *!*[string trimleft $hostname ~]]]} {
				set hostname *!*@[lindex [split $hostname @] 1]
			}
			if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
				channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
			}
			channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
			regsub -all :violate: $kmsg "\002\037change the topic\037\002" kmsg
			regsub -all :channel: $kmsg "$channel" kmsg
			regsub -all :id: $kmsg "$id" kmsg
			regsub -all :homechan: $kmsg "$homechan" kmsg
			if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { 
				putlog "Topicprot: (bad banmask: $hostname) $nickname [getchanhost $nickname $channel] $handle $channel $topic"; return
			}
			if {[botisop $channel] && [onchan $nickname $channel]} {
				putquick "MODE $channel -o+b $nickname $hostname"
				putquick "KICK $channel $nickname :$kmsg"
				newchanban $channel $hostname $botnick "$kmsg" 120
			}
			if {[set topc [channel get $channel service_topic_current]] != ""} {
				if {[channel get $channel service_topic_Q]} {
					putquick "PRIVMSG Q :SETTOPIC $channel $topc"
				} else {
					putquick "TOPIC $channel :$topc"
				}
			} else {
				if {[channel get $channel service_topic_Q]} {
					putquick "PRIVMSG Q :SETTOPIC $channel No topic saved."
				} else {
					putquick "TOPIC $channel :No topic saved."
				}
			}
		}
		return 0
	}

	proc unlock {channel lock modes} {
		variable flood
		if {![info exists flood([set channel [string tolower $channel]])]} { return }
		if {[botisop $channel]} {
			puthelp "MODE $channel -$lock+$modes"
		}
		unset flood($channel)
	}

	proc onraw {from raw arg} {
		if {[string equal -nocase "MODE" $raw]} {
			onraw_mode $from $raw $arg; return 0
		} elseif {[string equal -nocase "KICK" $raw]} {
			onraw_kick $from $raw $arg; return 0
		} elseif {[string equal -nocase "TOPIC" $raw]} {
			onraw_topic $from $raw $arg; return 0
		} elseif {[string equal -nocase "NICK" $raw]} {
			onraw_nick $from $raw $arg; return 0
		} elseif {[string equal -nocase "INVITE" $raw]} {
			onraw_invite $from $raw $arg; return 0
		} elseif {$raw == "319" || $raw == "330" || $raw == "318"} {
			return 0
		} elseif {$raw == "315"} {
			# end of WHO
			set channel [lindex [split $arg] 1]
			if {[validchan $channel] && [channel get $channel service_startup]} {
				channel set $channel -service_startup; return
			}; return 0
		}
		return 0
	}
	
	proc giveopvoice {channel nickname} {
		if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
		if {![botisop $channel]} { return 0 }
		set m [list]
		if {![isop $nickname $channel]} { lappend m "o" }
		if {![isvoice $nickname $channel]} { lappend m "v" }
		if {[llength $v] >= 1} {
			putquick "MODE $channel +[join $m ""] [string repeat $nickname [llength $m]]"
		}
	}

	proc giveop {channel nickname} {
		if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
		if {![botisop $channel]} { return 0 }
		if {![isop $nickname $channel]} {
			putquick "MODE $channel +o $nickname"
		}
	}
	
	proc givevoice {channel nickname} {
		if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
		if {![botisop $channel]} { return 0 }
		if {![isvoice $nickname $channel]} {
			putquick "MODE $channel +v $nickname"
		}
	}
	
	proc deopkickban {channel nickname kickmsg} {
		if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
		if {![botisop $channel]} { return 0 }
		if {$kickmsg == ""} { set kickmsg "You are BANNED from this channel." }
		set banmask *!*[string trimleft ~ [getchanhost $nickname $channel]]
		if {[string equal -nocase "*.users.quakenet.org" $banmask]} {
			set banmask *!*@[lindex [split $banmask @] 1]
		}
		if {[isop $nickname $channel]} {
			putquick "MODE $channel -o+b $nickname $banmask"
		} else {
			putquick "MODE $channel +b $banmask"
		}
		putquick "KICK $channel :$kickmsg"
		return 1
	}
		

	proc host2hand {host} {
		set who "*"
		foreach user [userlist] {
			if {[llength [getuser $user HOSTS]] > 1} {
				foreach mask [getuser $user HOSTS] {
					if {[string equal -nocase $host $mask]} {
						set who $user
						break
					}
				}
			} elseif {[string equal -nocase $host [getuser $user HOSTS]]} {
				set who $user
				break
			}
		}
		return "$who"
	}

	proc onsplt {nickname hostname handle channel} {
		variable netsplit_start
		if {[string equal -nocase Q $nickname] && ![channel get $channel service_netsplit]} {
			channel set $channel +service_netsplit
			channel set $channel service_netsplit_time "[unixtime]"
			putserv "PRIVMSG $channel :$netsplit_start"
		}
	}

	proc onrejn {nickname hostname handle channel} {
		variable netsplit_end
		if {[string equal -nocase Q $nickname] && [channel get $channel service_netsplit]} {
			channel set $channel -service_netsplit
			set time [duration [expr {[unixtime] - [channel get $channel service_netsplit_time]}]]
			channel set $channel service_netsplit_time ""
			regsub -all :time: $netsplit_end $time msg
			putserv "PRIVMSG $channel :$msg"
		}
	}


	proc validtopickey {channel keyword} {
		if {[set curr [channel get $channel service_topic_keywords]] == ""} {
			return "0"
		} else {
			array set temp {}
			set result 0
			foreach entry $curr {
				set temp([string tolower [lindex [split $entry] 0]]) "1"
			}
			return "[info exists temp([string tolower $keyword])]"
		}
	}

	proc loaded {} {
		variable start; variable copyright
		loadmodules
		set modules [loadedmodules]
		set end [clock clicks]
		set ms [expr {(round($end) - round($start))/1000.0}]ms
		putlog "$copyright - [llength $modules] module(s) loaded[expr {[llength $modules]>0  ? ": [join $modules ", "]" : ""}] - loaded in $ms!!"
	}
	
	proc kickban {nickname channel type {reason {}}} {
		variable kickmsg; variable bantime; global botnick
		if {![validchan $channel] || ![onchan $nickname]} { return 0 }
		set valid [list gban userban known badchan userkick defaultban clonescan badword authban protkick]
		if {[lsearch -exact $valid [set type [string tolower $type]]] eq -1} { return 0 }
		set banmask "*!*[string trimleft ~ [getchanhost $nickname]]"
		if {[string equal -nocase "*.users.quakenet.org" $banmask]} { set banmask "*!*@[lindex [split $banmask @] 1]" }
		if {![validbanmask $banmask]} { putlog "KICKBAN - ERROR: Invalid banmask \"$banmask\" (Channel: $channel - Nickname: $nickname - Type: $type)"; return }
		set kmsg [channel get $channel service_kmsg_$type]
		channel set $channel service_kid_$type [set kid [expr {[channel get $channel service_kid_$type]+1}]]
		set btime [channel get $channel service_btime_$type]
		if {$kmsg eq ""} {
			channel set $channel service_kmsg_$type $kickmsg($type)
		}
		if {$btime eq "" || $btime < 0} {
			channel set $channel service_btime_$type $bantime($type)
		}
		set global 0; set chanban 0; set map [list]
		lappend map ":channel: \{$channel\}"
		lappend map ":nickname: \{$nickname\}"
		lappend map ":botnick: \{$botnick\}"
		lappend map ":id: \{$kid\}"
		lappend map ":bantime: \{$btime\}"
		lappend map ":homechan: \{....\}"
		if {$type eq "gban"} {
			set global 1; set mode "-o+b $nickname $banmask"
		} elseif {$type eq "userban"} {
			set mode "-o+b $nickname $banmask"
		} elseif {$type eq "known"} {
			set mode "-o+b $nickname $banmask"; set chanban 1
		} elseif {$type eq "badchan"} {
			set mode "-o+b $nickname $banmask"; set chanban 1
		} elseif {$type eq "userkick"} {
			set mode ""; set chanban 1
		} elseif {$type eq "defaultban"} {
			set mode "-o+b $nickname $banmask"
		} elseif {$type eq "clonescan"} {
			set mode "-o+b $nickname $banmask"; set chanban 1
		} elseif {$type eq "badword"} {
			set mode "-o+b $nickname $banmask"; set chanban 1
		} elseif {$type eq "authban"} {
			set mode "-o+b $nickname $banmask"; set chanban 1
		} elseif {$type eq "protkick"} {
			# You are not allowed to :violate: on :channel: - (ID: :id:) - (by :homechan:)
			lappend map ":violate: \{....\}"
			set mode "-o+b $nickname $banmask"
		} else {
			return 0
		}
		if {$mode != ""} {
			putquick "MODE $channel $mode"
		}
		putquick "KICK $channel :$kmsg"
		if {$btime>=0} {
			if {$chanban} {
				timer 1 [list pushmode $channel -b $banmask]
			} else {
				newchanban $channel $banmask creator $kmsg $btime ?options?
			}
		}
	}
	
	if {[catch {[namespace current]::helper_loadini_cmd $cmdinifile} err]} {
		putlog "Error parsing ${cmdinifile}:"
		foreach li $err {
			if {$li == ""} { continue }
			putlog $li
		}
		putlog "End of error."
	}
	
	# hacky way to upgrade stuff
	proc upgrade {} {
		# add P to chanflags for peak
		if {![info exists chanflags(P)]} {
			set chanflags(P) "service_peak peak"
		}
		# add m to chanflags for enforcemodes
		if {![info exists chanflags(m)]} {
			set chanflags(m) "service_enforcemodes enforcemodes"
		}
		# key is enforced via enforcemodes currently
		# add k to chanflags for enforcekey
		#if {![info exists chanflags(k)]} {
		#	set chanflags(k) "service_key enforcekey"
		#}
		# import saved automsg lines from the old save format into the new save format
		foreach channel [channels] {
			set messages [list]
			if {[set msg [channel get $channel service_automsg_line1]]!=""} {
				linsert $messages end $msg
				channel set $channel service_automsg_line1 ""
			}
			if {[set msg [channel get $channel service_automsg_line2]]!=""} {
				linsert $messages end $msg
				channel set $channel service_automsg_line2 ""
			}
			if {[set msg [channel get $channel service_automsg_line3]]!=""} {
				linsert $messages end $msg
				channel set $channel service_automsg_line3 ""
			}
			channel set $channel service_automsg_messages $messages
		}
		# overwrite existing global/channel levels
		variable global_user_levels; variable channel_user_levels
		array set global_user_levels {
			{admin} {A| -D+A|}
			{administrator} {A| -D+A|}
			{dev} {A| +AD|}
			{developer} {A| +AD|}
			{service} {ADn| +Samo|}
			{owner} {ADn| +anmovf|}
			{master} {ADn| -n+amovf|}
			{operator} {ADnm| -ADnm+aovf|}
			{op} {ADnm| -ADnm+aovf|}
			{voice} {ADnm| -ADanmo+gvf|}
			{friend} {ADnm| -ADanmo+gvf|}
			{ban} {ADnm| -ADanmogvf+b|}
			{none} {ADnm| -SADanmogvfb|}
			{clear} {ADnm| -SADanmogvfb|}
		}
		array set channel_user_levels {
			{owner} {ADnm|n |+anmovf}
			{master} {ADnm|nm |-n+amovf}
			{operator} {ADnm|nm |-nm+aovf}
			{op} {ADnm|nm |-nm+aovf}
			{voice} {ADnm|nm |-anmo+gvf}
			{friend} {ADnm|nm |-anmo+gvf}
			{ban} {ADnm|nm |-anmogvf+b}
			{none} {ADnm|nm |-anmogvfb}
			{clear} {ADnm|nm |-anmogvfb}
		}
		# remove the old setudef str for service_topic_save and recreate it as a flag
		catch {deludef str service_topic_save}
		catch {setudef flag service_topic_save}
	}
	
	upgrade	
	loaded

}