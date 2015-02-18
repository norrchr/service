proc badchan_list {channel nickname handle lastbind text} {
	set total 0
	set list [list]
	foreach bchan [channel get $channel service_badchans] {
		if {$bchan == ""} { continue }
		incr total
		lappend list "$bchan"
		if {[llength $list] == "20"} {
			putserv "NOTICE $nickname :[join $list ", "]"
			set list [list]
		}
	}
	if {[llength $list] > 0} {
		putserv "NOTICE $nickname :[join $list ", "]."
		set list [list]
	}
	putserv "NOTICE $nickname :End of bad channels list. (Total: $total)"
}