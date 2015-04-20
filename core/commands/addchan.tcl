service::commands::register addchan,join,+chan 950 [namespace current]::addchan_cmd

proc addchan_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {[set chan [lindex [split $text] 0]] == "" || [string index $chan 0] != "#"} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind #channel."
	} elseif {[validchan $chan]} {
		putserv "NOTICE $nickname :$chan is already added to my channel list."
	} elseif {[llength [channels]] >= "20"} {
		putserv "NOTICE $nickname :Im full up! I have ([llength [channels]]/20) channels in my list."
	} else {
		channel add $chan
		chattr $handle |+amnov $chan
		putserv "NOTICE $nickname :Channel ($chan) successfully added to my channel list."
	}
}