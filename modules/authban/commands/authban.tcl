service::commands::register authban 450 [namespace current]::authban

proc authban {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set command [string tolower [lindex [split $text] 0]]
	set arg [join [lrange $text 1 end]]
	if {$command eq "add"} {
		authban_add $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "del"} {
		authban_del $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "list"} {
		authban_list $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "on"} {
		authban_on $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "off"} {
		authban_off $channel $nickname $handle "$lastbind $command" $arg
	} else {
		authban_default $channel $nickname $handle $lastbind $text
	}
}