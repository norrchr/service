proc badchan_default {channel nickname handle lastbind text} {
	set status [expr {[channel get $channel service_badchan] ? "enabled" : "disabled"}]
	set badchans [llength [channel get $channel service_badchans]]
	if {[set id [channel get $channel service_bid]] == ""} {
		channel set $channel service_bid "[set id 0]"
	}
	putserv "NOTICE $nickname :Bad Channel is: \002$status\002 - Bad Channel(s): \002$badchans\002 - Bad Channel ID: \002#$id\002."
	putserv "NOTICE $nickname :SYNTAX: $lastbind on|off|add|del|list ?arguments?."
}