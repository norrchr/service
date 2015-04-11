proc onpart {nickname hostname handle channel {reason {}}} {
	if {[isbotnick $nickname]} {
		foreach user [chanlist $channel] {
			if {[validuser [set handle [nick2hand $user]]] && ([getuser $handle XTRA loggedin]=="1" || [getuser $handle XTRA loggedin] == "") && ![onchan $user]} {
				setuser $handle XTRA loggedin 0
			}
		}
		return 0
	} elseif {([getuser $handle XTRA loggedin]=="1" || [getuser $handle XTRA loggedin] == "") && ![onchan $nickname]} {
		setuser $handle XTRA loggedin 0
	}
	if {[isnetworkservice $nickname] && [ischannelservice $nickname]} {
		channel set $channel +service_netsplit
		channel set $channel service_servicebot ""
		return 0
	}
	if {[channel get $channel service_flyby] && ![matchattr $handle nmovfS|nmovfS $channel] && [botisop $channel] && [expr {[clock seconds] - [getchanjoin $nickname $channel]}] < 10} {
		if {[string match -nocase *users.quakenet.org [set hostname *!*[string trimleft $hostname ~]]]} {
			set hostname *!*@[lindex [split $hostname @] 1]
		}
		pushmode $channel +b $hostname
		utimer 300 [list pushmode $channel -b $hostname]
	}
	if {[channel get $channel service_autolimit]} {
		if {[string match *l* [getchanmode $channel]]} {
			if {[string match *k* [getchanmode $channel]]} {
				set curr [lindex [split [getchanmode $channel]] 2]
			} else {
				set curr [lindex [split [getchanmode $channel]] 1]
			}
			set newlimit [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]
			if {$newlimit == "$curr"} { return }
			if {[expr {$newlimit - $curr}] == "3" || [expr {$newlimit - $curr}] == "-3"} {
				pushmode $channel +l $newlimit
			}
		} else {
			pushmode $channel +l [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]
		}
	}
	return 0
}