proc onraw_invite {from raw arg} {
	global botnick; variable adminchan; variable homechan
	set nickname [lindex [split $from !] 0]
	set hostname [lindex [split $from !] 1]
	if {[string equal -nocase $botnick [lindex [split $arg] 0]] && [string index [set channel [lindex [split $arg] 1]] 0] == "#"} {
		putserv "PRIVMSG $adminchan :\00307\002INFO:\002 \003I've been \002INVITED\002 by \002$nickname\002 to \002$channel\002"
		if {![validchan $channel]} {
			putserv "NOTICE $nickname :Your channel '${channel}' is unknown to me - Bot by $homechan."
		} else {
			putquick "JOIN $channel"
			puthelp "NOTICE $nickname :Invite successful - I (re)joined ${channel}."
		}
	}
	return 0
}