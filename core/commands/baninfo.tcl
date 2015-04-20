service::commands::register baninfo 400 [namespace current]::baninfo_cmd

proc baninfo_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {$text == ""} { putserv "NOTICE $nickname :Syntax: $lastbind -global|-chan #id|hostmask."; return }
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