# load event handlers
variable events [globr scripts/service/core/events/ *.tcl]
if {[llength $events] <= 0} {
	putlog "No event handlers detected"; return
} else {
	#putlog "Detected [llength $event] event handler(s): [join $events ", "]"
	foreach handler $events {
		if {$handler eq ""} { continue }
		set name [lindex [split [file tail $handler] .] 0]
		#putlog "Attempting to load '$name' event handler (Path: $handler):"
		if {[catch {source $handler} err]} {
			putlog "Error loading event handler '$name' (Path: $handler):"
			foreach li $err {
				putlog "${name} error: $li"
			}
			putlog "${name} end of error."
		} else {
			putlog "${name} event handler successfully loaded."
		}
	}
}

foreach channel [channels] {
	if {[botonchan $channel]} {
		if {[set tmp [getnetworkservice $channel "chanserv"]] != ""} {
			channel set $channel service_servicebot $tmp
		}
	}
	foreach ban [list *!*@ *!*@* *!**@ *!**@* *@*] {
		catch {killchanban $channel $ban}
		pushmode $channel -b $ban
	}
	flushmode $channel
}

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

proc putservlog {text} {
	global botnick
	if {![file isdir [file join [pwd]/logs/service $botnick]]} {
		file mkdir -force [file join [pwd]/logs/service $::botnick]
	}
	set file [open [file join [pwd]/logs/service $::botnick [clock format [unixtime] -format %d%m%y].log] a]
	puts $file "\[[clock format [unixtime] -format %H:%M:%S]\] $text"
	close $file
}