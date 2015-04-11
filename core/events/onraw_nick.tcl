proc onraw_nick {from raw arg} {
	set nickname [lindex [split $from !] 0]
	set hostname [string trimleft [lindex [split $from !] 1] ~]
	set newnick [string trimleft $arg :]
	set handle [nick2hand $newnick]
	onnick_global $nickname $hostname $handle $newnick
	foreach channel [channels] {
		onnick_channel $nickname $hostname $handle $channel $newnick
	}
	return 0
}
	
proc onnick_global {nickname hostname handle newnick} {
	variable authnames
	if {[info exists authnames($nickname)]} {
		set authnames($newnick) "$authnames($nickname)"
		unset authnames($nickname)
	}
	return 0
}

proc onnick_channel {nickname hostname handle channel newnick} {
	variable saveops
	set ch [string tolower $channel]; set ni [string tolower $nickname]; set ho [string trimleft [getchanhost $newnick $channel] ~]; set neni [string tolower $newnick]
	if {[info exists saveops(${ch},${ni}!${ho})]} {
		set saveops(${ch},${neni}!${ho}) "$saveops(${ch},${ni}!${ho})"
		unset saveops(${ch},${ni}!${ho})
	}
	return 0
}