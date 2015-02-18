proc badchan_del {channel nickname handle lastbind text} {
	set chan [lindex [split $text] 0]
	if {$chan == ""} {
		putserv "NOTICE $nickname :Syntax: ${lastbind}$command $option del #channel."
	} else {
		if {[string index $chan 0] != "#"} {
			set chan "#$chan"
		}
		set found 0
		set list [list]
		foreach bchan [channel get $channel service_badchans] {
			if {$bchan == ""} { continue }
			if {[string equal -nocase $chan $bchan]} {
				set found 1
			} else {
				lappend list "$bchan"
			}
		}
		if {$found} {
			channel set $channel service_badchans "[join $list " "]"
			putserv "NOTICE $nickname :Removed bad channel '$chan' successfully."
		} else {
			putserv "NOTICE $nickname :Bad Channel '$chan' is not added."
		}
	}
}