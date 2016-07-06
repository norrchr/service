proc onjoin {nickname hostname handle channel} {
	variable onjoin
	set homechan [getconf core homechan]
	# channel peak
	if {[channel get $channel service_peak] && [set peak [channel get $channel service_peak_count]]<[set count [llength [chanlist $channel]]]} {
		channel set $channel service_peak_count [set peak $count]
		channel set $channel service_peak_time [set ts [clock seconds]]
		channel set $channel service_peak_nick [set by $nickname]
		putserv "PRIVMSG $channel :New $channel peak $peak set by ${nickname}."
	}
	# XTRA events		
	if {[isbotnick $nickname]} {
		foreach user [chanlist $channel] {
			if {[validuser [set handle [nick2hand $user]]] && ([getuser $handle XTRA loggedin]=="0" || [getuser $handle XTRA loggedin]=="")} {
				setuser $handle XTRA loggedin 1
				setuser $handle XTRA lastlogin "[clock seconds]"
				setuser $handle XTRA lasthost "[string trimleft $hostname ~]"
			}
		}
		if {[set service [getnetworkservice $channel chanserv]] != ""} {
			channel set $channel -service_netsplit
			channel set $channel service_servicebot $service
			chattr [nick2hand $service] +S|+S $channel
		}
		if {[string match *l* [getchanmode $channel]]} {
			if {[string match *k* [getchanmode $channel]]} {
				channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 2]
			} else {
				channel set $channel service_chanmode_limit [lindex [split [getchanmode $channel]] 1]
			}
		}
		return 0
	} elseif {[getuser $handle XTRA loggedin]=="0" || [getuser $handle XTRA loggedin]==""} {
		setuser $handle XTRA loggedin 1
		setuser $handle XTRA lastlogin "[clock seconds]"
		setuser $handle XTRA lasthost "[string trimleft $hostname ~]"
	}
	# Q
	if {[isnetworkservice $nickname] && [ischannelservice $nickname]} {
		channel set $channel -service_netsplit
		channel set $channel service_servicebot "$nickname"
		if {[validuser $handle]} { chattr $handle +S|+S $channel }
		return 0
	}
	# Known
	if {[channel get $channel service_known] && ![matchattr $handle nmS|RnmovfS $channel]} {
		if {[string match -nocase *users.quakenet.org [set hostname *!$hostname]]} {
			set hostname *!*@[lindex [split $hostname @] 1]
		}
		if {[set kickmsg [channel get $channel service_kickmsg_known]] == ""} {
			channel set $channel service_kickmsg_known "[set kmsg [getconf kickmsg known]]"
		}
		channel set $channel service_kid_known "[set id [expr {[channel get $channel service_kid_known] + 1}]]"
		regsub -all :channel: $kmsg "$channel" kmsg
		regsub -all :id: $kmsg "$id" kmsg
		if {[botisop $channel] && [onchan $nickname $channel]} {
			putquick "MODE $channel -o+b $nickname $hostname"
			putquick "KICK $channel $nickname :$kmsg"
			utimer 300 [list pushmode $channel -b $hostname]
		}
		return 0
	}
	# Clonescan
	if {[channel get $channel service_clonescan] && ![matchattr $handle nmS|RnmovfS $channel]} {
		set type [channel get $channel service_clonescan_hosttype]
		set max [channel get $channel service_clonescan_maxclones]
		set hostname [string trimleft $hostname ~]
		set hostname [expr {$type ? "*!*@[lindex [split $hostname @] 1]" : "*!*$hostname"}]
		set list [list]
		foreach user [chanlist $channel] {       
			set host [string trimleft [getchanhost $user $channel] ~]
			set host [expr {$type ? "*!*@[lindex [split $host @] 1]" : "*!*$host"}]		
			if {[string equal -nocase $hostname $host]} {
				lappend list $user;
			}
		}
		if {[llength $list] >= $max} {
			if {[botisop $channel]} {
				channel set $channel service_kid "[set id [expr {[channel get $channel service_kid] + 1}]]"
				regsub -all :clones: [getconf kickmsg clonescan] "[llength $list]" kmsg
				regsub -all :maxclones: $kmsg "[channel get $channel service_clonescan_maxclones]" kmsg
				regsub -all :hostname: $kmsg "$hostname" kmsg
				regsub -all :channel: $kmsg "$channel" kmsg
				regsub -all :id: $kmsg "$id" kmsg
				regsub -all :homechan: $kmsg "$homechan" kmsg
				if {$hostname == "*!*@" || $hostname == "*!*@*"} {
					#putloglev do "onjoin_clonescan: (bad hostmask: $hostname) $nickname $hostname $handle $channel $list"
				}
				putserv "MODE $channel +b $hostname"
				foreach user $list {
					if {[onchan $user $channel] && [botisop $channel]} {
						putserv "KICK $channel $user :$kmsg"
					}
				}
				utimer [expr {[channel get $channel service_clonescan_bantime]*60}] [list puthelp "MODE $channel -b $hostname"]
			} else {
				putserv "PRIVMSG $channel :Clonescan: $nickname is a clone! The nicknames ( [join $list ", "] ) are sharing the same hostmask ( [lindex [split $hostname @] 1] ). (Clones/Maxclones: [llength $list]/[channel get $channel service_clonescan_maxclones])."
			}
			return 0
		}
	}
	# Usermodes
	if {![matchattr $handle d|d $channel]} {
		#set mode [list]; set arg [list]
		if {[matchattr $handle B|B $channel]} {
			if {[string match -nocase *users.quakenet.org [set hostname *!$hostname]]} {
				set hostname *!*@[lindex [split $hostname @] 1]
			}
			if {[channel get $channel service_kickmsg_defaultban] == ""} {
				channel set $channel service_kickmsg_defaultban [set kmsg [getconf kickmsg defaultban]]
			}
			channel set $channel service_kid "[set id [expr {[channel get $channel service_kid] + 1}]]"
			regsub -all :channel: $kmsg $channel kmsg
			regsub -all :id: $kmsg $id kmsg
			if {[botisop $channel] && [onchan $nickname $channel]} {
				putquick "MODE $channel -o+b $nickname $hostname"
				putquick "KICK $channel $nickname :$kmsg"
			}
			return 0
		} else {
			if {[matchattr $handle S|S $channel]} {
				#lappend mode "o"; lappend arg $nickname
				pushmode $channel +o $nickname
			} else {
				if {[matchattr $handle |o $channel] && [matchattr $handle |ap $channel]} {
					#lappend mode "o"; lappend arg $nickname
					pushmode $channel +o $nickname
				}
				if {[matchattr $handle |vf $channel] && [matchattr $handle |gp $channel]} {
					#lappend mode "v"; lappend arg $nickname
					pushmode $channel +v $nickname
				}
			}
			#if {[llength $mode]>=1} {
				#putquick "MODE $channel +[join $mode ""] [join $arg " "]"
			#}
		}
	}
	# Autolimit
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
				channel set $channel service_chanmode_limit $newlimit
			}
		} else {
			pushmode $channel +l [set newlimit [expr {[llength [chanlist $channel]] + [channel get $channel service_limit]}]]
			channel set $channel service_chanmode_limit $newlimit
		}
	}
	# Automodes
	if {![channel get $channel service_netsplit] && ![matchattr $handle d|d $channel] && [botisop $channel] && ([set ao [channel get $channel service_ao]] || [set av [channel get $channel service_av]])} {
		set mode [list]; set arg [list]
		if {$ao && $av} {
			lappend mode "ov"; lappend arg "$nickname $nickname"
		} elseif {$ao} {
			lappend mode "o"; lappend arg $nickname
		} elseif {$av} {
			lappend mode "v"; lappend arg $nickname
		}
		if {[llength $mode]>=1} { 
			pushmode $channel +[join $mode ""] [join $arg " "]
		}
	}
	# flush channel modes
	flushmode $channel
	# Welcome
	if {[channel get $channel service_welcome] && ![isbotnick $nickname]} {
		if {[set skin [channel get $channel service_welcome_skin]] == ""} {
			channel set $channel service_welcome_skin [set skin [getconf welcome skin]]
		}
		regsub -all :nickname: $skin "$nickname" skin
		regsub -all :hostname: $skin "$hostname" skin
		regsub -all :date: $skin "[clock format [clock seconds] -format "%A %d/%m/%Y"]" skin
		set t [clock format [clock seconds] -format "%T"]
		regsub -all :time: $skin "[lindex [split $t :] 0]hr [lindex [split $t :] 1]min [lindex [split $t :] 2]sec" skin
		regsub -all :channel: $skin "$channel" skin
		channel set $channel service_jid "[set id [expr {[channel get $channel service_jid] + 1}]]"
		regsub -all :id: $skin "$id" skin
		if {$skin == ""} { return 0 }
		if {[channel get $channel service_welcome_notice]} {
			putserv "NOTICE $nickname :$skin"
		} else {
			putserv "PRIVMSG $channel :$skin"
		}
	}
	# authban/badchan/vip
	set chks [list]
	if {[channel get $channel service_authban] && [channel get $channel service_authbans] != ""} {
		lappend chks "authban"
	}
	if {[channel get $channel service_badchan] && [channel get $channel service_badchans] != ""} {
		lappend chks "badchan"
	}
	if {[channel get $channel service_vip] && [channel get $channel service_vipc] != ""} {
		lappend chks "vip"
	}
	#putlog "$nickname @ $channel chks => $chks"
	if {[llength $chks] >= 1} {
		#putlog "Delayed whois -> $nickname @ $channel -> $chks (0)"
		service whois delayedwhois $nickname $channel $chks 0
	}
	return 0
}
