service::commands::register saveops 450 [namespace current]::saveops_cmd

proc saveops_cmd {nickname hostname handle channel text} {
	global lastbind; variable saveops
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	array set options {
		{clear} {0}
		{save} {0}
		{op} {0}
		{list} {0}
	}
	foreach {opt} [split $text] {
		if {$opt eq ""} { continue }
		if {$opt eq "--"} { set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]; break }
		if {[string equal -nocase "-c" $opt] || [string equal -nocase "--clear" $opt]} {
			set options(clear) [expr {1-$options(clear)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
		} elseif {[string equal -nocase "-s" $opt] || [string equal -nocase "--save" $opt]} {
			set options(save) [expr {1-$options(save)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
		} elseif {[string equal -nocase "-o" $opt] || [string equal -nocase "--op" $opt]} {
			set options(op) [expr {1-$options(op)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
		} elseif {[string equal -nocase "-l" $opt] || [string equal -nocase "--list" $opt]} {
			set options(list) [expr {1-$options(list)}]; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
		} elseif {[string index $opt 0] eq "-" || [string range $opt 0 1] eq "--"} {
			lappend unknown $opt; set text [join [lreplace [split $text] [set r [lsearch -exact [split $text] $opt]] $r]]
		}
	}
	if {[info exists unknown]} {
		putserv "NOTICE $nickname :Unknown option(s) specified: [join $unknown " "]. (Available options: --[join [lsort [array names options]] ", --"])"; return
	}
	if {$options(clear)} {
		set conflict [list]
		if {$options(save)} { lappend conflict "save" }
		if {$options(list)} { lappend conflict "list" }
		if {$options(op)} { lappend conflict "op" }
		if {[llength $conflict]>=1} {
			putserv "NOTICE $nickname :ERROR: Options Conflict - You can not use '[join [lsort $conflict] " "]' along with 'clear'."; return
		}
	}
	if {$options(list)} {
		set conflict [list]
		if {$options(save)} { lappend conflict "save" }
		if {$options(clear)} { lappend conflict "clear" }
		if {$options(op)} { lappend conflict "op" }
		if {[llength $conflict]>=1} {
			putserv "NOTICE $nickname :ERROR: Options Conflict - You can not use '[join [lsort $conflict] " "]' along with 'list'."; return
		}
	}
	set c 0; set ch [string tolower $channel]
	if {$options(clear)} {
		foreach e [array names saveops $ch:*] {
			if {$e eq ""} { continue }
			unset saveops($e); incr c
		}
		putserv "NOTICE $nickname :Cleared '$c' saved op(s) for $channel."; return
	}
	if {$options(list)} {
		putserv "NOTICE $nickname :Saved op(s) list for $channel:"
		foreach e [lsort [array names saveops $ch,*]] {
			if {$e eq ""} { continue }
			set ni [lindex [split [lindex [split $e ,] 1] !] 0]
			set ho [lindex [split [lindex [split $e ,] 1] !] 1]
			set ts $saveops($e)
			putserv "NOTICE $nickname :$ni ($ho) saved [clock format $ts] ([duration [expr {[clock seconds]-$ts}]] ago)"
			incr c
		}
		putserv "NOTICE $nickname :End of saved op(s) list for $channel. ($c saved op(s))."; return
	}
	if {$options(op)} {
		if {![botisop $channel]} {
			putserv "NOTICE $nickname :ERROR: I need op on $channel to (re)op saved op(s)."; return
		}
		set opli [list]
		foreach e [array names saveops $ch,*] {
			if {$e eq ""} { continue }
			set ni [lindex [split [lindex [split $e ,] 1] !] 0]
			set ho [lindex [split [lindex [split $e ,] 1] !] 1]
			if {[onchan $ni $channel] && [string equal -nocase $ho [string trimleft [getchanhost $ni $channel] ~]] && ![isop $ni $channel]} {
				lappend opli $ni; incr c
			}
			unset saveops($e)
			if {[llength $opli]==6} {
				putserv "MODE $channel +oooooo [join $opli " "]"; set opli [list]
			}
		}
		if {[llength $opli]>=1} {
			putserv "MODE $channel +[string repeat "o" [llength $opli]] [join $opli " "]"; unset opli
		}
		if {!$options(save)} {
			putserv "NOTICE $nickname :Op'd $c saved op(s) on $channel. Saved op(s) list cleared, please use $lastbind --save to save the current channel ops."; return
		} else {
			set cc $c
		}
	}
	if {$options(save)} {
		set ts [clock seconds]
		foreach ni [chanlist $channel] {
			if {$ni eq ""} { continue }
			if {[isbotnick $ni] || ![isop $ni $channel]} { continue }
			set ho [string trimleft [getchanhost $ni $channel] ~]
			set e ${ni}!${ho}
			if {[info exists saveops(${ch},${e})]} { continue }
			set saveops(${ch},${e}) $ts; incr c
		}
		if {$options(op) && [info exists cc]} {
			putserv "NOTICE $nickname :Op'd $cc saved op(s) on $channel. Saved $c op(s) for $channel."
		} else {
			putserv "NOTICE $nickname :Saved $c op(s) for $channel."
		}
		return
	}
	putserv "NOTICE $nickname :Syntax: $lastbind ?--options?. (Available options: --[join [lsort [array names options]] ", --"])"
}