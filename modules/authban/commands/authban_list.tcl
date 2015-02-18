proc authban_list {channel nickname handle lastbind text} {
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