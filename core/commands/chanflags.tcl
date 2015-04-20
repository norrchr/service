service::commands::register chanflags 400 [namespace current]::chanflags_cmd

proc chanflags_cmd {nickname hostname handle channel text} {
	global lastbind; variable chanflags
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set flags [lindex [split $text] 0]
	array set current { {+} {} {-} {} }
	foreach {x y} [array get chanflags] {
		if {$x == "" || $y == ""} { continue }
		if {[channel get $channel [lindex [split $chanflags($x)] 0]]} {
			lappend current(+) $x
		} else {
			lappend current(-) $x
		}
	}
	if {$flags == ""} {
		putserv "NOTICE $nickname :Current: [join "+ [lsort -unique [join $current(+)]] - [lsort -unique [join $current(-)]]" ""]."
		putserv "NOTICE $nickname :SYNTAX: ${lastbind}$command +-flags. Available flags: [join [lsort -unique [array names chanflags]] ""]."
	} else {
		if {[string index $flags 0] != "+" && [string index $flags 0] != "-"} {
			set flags "+$flags"
		}
		set unknown [list]
		foreach flag [split $flags ""] {
			if {$flag == "" || $flag == "+" || $flag == "-"} { continue }
			if {![info exists chanflags($flag)]} {
				lappend unknown $flag
			}
		}
		if {[llength $unknown] > 0} {
			putserv "NOTICE $nickname :Invalid or disallowed flag(s) '[join $unknown ", "]' specified."
		} else {
			array set done { {+} {} {-} {} }
			set lastmode ""
			foreach flag [split $flags ""] {
				if {$flag == "+" || $flag == "-"} { 
					set lastmode "$flag"
					continue
				}
				if {$lastmode == "+" && ![channel get $channel [lindex [split $chanflags($flag)] 0]]} {
					lappend done(+) $flag
					channel set $channel +[lindex [split $chanflags($flag)] 0]
				} elseif {$lastmode == "-" && [channel get $channel [lindex [split $chanflags($flag)] 0]]} {
					lappend done(-) $flag
					channel set $channel -[lindex [split $chanflags($flag)] 0]
				}
			}
			array set after { {+} {} {-} {} }
			foreach {x y} [array get chanflags] {
				if {$x == "" || $y == ""} { continue }
				if {[channel get $channel [lindex [split $chanflags($x)] 0]]} {
					lappend after(+) $x
				} else {
					lappend after(-) $x
				}
			}
			putserv "NOTICE $nickname :Done. Before: [join "+ [lsort -unique $current(+)] - [lsort -unique $current(-)]" ""] - After: [join "+ [lsort -unique "$after(+) $done(+)"] - [lsort -unique "$after(-) $done(-)"]" ""] - Changes: [join "+ [lsort -unique $done(+)] - [lsort -unique $done(-)]" ""]."
		}
	}
}