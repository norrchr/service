proc onraw {from raw arg} {
	if {[string equal -nocase "MODE" $raw]} {
		onraw_mode $from $raw $arg; return 0
	} elseif {[string equal -nocase "KICK" $raw]} {
		onraw_kick $from $raw $arg; return 0
	} elseif {[string equal -nocase "TOPIC" $raw]} {
		onraw_topic $from $raw $arg; return 0
	} elseif {[string equal -nocase "NICK" $raw]} {
		onraw_nick $from $raw $arg; return 0
	} elseif {[string equal -nocase "INVITE" $raw]} {
		onraw_invite $from $raw $arg; return 0
	} elseif {$raw == "319" || $raw == "330" || $raw == "318"} {
		return 0
	} elseif {$raw == "315"} {
		# end of WHO
		set channel [lindex [split $arg] 1]
		if {[validchan $channel] && [channel get $channel service_startup]} {
			channel set $channel -service_startup; return
		}; return 0
	}
	return 0
}