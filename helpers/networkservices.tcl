array set networkservices {
	{Q} {chanserv}
	{S} {spamscan}
	{P} {proxyscan}
	{U} {gamebot}
	{H} {helpbot}
	{T} {trojanscan}
	{WOWBOT} {gameserv}
	{SNAILBOT} {gameserv}
	{CATBOT} {gameserv}
	{FISHBOT} {gameserv}
}

proc isnetworkservice {arg} {
	variable networkservices
	return [info exists networkservices([string toupper $arg])]
}

proc ischannelservice {arg} {
	variable networkservices
	if {[info exists networkservices([set arg [string toupper $arg]])]} {
		if {$networkservices($arg) == "chanserv"} {
			return 1
		}
	}
	return 0
}

proc getnetworkservice {channel {type "chanserv"}} {
	variable networkservices
	if {![validchan $channel]} { return }
	foreach {service typ} [array get networkservices] {
		if {$service == "" || $typ == ""} { continue }
		if {[string equal -nocase $type $typ]} {
			if {[onchan $service $channel]} {
				return $service
			}
		}
	}
	return
}

proc getnetworkservices {channel} {
	variable networkservices
	if {![validchan $channel]} { return }
	set services [list]
	foreach service [array names networkservices] {
		if {$service == ""} { continue }
		if {[onchan $service $channel]} {
			lappend services $service
		}
	}
	return $services
}