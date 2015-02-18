proc authban_add {channel nickname handle lastbind text} {
	set auth [lindex [split $text] 0]
	if {$auth == ""} {
		putserv "NOTICE $nickname :Syntax: $lastbind <authname>."
	} elseif {[regexp -- {(.+)!(.+)@(.+)} $auth]} {
		putserv "NOTICE $nickname :Error: Your input matches a hostmask layout, if you want to ban a hostmask please use the BAN command."
	} else {
		if {[string match -nocase *users.quakenet.org $hostname] && [string equal -nocase $auth [lindex [split [lindex [split $hostname @] 1] .] 0]]} {
			putserv "NOTICE $nickname :Error: You can't ban your own authname!"
			return
		}
		if {[matchattr [finduser *!*@$auth.users.quakenet.org] ADnmobSBF|nmovfS $channel]} {
			putserv "NOTICE $nickname :Error: You can't ban this authname - Protected authname."
			return
		}
		set found 0
		set list [list]
		foreach bauth [channel get $channel service_authbans] {
			if {$bauth == ""} { continue }
			if {[string equal -nocase $auth $bauth]} {
				putserv "NOTICE $nickname :Authname '$auth' is already added."
				set found 1
			} else {
				lappend list "$bauth"
			}
		}
		if {!$found} {
			channel set $channel service_authbans "[channel get $channel service_authbans] $auth"
			putserv "NOTICE $nickname :Authname '$auth' added successfully."
		}
	}
}