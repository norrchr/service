service::commands::register badwords,badword 450 [namespace current]::badwords

proc badwords {nickname hostname handle channel lastbind text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set command [string tolower [lindex [split $text] 0]]
	set arg [join [lrange $text 1 end]]
	if {$command eq "add"} {
		badwords_add $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "del"} {
		badwords_del $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "list"} {
		badwords_list $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "on"} {
		badwords_on $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "off"} {
		badwords_off $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "status"} {
		badwords_status $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "bantime"} {
		badwords_bantime $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "check"} {
		badwords_check $channel $nickname $handle "$lastbind $command" $arg
	} else {
		badwords_default $channel $nickname $handle $lastbind $text
	}
}

proc badwords_on {channel nickname handle lastbind text} {
	set status [channel get $channel service_badword]
	if {$status} {
		putserv "NOTICE $nickname :$channel badwords is already enabled."
	} else {
		channel set $channel +service_badword
		putserv "NOTICE $nickname :$channel badwords is now enabled."
	}
}

proc badwords_off {channel nickname handle lastbind text} {
	set status [channel get $channel service_badword]
	if {!$status} {
		putserv "NOTICE $nickname :$channel badwords is already disabled."
	} else {
		channel set $channel -service_badword
		putserv "NOTICE $nickname :$channel badwords is now disabled."
	}
}

proc badwords_add {channel nickname handle lastbind text} {
	set words [channel get $channel service_badwords]
	set badword $text
	if {$badword == ""} { 
		putserv "NOTICE $nickname :SYNTAX: $lastbind ?badword?."
	} elseif {[llength $badword] > 1} {
		putserv "NOTICE $nickname :A badword may only consist of one word."
	} elseif {[regexp -nocase {\*} $badword]} {
		putserv "NOTICE $nickname :A badword is not to incldue '\*'."
	} elseif {[lsearch -exact [string tolower $words] [string tolower $badword]] != -1} {
		putserv "NOTICE $nickname :Badword '$badword' is already added to my badwords list."
	} else {
		channel set $channel service_badwords "[string tolower $words] [string tolower $badword]"
		putserv "NOTICE $nickname :Badword '$badword' added to my badwords list."
	}
}

proc badwords_del {channel nickname handle lastbind text} {
	set words [channel get $channel service_badwords]
	set badword $text
	if {$badword == ""} { 
		putserv "NOTICE $nickname :SYNTAX: $lastbind ?badword?."
	} elseif {[llength $badword] > 1} {
		putserv "NOTICE $nickname :A badword may only consist of one word."
	} elseif {[regexp -nocase {\*} $badword]} {
		putserv "NOTICE $nickname :A badword is not to incldue '\*'."
	} elseif {[set index [lsearch -exact [string tolower $words] [string tolower $badword]]] == -1} {
		putserv "NOTICE $nickname :Badword '$badword' is not added to my badwords list."
	} else {
		channel set $channel service_badwords "[lreplace $words $index $index]"
		putserv "NOTICE $nickname :Badword '$badword' removed from my badwords list."
	}
}

proc badwords_list {channel nickname handle lastbind text} {
	set words [channel get $channel service_badwords]
	set list [list]
	putserv "NOTICE $nickname :$channel badwords list:"
	foreach badword $words {
		if {$badword == ""} { continue }
		lappend list $badword
		if {[llength $badword] > 20} {
			putserv "NOTICE $nickname :[join $list ", "]"
			set list [list]
		}
	}
	if {[llength $list] > 0} {
		putserv "NOTICE $nickname :[join $list ", "]."
	}
	putserv "NOTICE $nickname :End of badwords list. (Total: [llength $words])"
}

proc badwords_status {channel nickname handle lastbind text} {
	set time [channel get $channel service_badword_bantime]z
	if {$time == ""} { 
		channel set $channel service_badword_bantime "[set time 1]"
	}
	putserv "NOTICE $nickname :$channel badwords is: \002[expr {$status ? "enabled" : "disabled"}]. $channel badwords-bantime is: \002$time minute(s)\002."
}

proc badwords_bantime {channel nickname handle lastbind text} {
	set bantime [lindex [split $text] 1]
	if {$bantime == ""} {
		putserv "NOTICE $nickname :Current: $time minute(s)."
		putserv "NOTICE $nickname :SYNTAX: $lastbind ?integer?."
	} elseif {![string is integer $bantime]} {
		putserv "NOTICE $nickname :Bantime must consist of digits only."
	} elseif {$bantime < 1 || $bantime > 30} {
		putserv "NOTICE $nickname :Bantime must be between 1 and 30 minutes."
	} elseif {$bantime == $time} {
		putserv "NOTICE $nickname :The new bantime is the same as the current."
	} else {
		channel set $channel service_badword_bantime $bantime
		putserv "NOTICE $nickname :Bantime set to '$bantime' minute(s)."
	}
}

proc badwords_check {channel nickname handle lastbind text} {
	set words [channel get $channel service_badwords]
	set badword [lindex [split $text] 1]
	if {[lsearch -exact [string tolower $words] [string tolower $badword]] != -1} {
		putserv "NOTICE $nickname :'$badword' is a badword."
	} else {
		putserv "NOTICE $nickname :'$badword' is not a badword."
	}
}

proc badwords_default {channel nickname handle lastbind text} {
	putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|add|del|list|check|bantime|status ?badword?."
}