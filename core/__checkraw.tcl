proc checkraw {from raw arg} {
	variable homechan; variable adminchan; variable helpchan
	# 471 = channel is full
	# 473 = channel is invite-only
	# 474 = banned from channel
	# 475 = channel is +k
	# 477 = channel is +r
	# 479 = glined channel
	if {[string equal -nocase $homechan [lindex [split $arg] 0]]} { return 0 }
	if {[string equal -nocase $adminchan [lindex [split $arg] 0]]} { return 0 }
	if {[string equal -nocase $helpchan [lindex [split $arg] 0]]} { return 0 }
	switch -exact -- $raw {
		"471" - "473" - "474" - "475" {
			#if {[info exists service::errorcount([set channel [string tolower [lindex [split $arg] 1]]]:rejoin)]} {
				#    set count [expr {$service::errorcount($channel:rejoin) + 1}]
				#    set service::errorcount($channel:rejoin) "$count"
				#    if {$count >= "10"} {]
					#        putserv "PRIVMSG $service::adminchan :.suspend service $channel $service::suspend(rejoin)"
					#		catch {unset service::errorcount($channel:rejoin)}
					#    }
				#} else {
				#    set service::errorcount($channel:rejoin) "1"
				#}
		}
		"477" {
			putserv "PRIVMSG $adminchan :\00304ERROR\00304: I could not join [set channel [string tolower [lindex [split $arg] 1]]] (+r) - Im not authed!"
		}
		"479" {
			#putserv "PRIVMSG $adminchan :.suspend service [set channel [string tolower [lindex [split $arg] 1]]] $service::suspend(glined)"
			putserv "PRIVMSG $adminchan :Gline/Badchan reason for ${channel}: (Glined: [lrange $arg 1 end])."
		}
		"default" {
			#putserv "PRIVMSG $adminchan :Non-monitored raw line found - $from: $raw $arg."
		}
	}
	return 0
}