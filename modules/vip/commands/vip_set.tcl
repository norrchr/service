proc vip_set {channel nickname handle lastbind text} {
	set subcommand [string tolower [lindex [split $text] 0]]
	set arg [join [lrange $text 1 end]]
	if {$subcommand eq "skin"} {
		vip_set_skin $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "notice"} {
		vip_set_notice $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "authed"} {
		vip_set_authed $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "chanmode"} {
		vip_set_chanmode $channel $nickname $handle "$lastbind $subcommand" $arg
	} elseif {$subcommand eq "dynamicmode"} {
		vip_set_dynamicmode $channel $nickname $handle "$lastbind $subcommand" $arg
	} else {
		vip_set_default $channel $nickname $handle $lastbind $text
	}
}