proc info_mode {nickname hostname handle channel mode victim {reason ""}} {
	global botnick botname; variable adminchan
	if {$nickname == ""} {
		set nickname "$hostname"
	}
	if {$mode == "+o" && [string equal -nocase $botnick $victim]} {
		putserv "PRIVMSG $adminchan :\00307\002INFO:\002 \003I've been \002OPED\002 on \002$channel\002 by \002$nickname\002"
	} elseif {$mode == "-o" && [string equal -nocase $botnick $victim]} {
		putserv "PRIVMSG $adminchan :\00307\002INFO:\002 \003I've been \002DEOPED\002 on \002$channel\002 by \002$nickname\002"
	} elseif {$mode == "+b" && [string match -nocase "*[lindex [split $botname @] 1]*" "*$victim*"]} {
		putserv "PRIVMSG $adminchan :\00304\002ERROR:\002 \003I've been \002BANNED\002 on \002$channel\002 by \002$nickname\002"
	} elseif {$mode == "kick" && [string equal -nocase $botnick $victim] && [info exists reason]} {
		putserv "PRIVMSG $adminchan :\00304\002ERROR:\002 \003I've been \002KICKED\002 on \002$channel\002 by \002$nickname\002 with the reason: \002[stripcodes bcu $reason]\002"
	}
	return 0
}