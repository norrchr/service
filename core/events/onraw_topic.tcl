proc onraw_topic {from raw arg {lookup 0}} {
	global botnick server; variable kickmsg; variable homechan
	set channel [lindex [split $arg] 0]
	set nickname [lindex [split $from !] 0]
	set hostname [lindex [split $from !] 1]
	#set authname [service authname nick2auth $nickname]
	set handle [nick2hand $nickname]		
	#if {$handle == "*" && $authname == "" && $lookup == 0} {
	#	putlog "onraw_topic: Performing auth lookup for $nickname @ $channel"
	#	if {[set op [isop $nickname $channel]]} {
	#		putquick "MODE $channel -o $nickname" -next
	#	}
	#	if {[llength [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] <= 0} {
	#		set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],1) "$op KICK $arg"
	#		putquick "WHO $nickname n%nuhat,139" -next; return 0
	#	} else {
	#		set id [expr {[lindex [split [lindex [split [array names [namespace current]::authname::authlookup ${nickname},${channel},*]] end] ,] end] + 1}]
	#		set [namespace current]::authname::authlookup([string tolower $nickname],[string tolower $channel],$id) "$op KICK $arg"
	#		return 0
	#	}
	#} elseif {$lookup == 2} {
	#	set reop 1
	#} else {
	#	set reop 0
	#}
	#if {$authname != "" && [validuser $authname]} { set handle $authname }
	set topic [join [lindex [split [lrange $arg 1 end] :] 1]]
	if {[string equal -nocase [lindex [split $server :] 0] $hostname] || $nickname == ""} { return 0 }
	if {[string equal -nocase $botnick $nickname]} {
		if {[channel get $channel service_topic_save]} {
			channel set $channel service_topic_current "$topic"
		} elseif {[channel get $channel service_topic_force]} {
			if {[set topc [channel get $channel service_topic_current]] != ""} {
				if {![string equal $topc $topic]} {
					if {[channel get $channel service_topic_Q]} {
						putquick "PRIVMSG Q :SETTOPIC $channel $topc"
					} else {
						putquick "TOPIC $channel :$topc"
					}
				}
			} else {
				if {[channel get $channel service_topic_Q]} {
					putquick "PRIVMSG Q :SETTOPIC $channel No topic saved."
				} else {
					putquick "TOPIC $channel :No topic saved."
				}
			}
		}
	}
	if {([channel get $channel service_prot_hard] && [matchattr $handle nmNS|nmS $channel]) || [matchattr $handle nmNoS|nmoS $channel] && $topic != ""} {
		if {$reop && [botisop $channel] && ![isop $nickname $channel]} {
			putserv "MODE $channel +o $nickname"
		}
		if {[channel get $channel service_topic_save]} {
			channel set $channel service_topic_current "$topic"
			putserv "NOTICE $nickname :Done. $channel topic saved to '$topic'."
		} elseif {[channel get $channel service_topic_force]} {
			if {[set topc [channel get $channel service_topic_current]] != ""} {
				if {[channel get $channel service_topic_Q]} {
					putquick "PRIVMSG Q :SETTOPIC $channel $topc"
				} else {
					putquick "TOPIC $channel :$topc"
				}
			} else {
				if {[channel get $channel service_topic_Q]} {
					putquick "PRIVMSG Q :SETTOPIC $channel No topic saved."
				} else {
					putquick "TOPIC $channel :No topic saved."
				}
			}
			putserv "NOTICE $nickname :ERROR: $channel topic is forced. (Use '$::botnick topic' to set the topic)"
		}
	} elseif {[channel get $channel service_prot] && ![channel get $channel service_startup]} {
		if {[string match -nocase *users.quakenet.org [set hostname *!*[string trimleft $hostname ~]]]} {
			set hostname *!*@[lindex [split $hostname @] 1]
		}
		if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
			channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
		}
		channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
		regsub -all :violate: $kmsg "\002\037change the topic\037\002" kmsg
		regsub -all :channel: $kmsg "$channel" kmsg
		regsub -all :id: $kmsg "$id" kmsg
		regsub -all :homechan: $kmsg "$homechan" kmsg
		set ban 1
		if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { set ban 0 }
		if {$ban && ![validbanmask $hostname]} { set ban 0 }
		if {[botisop $channel] && [onchan $nickname $channel]} {
			if {$ban} {
				putquick "MODE $channel -o+b $nickname $hostname"
			} else {
				putquick "MODE $channel -o $nickname"
			}
			putquick "KICK $channel $nickname :$kmsg"
		}
		if {$ban} {
			newchanban $channel $hostname $botnick "$kmsg" 120
		}
		if {[set topc [channel get $channel service_topic_current]] != ""} {
			if {[channel get $channel service_topic_Q]} {
				putquick "PRIVMSG Q :SETTOPIC $channel $topc"
			} else {
				putquick "TOPIC $channel :$topc"
			}
		} else {
			if {[channel get $channel service_topic_Q]} {
				putquick "PRIVMSG Q :SETTOPIC $channel No topic saved."
			} else {
				putquick "TOPIC $channel :No topic saved."
			}
		}
	}
	return 0
}