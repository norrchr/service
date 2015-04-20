proc loadcommands {} {
	set commands [globr scripts/service/core/commands *.tcl]
	if {[llength $commands] <= 0} {
		putlog "No core commands detected"; return
	} else {
		putlog "Detected [llength $commands] core command(s): [join $commands ", "]"
		foreach command $commands {
			if {$command eq ""} { continue }
			set name [lindex [split [file tail $command] .] 0]
			#putlog "Attempting to load '$name' command (Path: $command):"
			if {[catch {source $command} err]} {
				putlog "Error loading command '$name' (Path: $command):"
				foreach li $err {
					putlog "${name} error: $li"
				}
				putlog "${name} end of error."
			} else {
				putlog "${name} core command successfully loaded."
			}
		}
	}
}

loadcommands