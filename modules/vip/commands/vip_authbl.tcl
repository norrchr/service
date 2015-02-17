proc vip_authbl {channel nickname handle lastbind text} {
	set subcommand [string tolower [lindex [split $text] 0]]
	set arg [join [lrange $text 1 end]]
	if {$subcommand eq "add"} {
		vip_authbl_add $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "del"} {
		vip_authbl_del $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "list"} {
		vip_authbl_list $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "on"} {
		vip_authbl_on $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "off"} {
		vip_authbl_off $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "status"} {
		vip_authbl_status $channel $nickname $handle "$lastbind $subcommand" $arg
	} else {
		vip_authbl_default $channel $nickname $handle $lastbind $text
	}
}