service::commands::register errorinfo 1000 errorinfo_cmd

proc errorinfo_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	array set options {
		{clear} {0}
		{notice} {0}
		{quick} {0}
	}
	for {set i 0; set unknown [list]; set tonick $text} {$i < [llength $text]} {incr i} {
		set opt [lindex [split $text] $i]
		if {$opt eq "--"} { break }
		if {[string equal -nocase "-c" $opt] || [string equal -nocase "--clear" $opt]} {
			set options(clear) [expr {1-$options(clear)}]; set tonick [lreplace $text $i $i]
		} elseif {[string equal -nocase "-n" $opt] || [string equal -nocase "--notice" $opt]} {
			set options(notice) [expr {1-$options(notice)}]; set tonick [lreplace $text $i $i]
		} elseif {[string equal -nocase "-q" $opt] || [string equal -nocase "--quick" $opt]} {
			set options(quick) [expr {1-$options(quick)}]; set tonick [lreplace $text $i $i]
		} elseif {[string range $opt 0 1] eq "--"} {
			lappend unknown [string range $opt 2 end]
		}
	}
	if {[llength $unknown] >= 1} {
		putserv "NOTICE $nickname :ERROR: Unknown option(s) specified: [join $unknown ", "]. (Available options: [lsort [join [array names options] ", "]])"; return
	}
	if {![info exists ::errorInfo]} {
		putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] No errorInfo set."; return
	}
	if {$options(clear)} {
		catch {unset ::errorInfo}
		putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] errorInfo cleared."; return
	}
	if {[llength [split $::errorInfo \n]] > 1} {
		if {$options(quick)} {
			putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] Multi-line error:"
		} else {
			puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] Multi-line error:"
		}	
		foreach line [split $::errorInfo \n] {
			if {$line eq ""} { continue }
			if {$options(quick)} {
				putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :$line"
			} else {
				puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :$line"
			}
		}
		if {$options(quick)} {
			putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] End of multi-line error."
		} else {
			puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] End of multi-line error."
		}
	} else {
		if {$options(quick)} {
			putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] $result"
		} else {
			puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[\$::errorInfo\] $result"
		}
	}
}