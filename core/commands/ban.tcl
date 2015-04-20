service::commands::register ban,kb 400 [namespace current]::ban_cmd

proc ban_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set mask [lindex [split $text] 0]
	set time [lindex [split $text] 1]
	set reason [lrange $text 2 end]
	if {$mask == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind nickname|ip|hostname ?bantime? ?reason?. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
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