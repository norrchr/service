proc vip_authbl_add {channel nickname handle lastbind text} {
	set authname [string tolower [lindex [split $text] 0]]
	if {$authname == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind <authname>."
		return
	}
	set blist [string tolower [channel get $channel service_vip_authblist]]
	set index "-1"
	foreach x $blist {
		if {$x == ""} { continue }
		if {[string equal -nocase $authname $x]} {
			set index [lsearch -exact $blist $x]; break
		}
	}
	if {$index == "-1"} {
		lappend $blist $authname
		channel set $channel service_vip_authblist $blist
		putserv "NOTICE $nickname :Vip authname '$authname' was successfully blacklisted."
	} else {
		putserv "NOTICE $nickname :Vip authname '$authname' is already blacklisted."
	}
}