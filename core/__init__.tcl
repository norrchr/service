namespace eval core {

	# on evnt
	source scripts/service/core/onevnt.tcl

	# autosave
	source scripts/service/core/autosave.tcl

	foreach user [userlist] {
		if {$user == ""} { return }
		if {[getuser $user XTRA mytrigger] == ""} {
			setuser $user XTRA mytrigger "$[namespace parent]::trigger"
			setuser $user XTRA mytriggerset "[clock seconds]"
		}
		if {[getuser $user XTRA mytriggerset] == ""} { 
			setuser $user XTRA mytriggerset "[clock seconds]"
		}
		if {[getuser $user XTRA userid] == ""} {
			channel set $adminchan service_userid "[set userid [expr {[channel get $[namespace parent]::adminchan service_userid]+1}]]"
			setuser $user XTRA userid "$userid"
		}
		if {[getuser $user XTRA loggedin] == ""} {
			setuser $user XTRA loggedin 0
		}
		if {[getuser $user XTRA lasthost] == ""} {
			setuser $user XTRA lasthost "N/A"
		}
		if {[getuser $user XTRA email] == ""} {
			setuser $user XTRA email "N/A"
		}
		if {[getuser $user XTRA cmdcount] == ""} {
			setuser $user XTRA cmdcount 0
		}
		if {[getuser $user XTRA lastcmd] == ""} {
			setuser $user XTRA lastcmd "N/A"
		}
	}
	
}