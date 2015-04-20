service::commands::register auth 850 auth_cmd

proc auth_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	### Recode ###
	putserv "NOTICE $nickname :Defunct -- Being reimplementated"; return
	### Recode ###
	if {[string match -nocase *users.quakenet.org $::botname]} {
		putserv "NOTICE $nickname :I'm already authed!"
	} elseif {![info exists ::qscript(auth)] || ![info exists ::qscript(pass)]} {
		putserv "NOTICE $nickname :Error: error trying to auth to Q..."
	} elseif {![string equal -nocase [join [lrange [split [lindex [split $::server :] 0] .] end-1 end] .] quakenet.org]} {
		putserv "NOTICE $nickname :Error: network/server does not end in 'quakenet.org'..."
	} else {
		putserv "NOTICE $nickname :Authing with Q... this may take a few seconds depending on queue times."
		puthelp "MODE $::botnick +ixR-ws"
		puthelp "AUTH :$::qscript(auth) $::qscript(pass)"
		puthelp "NOTICE $nickname :Sent auth to Q..."
	}
}