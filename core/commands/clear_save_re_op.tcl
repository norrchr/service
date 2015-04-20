service::commands::register clearop 450 [namespace current]::clearop_cmd
service::commands::register saveop 450 [namespace current]::saveop_cmd
service::commands::register reop 450 [namespace current]::reop_cmd

proc clearop_cmd {nickname hostname handle channel text} {
	global lasttrigger
	::service::commands::handler $nickname $hostname $handle $channel "${lasttrigger}saveops --clear"
}

proc saveop_cmd {nickname hostname handle channel text} {
	global lasttrigger
	::service::commands::handler $nickname $hostname $handle $channel "${lasttrigger}saveops --save"
}

proc reop_cmd {nickname hostname handle channel text} {
	global lasttrigger
	::service::commands::handler $nickname $hostname $handle $channel "${lasttrigger}saveops --op --save"
}