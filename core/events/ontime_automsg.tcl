proc ontime_automsg {min hour day month year} {
	foreach channel [channels] {
		if {$channel == "" || ![botonchan $channel] || ![channel get $channel service_automsg]} { continue }
		set interval [channel get $channel service_automsg_interval]
		set counter [expr {[channel get $channel service_automsg_counter]+1}]
		#putlog "automsg: $channel -> $counter => $interval"
		if {$counter>=$interval} {
			channel set $channel service_automsg_counter 0
		} else {
			channel set $channel service_automsg_counter $counter; continue
		}
		set messages [channel get $channel service_automsg_messages]
		if {[llength $messages]<=0} { continue }
		set last [channel get $channel service_automsg_last]
		set moderate [channel get $channel service_automsg_moderate]
		set method [string tolower [channel get $channel service_automsg_method]]
		set maps [channel get $channel service_automsg_maps]
		if {![string is integer $last]} { set last -1 }
		if {$last>[llength $messages]} { set last -1 }			
		if {$method eq "random" || $method eq "rand"} {
			incr last
			if {[llength $messages]==1} {
				set last 0
			} else {
				if {$last>[llength $messages]} { set last 1 }
				if {$last>=0} { set messages [lreplace $messages $last-1 $last-1] }
				if {[set id [expr {[rand [llength $messages]]-1}]]<0} { set last 0 }
				if {$id>[llength $messages]} { set id 0 }
			}
			channel set $channel service_automsg_last [set id $last]
			set message \{[lindex $messages $id]\}
		} elseif {$method eq "loop" || $method eq "line"} {
			incr last
			if {$last == [llength $messages]} {
				set id $last
				if {$id<0 || $id>[expr {[llength $messages]-1}]} {
					set id 0
				}
			} elseif {$last > [llength $messages]} {
				set id 0
			} else {
				set id $last
				if {$id<0 || $id>[expr {[llength $messages]-1}]} {
					set id 0
				}
			}
			channel set $channel service_automsg_last $id
			set message \{[lindex $messages $id]\}
		} elseif {$method eq "default" || $method eq "multi" || $method eq "block" || $method eq "all" || $method eq ""} {
			set last -1
			channel set $channel service_automsg_last [set id $last]
			set message $messages
		}
		set color 0; set strip 0
		foreach msg $message {
			if {$msg eq ""} { continue }
			if {[string length [stripcodes bcu $msg]]<[string length $msg]} {
				set color 1; break
			}
		}
		set pre [list]; set post [list]
		set modes [getchanmode $channel]
		if {$color && [string match "*c*" $modes]} {
			lappend pre -c; lappend post +c
		}
		if {$moderate && ![string match "*m*" $modes]} {
			lappend pre +m; lappend post -m
		}
		if {[botisop $channel] && [llength $pre]>0} {
			putserv "MODE $channel [join $pre ""]"
		} elseif {![botisop $channel] && [string match "*c*" $modes] && $color} {
			set strip 1
		}
		set maps [linsert [linsert $maps end ":botnick: $::botnick"] end ":channel: $channel"]
		foreach msg $message {
			if {$msg eq ""} { continue }
			if {$strip} { set msg [stripcodes bcu $msg] }
			if {[llength $maps]>=1} {
				set msg [string map [join $maps] $msg]
			}
			foreach msg_ [split $msg \n] {
				if {$msg eq ""} { continue }
				putserv "PRIVMSG $channel :$msg_"
			}
		}
		if {[botisop $channel] && [llength $post]>0} {
			putserv "MODE $channel [join $post ""]"
		}
	}
	return 0
}