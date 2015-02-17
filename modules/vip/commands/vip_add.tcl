proc vip_add {channel nickname handle lastbind text} {
	set chan [lindex [split $text] 1]
	set status [lindex [split $text] 2]
	if {$chan == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind $option #channel @/+."
	} else {
		if {[string index $chan 0] != "#"} {
			set chan "#$chan"
		}
		if {$status == ""} {
			set status "@"
		}
		if {![regexp {^\@|\+$} $status]} {
			putserv "NOTICE $nickname :Vip status must be one of '@ +'. (@ means ops only | + means both ops and voice)"
			return
		}
		set vlist [string tolower [channel get $channel service_vipc]]
		set index ""
		foreach x $vlist {
			if {$x == ""} { continue }
			if {[string equal -nocase $chan [string range $x 1 end]]} {
				set index [lsearch -exact $vlist $x]; break
			}
		}
		if {$index == ""} {
			lappend vlist ${status}${chan}
			channel set $channel service_vipc $vlist
			set service::vip::vipchannels([string tolower $channel],[string tolower $chan]) $status
			putserv "NOTICE $nickname :Vip channel '$chan' has been added with status '$status' successfully."
		} else {
			set vstatus [string index [lindex [split $vlist] $index] 0]
			if {$vstatus == $status} { 
				putserv "NOTICE $nickname :Vip channel '$chan' is already added as status '$status'."
			} else {
				set vlist [lreplace $vlist $index $index ${status}${chan}]
				channel set $channel service_vipc $vlist
				putserv "NOTICE $nickname :Vip channel '$chan' was already added as status '$vstatus' but has now been modifed to '$status'."
			}
		}
	}
}