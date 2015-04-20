service::commands::register clonescan 450 clonescan_cmd

proc clonescan_cmd {nickname hostname handle channel text} {
	global lastbind; variable bantime; variable clonescan; variable networkservices
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_clonescan]
	foreach {y z} "bantime $bantime(clonescan) maxclones $clonescan(maxclones) hosttype $clonescan(hosttype)" {
		if {[channel get $channel service_clonescan_$y] == "" && $z != ""} {
			channel set $channel service_clonescan_$y $z
		}
	}
	set option [lindex [split $text] 0]]
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