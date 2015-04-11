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