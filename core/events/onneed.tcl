proc onneed {channel type} {
	set homechan [getconf core homechan]
	set adminchan [getconf core adminchan]
	set helpchan [getconf core helpchan]
	switch -exact -- $type {
		"op" {
			if {[string equal -nocase $homechan $channel]} { return 0 }
			if {[string equal -nocase $adminchan $channel]} { return 0 }
			if {[string equal -nocase $helpchan $channel]} { return 0 }
			putquick "PRIVMSG Q :OP $channel" -next
		}
		"unban" {
			if {[botonchan $channel] && ![botisop $channel]} {
				putquick "PRIVMSG Q :UNBANALL $channel" -next
			} else {
				putquick "PRIVMSG Q :INVITE $channel" -next
			}
		}
		"invite" {
			putquick "PRIVMSG Q :INVITE $channel" -next
		}
		"limit" {
			putquick "PRIVMSG Q :INVITE $channel" -next
		}
		"key" {
			putquick "PRIVMSG Q :INVITE $channel" -next
		}
	}
	return 0
}
