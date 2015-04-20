proc kickban {nickname channel type {reason {}}} {
	variable kickmsg; variable bantime; global botnick
	if {![validchan $channel] || ![onchan $nickname]} { return 0 }
	set valid [list gban userban known badchan userkick defaultban clonescan badword authban protkick]
	if {[lsearch -exact $valid [set type [string tolower $type]]] eq -1} { return 0 }
	set banmask "*!*[string trimleft ~ [getchanhost $nickname]]"
	if {[string equal -nocase "*.users.quakenet.org" $banmask]} { set banmask "*!*@[lindex [split $banmask @] 1]" }
	if {![validbanmask $banmask]} { putlog "KICKBAN - ERROR: Invalid banmask \"$banmask\" (Channel: $channel - Nickname: $nickname - Type: $type)"; return }
	set kmsg [channel get $channel service_kmsg_$type]
	channel set $channel service_kid_$type [set kid [expr {[channel get $channel service_kid_$type]+1}]]
	set btime [channel get $channel service_btime_$type]
	if {$kmsg eq ""} {
		channel set $channel service_kmsg_$type $kickmsg($type)
	}
	if {$btime eq "" || $btime < 0} {
		channel set $channel service_btime_$type $bantime($type)
	}
	set global 0; set chanban 0; set map [list]
	lappend map ":channel: \{$channel\}"
	lappend map ":nickname: \{$nickname\}"
	lappend map ":botnick: \{$botnick\}"
	lappend map ":id: \{$kid\}"
	lappend map ":bantime: \{$btime\}"
	lappend map ":homechan: \{....\}"
	if {$type eq "gban"} {
		set global 1; set mode "-o+b $nickname $banmask"
	} elseif {$type eq "userban"} {
		set mode "-o+b $nickname $banmask"
	} elseif {$type eq "known"} {
		set mode "-o+b $nickname $banmask"; set chanban 1
	} elseif {$type eq "badchan"} {
		set mode "-o+b $nickname $banmask"; set chanban 1
	} elseif {$type eq "userkick"} {
		set mode ""; set chanban 1
	} elseif {$type eq "defaultban"} {
		set mode "-o+b $nickname $banmask"
	} elseif {$type eq "clonescan"} {
		set mode "-o+b $nickname $banmask"; set chanban 1
	} elseif {$type eq "badword"} {
		set mode "-o+b $nickname $banmask"; set chanban 1
	} elseif {$type eq "authban"} {
		set mode "-o+b $nickname $banmask"; set chanban 1
	} elseif {$type eq "protkick"} {
		# You are not allowed to :violate: on :channel: - (ID: :id:) - (by :homechan:)
		lappend map ":violate: \{....\}"
		set mode "-o+b $nickname $banmask"
	} else {
		return 0
	}
	if {$mode != ""} {
		putquick "MODE $channel $mode"
	}
	putquick "KICK $channel :$kmsg"
	if {$btime>=0} {
		if {$chanban} {
			timer 1 [list pushmode $channel -b $banmask]
		} else {
			newchanban $channel $banmask creator $kmsg $btime ?options?
		}
	}
}

proc deopkickban {channel nickname kickmsg} {
	if {![validchan $channel] || ![onchan $nickname $channel]} { return -1 }
	if {![botisop $channel]} { return 0 }
	if {$kickmsg == ""} { set kickmsg "You are BANNED from this channel." }
	set banmask *!*[string trimleft ~ [getchanhost $nickname $channel]]
	if {[string equal -nocase "*.users.quakenet.org" $banmask]} {
		set banmask *!*@[lindex [split $banmask @] 1]
	}
	if {[isop $nickname $channel]} {
		putquick "MODE $channel -o+b $nickname $banmask"
	} else {
		putquick "MODE $channel +b $banmask"
	}
	putquick "KICK $channel :$kickmsg"
	return 1
}