proc tduration {string} {
	set result "0"
	array set duration {
		{minute} {60}
		{hour} {3600}
		{day} {86400}
		{week} {604800}
		{month} {2419200}
		{year} {31536000}
	}
	if {[regexp -nocase -- {([\d]{1,})m} $string full minute]} {
		set result "[expr {$result+($duration(minute)*$minute)}]"
	}
	if {[regexp -nocase -- {([\d]{1,})h} $string full hour]} {
		set result "[expr {$result+($duration(hour)*$hour)}]"
	}
	if {[regexp -nocase -- {([\d]{1,})d} $string full day]} {
		set result "[expr {$result+($duration(day)*$day)}]"
	}
	if {[regexp -nocase -- {([\d]{1,})w} $string full week]} {
		set result "[expr {$result+($duration(week)*$week)}]"
	}
	if {[regexp -nocase -- {([\d]{1,})y} $string full year]} {
		set result "[expr {$result+($duration(year)*$year)}]"
	}
	return "$result"
}

proc btduration {string} {
	if {![regexp -- {[0-9]+(s|m|h|d|w|y)} $string]} { return 0 }
	set duration 0
	if {[regexp -- {([0-9]+)s} $string -> number]} {
		set duration [expr {$duration+$number}]
	}
	if {[regexp -- {([0-9]+)m} $string -> number]} {
		set duration [expr {$duration+($number*60)}]
	}
	if {[regexp -- {^([0-9]+)h$} $string -> number]} {
		set duration [expr {$duration+($number*3600)}]
	}
	if {[regexp -- {^([0-9]+)d$} $string -> number]} {
		set duration [expr {$duration+($number*86400)}]
	}
	if {[regexp -- {^([0-9]+)w$} $string -> number]} {
		set duration [expr {$duration+($number*604800)}]
	}
	if {[regexp -- {^([0-9]+)y$} $string -> number]} {
		set duration [expr {$duration+($number*31536000)}]
	}
	if {[regexp -- {-} $duration]} {
		return 0
	}
	return $duration
}