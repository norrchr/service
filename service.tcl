namespace eval service {

	variable start [clock clicks]
	variable script [lindex [split [info script] /] end]
	
	set file [open [info script] r]
	variable linecount [llength [split [read -nonewline $file] \n]]
	close $file
	
	# load version information
	source scripts/service/core/__version.tcl
	
	# load config file
	source scripts/service/core/__config.tcl
	
	# globr
	source scripts/service/core/__globr.tcl
	
	# load command handler functions
	source scripts/service/core/__commands.tcl
	source scripts/service/core/__loadcommands.tcl
	
	# module functions
	source scripts/service/modules/functions.tcl
	
	# network services
	source scripts/service/helpers/networkservices.tcl
	
	variable cmdinifile "[pwd]/scripts/service/commands.ini"
	array set cmdlist {}
	array set cmdhelp {}

	# TODO:
	# Fully replace with new config system
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
	
	# load binds
	source scripts/service/core/__binds.tcl

	# load setudefs
	source scripts/service/core/__setudef.tcl
		
	# core __init__
	# loads event handlers
	source scripts/service/core/__init__.tcl
	
	# helper functions
	source scripts/service/helpers/helper_functions.tcl
	
	source scripts/service/core/__findusers.tcl
	source scripts/service/core/__levels.tcl	
	source scripts/service/core/__duration.tcl
	source scripts/service/core/__validbanmask.tcl	
	source scripts/service/core/__infomode.tcl
	
	proc dnslookup_ban {ipaddr hostname status mask nickname handle channel time reason lastbind} {
		if {$status == 0} {
			putserv "NOTICE $nickname :BAN: DNS lookup failed for '$mask'."; return
		} else {
			if {$status == 1} {
				if {[set hand [host2hand [set mask1 [lindex [split $mask @] 0]@$ipaddr]]] == "*"} {
					set hand [host2hand [set mask2 [lindex [split $mask @] 0]@$hostname]]
				}
			} else {
				# *.users.quakenet.org
				set hand [host2hand $mask]
			}
			if {[matchattr $hand ADnm] && ![matchattr $handle ADn]} {
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
				if {$status == 1} {
					if {[isban $mask1 $channel]} {
						if {[isban $mask2 $channel]} {
							putserv "NOTICE $nickname :Banmask '$mask1' ($mask2) is already banned on $channel."; return
						} else {
							putserv "NOTICE $nickname :Banmask '$mask1' is already banned on $channel."; return
						}
					} elseif {[isban $mask2 $channel]} {
						putserv "NOTICE $nickname :Banmask '$mask2' is already banned on $channel."; return
					}
				} else {
					if {[isban $mask $channel]} {
						putserv "NOTICE $nickname :Banmask '$mask' is already banned on $channel."; return
					}
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
				if {$status == 1} {
					putquick "MODE $channel +bb $mask1 $mask2"
					newchanban $channel $mask1 $handle "$kmsg" [expr {[set bt [tduration $time]]/60}]
					newchanban $channel $mask2 $handle "$kmsg" [expr {[set bt [tduration $time]]/60}]
					if {$time == "0"} {
						putserv "NOTICE $nickname :Banmask '$mask1' ($mask2) added to my banlist (Expires: Never!)."
					} else {
						putserv "NOTICE $nickname :Banmask '$mask1' ($mask2) added to my banlist for $time (Expires: [clock format [expr {[unixtime]+$bt}] -format "%a %d %b %Y at %H:%M:%S %Z"])."
					}
				} else {
					putquick "MODE $channel +b $mask"
					newchanban $channel $mask $handle "$kmsg" [expr {[set bt [tduration $time]]/60}]
					if {$time == "0"} {
						putserv "NOTICE $nickname :Banmask '$mask' added to my banlist (Expires: Never!)."
					} else {
						putserv "NOTICE $nickname :Banmask '$mask' added to my banlist for $time (Expires: [clock format [expr {[unixtime]+$bt}] -format "%a %d %b %Y at %H:%M:%S %Z"])."
					}
				}
			}
		}
	}

	proc unlock {channel lock modes} {
		variable flood
		if {![info exists flood([set channel [string tolower $channel]])]} { return }
		if {[botisop $channel]} {
			puthelp "MODE $channel -$lock+$modes"
		}
		unset flood($channel)
	}

	proc loaded {} {
		variable start; variable copyright
		loadmodules
		set modules [loadedmodules]
		set end [clock clicks]
		set ms [expr {(round($end) - round($start))/1000.0}]ms
		#putlog "$copyright - [llength $modules] module(s) loaded[expr {[llength $modules]>0  ? ": [join $modules ", "]" : ""}] - loaded in $ms!!"
		putlog "[getconf core script]: [getconf core version]_[getconf core verstxt] by [getconf core author] loaded in ${ms}! [llength $modules] module(s) loaded[expr {[llength $modules]>0  ? ": [join $modules ", "]" : ""}]."
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
	
	namespace ensemble create

}