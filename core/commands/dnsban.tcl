service::commands::register dnsban,dkb 400 [namespace current]::dnsban_cmd

proc dnsban_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set mask [lindex [split $text] 0]
	set time [lindex [split $text] 1]
	set reason [lrange $text 2 end]
	if {![regexp {^[\d]{1,}(m|h|d|w|y)$|^0$} $time]} {
		set time "1h"
		set reason [lrange $text 1 end]
	}
	if {$mask == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind nickname|ip|hostname ?bantime? ?reason?. Bantime format: XmXhXdXwXy (Where 'X' must be a number - For permban specify '0' on its own)."
		return
	}
	if {[regexp {(.+)!(.+)@(.*?)} $mask]} {			
		#!validbanmask $mask
		if {$mask == "*!*@*" || $mask == "*!*@" || $mask == "*!**@" || $mask == "*!**@*"} {
			putserv "NOTICE $nickname :Invalid banmask '$mask'."
		} else {
			putserv "NOTICE $nickname :Performing DNS lookup on '$mask'..."
			dnslookup [lindex [split $mask @] 1] ::service::dnslookup_ban $mask $nickname $handle $channel $time $reason $lastbind
		}
	} elseif {[onchan $mask $channel]} {
		if {[string equal -nocase $botnick $mask]} {
			putserv "NOTICE $nickname :You can't ban me!"; return
		} 
		set uh [getchanhost $mask $channel]
		if {[string equal -nocase "*.users.quakenet.org" $uh]} {
			set bmask *!*@[lindex [split $uh @] 1]
			dnslookup_ban {} {} 2 $mask $nickname $handle $channel $time $reason $lastbind
		} else {
			set bmask *!*$uh
			putserv "NOTICE $nickname :Performing DNS lookup on '$uh'..."
			dnslookup [lindex [split $uh @] 1] ::service::dnslookup_ban $mask $nickname $handle $channel $time $reason $lastbind
		}
	} else {
		putserv "NOTICE $nickname :ERROR: '$mask' is not on $channel."
	}
}