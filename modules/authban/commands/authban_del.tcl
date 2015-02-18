proc authban_del {channel nickname handle lastbind text} {
	set auth [lindex [split $text] 0]
	if {$auth == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind <authname>."
	} elseif {[regexp -- {(.+)!(.+)@(.+)} $auth]} {
		putserv "NOTICE $nickname :Error: Your input matches a hostmask layout, if you want to unban a hostmask please use the UNBAN command."
	} else {
		set found 0
		set list [list]
		foreach bauth [channel get $channel service_authbans] {
			if {$bauth == ""} { continue }
			if {[string equal -nocase $auth $bauth]} {
				set found 1
			} else {
				lappend list "$bauth"
			}
		}
		if {$found} {
			channel set $channel service_authbans "[join $list " "]"
			putserv "NOTICE $nickname :Removed authname '$auth' successfully."
		} else {
			putserv "NOTICE $nickname :Authname '$auth' is not added."
		}
	}
}