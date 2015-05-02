proc onraw_kick {from raw arg {lookup 0}} {
	global botnick server; variable kickmsg; variable homechan
	set nickname [lindex [split $from !] 0]
	set hostname [string trimleft [lindex [split $from !] 1] ~]
	set channel [lindex [split $arg] 0]
	set target [lindex [split $arg] 1]
	if {[isbotnick $nickname] || $nickname == "" || [string equal -nocase $nickname $target] || ![channel get $channel service_prot] || [channel get $channel service_startup] || ([string equal -nocase [lindex [split $server :] 0] $hostname] && $nickname == "")} { return 0 }
	set hostname [string trimleft [lindex [split $from !] 1] ~]
	#set authname [service authname nick2auth $nickname]
	set handle [nick2hand $nickname]		
	#if {$handle == "*" && $authname == "" && $lookup == 0} {
	#	putlog "onraw_kick: Performing auth lookup for $nickname @ $channel"
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
	set reason [lrange [string trimleft $arg :] 2 end]
	info_mode $nickname $hostname $handle $channel kick $target $reason
	set flags [expr {[channel get $channel service_prot_hard] ? "nmNbfS|nmS" : "nmNbfS|nmoS"}]
	if {[matchattr $handle $flags $channel]} {
		if {$reop && [botisop $channel] && ![isop $nickname $channel]} {
			putserv "MODE $channel +o $nickname"; return 0
		}
		return 0
	}
	set service [channel get $channel service_servicebot]
	if {[string match -nocase *users.quakenet.org [set hostname *!*$hostname]]} {
		set hostname *!*@[lindex [split $hostname @] 1]
	}
	if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { 
		#putloglev do "kickprot: (bad banmask: $hostname) $nickname [getchanhost $nickname $channel] $handle $channel $target $reason"
		return 0
	}
	if {[isbotnick $target]} {
		#putquick "PRIVMSG $service :CHANFLAGS $channel +b-p"
		putquick "PRIVMSG $service :RECOVER $channel" -next
		putquick "PRIVMSG $service :UNBANME $channel" -next
		putquick "JOIN $channel" -next
		putquick "PRIVMSG $service :OP $channel" -next
		set violate "\002\037kick/ban\037 me\002"
		if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
			channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
		}
		channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
		regsub -all :violate: $kmsg "$violate" kmsg
		regsub -all :channel: $kmsg "$channel" kmsg
		regsub -all :id: $kmsg "$id" kmsg
		regsub -all :homechan: $kmsg "$homechan" kmsg
		if {[botisop $channel] && [onchan $nickname $channel]} {
			putquick "MODE $channel -o+b $nickname $hostname"
			putquick "KICK $channel $nickname :$kmsg"
		}
		newchanban $channel $hostname $botnick "$kmsg" 120
		#putquick "PRIVMSG $service :CHANFLAGS $channel -b+p"
	} else {
		set violate "\002\037kick\037 anyone\002"
		if {[set kmsg [channel get $channel service_kickmsg_protkick]] == ""} {
			channel set $channel service_kickmsg_protkick [set kmsg $kickmsg(protkick)]
		}
		channel set $channel service_kid [set id [expr {[channel get $channel service_kid] + 1}]]
		regsub -all :violate: $kmsg "$violate" kmsg
		regsub -all :channel: $kmsg "$channel" kmsg
		regsub -all :id: $kmsg "$id" kmsg
		regsub -all :homechan: $kmsg "$homechan" kmsg
		if {$hostname == "*!*@" || $hostname == "*!*@*" || $hostname == "*!**@*" || $hostname == "*!**@"} { 
			#putloglev do "kickprot: (bad banmask: $hostname) $nickname [getchanhost $nickname $channel] $handle $channel $target $reason"
			return
		}
		if {[botisop $channel] && [onchan $nickname $channel]} {
			putquick "MODE $channel -o+b $nickname $hostname"
			putquick "KICK $channel $nickname :$kmsg"
		}
		newchanban $channel $hostname $botnick "$kmsg" 120
	}
	return 0
}