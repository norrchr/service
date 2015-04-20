service::commands::register vip 450 [namespace current]::vip

proc vip {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set command [string tolower [lindex [split $text] 0]]
	set arg [join [lrange $text 1 end]]
	if {$command eq "add"} {
		vip_add $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "del"} {
		vip_del $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "list"} {
		vip_list $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "skin"} {
		vip_skin $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "mode"} { 
		vip_mode $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "on"} {
		vip_on $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "off"} {
		vip_off $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "set"} {
		vip_set $channel $nickname $handle "$lastbind $command" $arg
	} elseif {$command eq "authbl"} {
		vip_authbl $channel $nickname $handle "$lastbind $command" $arg
	} else {
		vip_default $channel $nickname $handle $lastbind $text
	}
}