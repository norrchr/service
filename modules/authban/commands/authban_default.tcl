proc authban_default {channel nickname handle lastbind text} {
	set status [expr {[channel get $channel service_authban] ? "enabled" : "disabled"}]
	set authbans [llength [channel get $channel service_authbans]]
	if {[set id [channel get $channel service_aid]] == ""} {
		channel set $channel service_aid "[set id 0]"
	}
	putserv "NOTICE $nickname :Authbans is: \002$status\002 - Authname(s): \002$authbans\002 - Authbans ID: \002#$id\002."
	putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|add|del|list ?arguments?."
}