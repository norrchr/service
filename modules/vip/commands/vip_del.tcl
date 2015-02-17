proc vip_del {channel nickname handle lastbind text} {
	set chan [lindex [split $text] 1]
	if {$chan == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind $option #channel."
	} else {
		if {[string index $chan 0] != "#"} {
			set chan "#$chan"
		}
		set vlist [string tolower [channel get $channel service_vipc]]
		set index "-1"
		foreach x $vlist {
			if {$x == ""} { continue }
			if {[string equal -nocase $chan [string range $x 1 end]]} {
				set index [lsearch -exact $vlist $x]; break
			}
		}
		if {$index == "-1"} {
			putserv "NOTICE $nickname :Vip channel '$chan' does not exist."
		} else {
			set vlist [lreplace $vlist $index $index]
			channel set $channel service_vipc $vlist
			if {[info exists service::vip::vipchannels([string tolower $channel],[string tolower $chan])]} {
				unset service::vip::vipchannels([string tolower $channel],[string tolower $chan])
			}
			putserv "NOTICE $nickname :Vip channel '$chan' was removed successfully."
		}
	}
}