proc host2hand {host} {
	set who "*"
	foreach user [userlist] {
		if {[llength [getuser $user HOSTS]] > 1} {
			foreach mask [getuser $user HOSTS] {
				if {[string equal -nocase $host $mask]} {
					set who $user
					break
				}
			}
		} elseif {[string equal -nocase $host [getuser $user HOSTS]]} {
			set who $user
			break
		}
	}
	return "$who"
}

proc hand2nicks {handle} {
	set nicks [list]
	foreach channel [channels] {
		if {$channel == ""} { continue }
		foreach nick [chanlist $channel] {
			if {$nick == "" || [set x [nick2hand $nick]] == "" || $x == "*"} { continue }
			if {[string equal -nocase $handle $x]} {
				lappend nicks $nick
			}
		}
	}
	return [lsort -unique $nicks]
}