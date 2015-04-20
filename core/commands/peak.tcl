service::commands::register peak 0 peak_cmd

proc peak_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set status [channel get $channel service_peak]
	if {![matchattr $handle ADnm|nm $channel]} {
		if {$status} {
			putserv "NOTICE $nickname :The current peak for $channel is [channel get $channel service_peak_count]. It was set on [clock format [set ts [channel get $channel service_peak_time]]] ([duration [expr {[clock seconds]-$ts}]] ago) by [channel get $channel service_peak_nick]."
		} else {
			putserv "NOTICE $nickname :Peak is currently disabled for $channel."
		}
		return
	}
	set cmd [string tolower [lindex [split $text] 0]]
	if {$cmd eq "on" || $cmd eq "enable"} {
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
	} elseif {$cmd eq "off" || $cmd eq "disable"} {
		if {!$status} {
			putserv "NOTICE $nickname :Peak for $channel is already disabled."
		} else {
			channel set $channel -service_peak
			putserv "NOTICE $nickname :Peak for $channel is now disabled."
		}
	} elseif {$cmd eq "reset"} {
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
	} else {
		if {$cmd eq ""} {
			if {$status} {
				putserv "NOTICE $nickname :The current peak for $channel is [channel get $channel service_peak_count]. It was set on [clock format [set ts [channel get $channel service_peak_time]]] ([duration [expr {[clock seconds]-$ts}]] ago) by [channel get $channel service_peak_nick]."
			} else {
				putserv "NOTICE $nickname :Peak is currently disabled for $channel."
			}
		} else {
			putserv "NOTICE $nickname :Syntax: $lastbind on|off|reset."
		}
	}
}					