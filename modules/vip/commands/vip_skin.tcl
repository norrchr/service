proc vip_skin {channel nickname handle lastbind arg} {
	if {[channel get $channel service_vipskin] == ""} {
		channel set $channel service_vipskin "$[namespace parent]::vipskin"
	}
	set skin [lrange $text 1 end]
	if {$skin == ""} {
		putserv "NOTICE $nickname :$channel vip-skin: [join [channel get $channel service_vipskin]] - Keyword(s) available: :nickname: :hostname: :channel: :vipchannel: :status: :id:."
	} else {
		if {[string length $skin] < "2"} {
			putserv "NOTICE $nickname :The minimum vip-skin length allowed is 2."
		} elseif {[string length $skin] > "300"} {
			putserv "NOTICE $nickname :The maxium vip-skin length allowed is 300. The current skin length is [string length $skin]."
		} else {
			channel set $channel service_vipskin "$skin"
			putserv "NOTICE $nickname :$channel vip-skin set to: [join [channel get $channel service_vipskin]]."
		}
	}
}