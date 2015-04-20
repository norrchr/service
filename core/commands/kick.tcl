service::commands::register kick 400 [namespace current]::kick_cmd

proc kick_cmd {nickname hostname handle channel text} {
	global lastbind; variable kickmsg; variable defaultreason
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set who [lindex [split $text] 0]
	set reason [lrange $text 1 end]
	if {$who == ""} {
		putserv "NOTICE $nickname :SYNTAX: $lastbind nickname \?reason\?."
	} elseif {![onchan $who $channel]} {
		putserv "NOTICE $nickname :$who isn't on $channel."
	} elseif {![botisop $channel]} {
		putserv "NOTICE $nickname :I need op to do that!"
	} elseif {[isbotnick $who]} {
		putserv "NOTICE $nickname :You can't kick me!"
	} elseif {[isnetworkservice $who]} {
		putserv "NOTICE $nickname :You can't kick a network service!"
	} else {
		if {[channel get $channel service_kickmsg_kick] == ""} {
			channel set $channel service_kickmsg_kick "$kickmsg(userkick)"
		}
		channel set $channel service_kid "[expr {[channel get $channel service_kid] + 1}]"
		set kmsg [channel get $channel service_kickmsg_kick]
		set id [channel get $channel service_kid]
		regsub -all :nickname: $kmsg $nickname kmsg
		regsub -all :channel: $kmsg $channel kmsg
		if {$reason == ""} {
			regsub -all :reason: $kmsg "$defaultreason" kmsg
		} else {
			regsub -all :reason: $kmsg "$reason" kmsg
		}
		regsub -all :id: $kmsg $id kmsg
		putquick "KICK $channel $who :$kmsg"
	}
}