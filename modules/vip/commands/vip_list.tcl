proc vip_list {channel nickname handle lastbind arg} {
	set status [lindex [split $text] 1]
	if {$status != "" && ($status != "@" || $status != "+")} {
		putserv "NOTICE $nickname :Invalid status '$status'. Status must be one of '@ +'."; return
	}
	set total [llength [channel get $channel service_vipc]]
	set i 0; set op 0; set voice 0; set list [list]
	foreach vchan [channel get $channel service_vipc] {
		if {$vchan == ""} { continue }
		if {$status != "" && [string equal -nocase $status [string index $vchan 0]]} {
			lappend list $vchan; incr i
		} else {
			if {[string index $vchan 0] == "@"} {
				incr op
			} else {
				incr voice
			}
			lappend list "$vchan"
		}
		if {[llength $list] == "20"} {
			putserv "NOTICE $nickname :[join $list ", "]"
			set list [list]
		}
	}
	if {[llength $list] > 0} {
		putserv "NOTICE $nickname :[join $list ", "]."
	}
	if {$status != ""} {
		putserv "NOTICE $nickname :End of vip list. (${i}/$total $status)"
	} else {
		putserv "NOTICE $nickname :End of vip list. (Total: $total - @: $op - +: $voice)"
	}
}