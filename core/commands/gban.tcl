service::commands::register gban 850 [namespace current]::gban_cmd

proc gban_cmd {nickname hostname handle channel text} {
	global lastbind; variable homechan; variable adminchan; variable kickmsg
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set mask [lindex [split $text] 0]
	set time [lindex [split $text] 1]
	set reason [lrange $text 2 end]
	if {$mask == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind nickname|hostname ?bantime? ?reason?. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
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