proc giveopvoice {channel nickname} {
	if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
	if {![botisop $channel]} { return 0 }
	set m [list]
	if {![isop $nickname $channel]} { lappend m "o" }
	if {![isvoice $nickname $channel]} { lappend m "v" }
	if {[llength $v] >= 1} {
		putquick "MODE $channel +[join $m ""] [string repeat $nickname [llength $m]]"
	}
}

proc giveop {channel nickname} {
	if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
	if {![botisop $channel]} { return 0 }
	if {![isop $nickname $channel]} {
		putquick "MODE $channel +o $nickname"
	}
}

proc givevoice {channel nickname} {
	if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
	if {![botisop $channel]} { return 0 }
	if {![isvoice $nickname $channel]} {
		putquick "MODE $channel +v $nickname"
	}
}