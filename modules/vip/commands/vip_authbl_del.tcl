proc vip_authbl_del {channel nickname handle lastbind text} {
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
		putserv "NOTICE $nickname :Vip authname '$authname' is not blacklisted."
	} else {
		set blist [lreplace $blist $index $index]
		channel set $channel service_vip_authblist $blist
		putserv "NOTICE $nickname :Vip authname '$authname' was successfully removed from my blacklist."
	}
}