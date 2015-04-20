service::commands::register channels,chanlist 850 [namespace current]::channels_cmd

proc channels_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set on 0
	set active 0
	set inactive 0
	set users 0
	set op 0
	set voice 0
	set reg 0
	set result ""
	foreach c [channels] {
		set status ""
		set count ""
		set services ""
		if {[botonchan $c]} {
			incr on 1
		}
		if {[channel get $c inactive]} {
			incr inactive 1
		} else {
			incr active 1
		}
		if {[botisop $c]} {
			incr op 1
			set status "@"
		} elseif {[botisvoice $c]} {
			incr voice 1
			set status "+"
		} else {
			incr reg 1
			set status ""
		}
		incr users [set count [llength [chanlist $c]]]
		if {[set services [getnetworkservices $c]] == ""} {
			set services "None"
		}
		if {[botonchan $c]} {
			lappend result "${status}${c} \(Channel Count: $count user(s) - Userlist Count: [llength [userlist |almnov $c]] user(s) - Channel Service(s): [join $services ", "]\)"
		} else {
			lappend result "${c} \(currently not on $c\)"
		}
	}
	puthelp "NOTICE $nickname :Channels Count: \([llength [channels]]/20\) channel(s). Im currently on $on of these channels. Statistics (Active on $active - Inactive on $inactive - Operator on $op - Voice on $voice, Regular on $reg - Total user count of all channels: $users user(s))."
	if {[string equal -nocase "-list" [lindex $text 0]]} {
		puthelp "NOTICE $nickname :[join $result " - "]"
	} else {
		foreach line $result {
			if {$line == ""} { return }
			puthelp "NOTICE $nickname :$line"
		}
	}
	puthelp "NOTICE $nickname :Im using [format %.0f [expr (([llength [channels]].0 * 100.0) / 20.0)]]% of my total channel capacity."
}