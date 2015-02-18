proc badchan_add {channel nickname handle lastbind text} {
	set chan [lindex [split $text] 0]
	if {$chan == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind #channel."
	} else {
		if {[string index $chan 0] != "#"} {
			set chan "#$chan"
		}
		if {[string equal -nocase $chan $channel]} {
			putserv "NOTICE $nickname :Error: You can't bad channel your own channel!"
			return
		}
		if {[string equal -nocase $[namespace parent]::homechan $chan] || [string equal -nocase $[namespace parent]::adminchan $chan] || [string equal -nocase $[namespace parent]::helpchan $chan]} {
			putserv "NOTICE $nickname :Error: Can't add '$chan' to my bad channel list. (Protected channel)"
			return
		}
		set found 0
		set list [list]
		foreach bchan [channel get $channel service_badchans] {
			if {$bchan == ""} { continue }
			if {[string equal -nocase $chan $bchan]} {
				putserv "NOTICE $nickname :Bad Channel '$chan' is already added."
				set found 1
			} else {
				lappend list "$bchan"
			}
		}
		if {!$found} {
			channel set $channel service_badchans "[channel get $channel service_badchans] $chan"
			putserv "NOTICE $nickname :Bad Channel '$chan' added successfully."
		}
	}
}