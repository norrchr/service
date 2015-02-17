proc vip_authbl_list {channel nickname handle lastbind text} {
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