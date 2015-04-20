if {[catch {package require inifile 0.2.3} err]} {
	putlog "${script}: Error loading inifile package -- Exiting."
	#die "${script}: $script requires inifile tcl package to load -- Exiting."
} else {
	putlog "${script}: Successfully loaded inifile package."
	if {[catch {[namespace current]::loadconfig} err]} {
		putlog "${script}: Error loading config file(s):"
		foreach li [split $err \n] {
			putlog "${script}: $li"
		}
		#putlog "-- Exiting."
		#die "${script}: Error loading config file -- Exiting."
	} else {
		putlog "${script}: Successfully loaded config file(s)."
	}
}

variable configdinifile "[pwd]/scripts/service/default.ini"
variable configuinifile "[pwd]/scripts/service/service.ini"

if {![array exists __config]} {
	array set __config {}
}

proc getconf {section arg} {
	variable __config
	set section [string tolower $section]
	set arg [string tolower $arg]
	if {![info exists __config(${section},${arg})]} { return -1 }
	return $__config(${section},${arg})
}

proc loadconfig {} {
	variable __config; variable configdinifile; variable configuinifile
	#if {[string match "*/*" [info script]]} {
	#	set file [file join "/[join [lrange [split [info script] /] 0 end-1] "/"]" service.ini]
	#} else {
	#	set file [file join "[join [lrange [split [info script] \\] 0 end-1] "\\"]" service.ini]
	#}
	putlog "Loading default.ini"
	set ini [::ini::open $configdinifile r]
	foreach section [::ini::sections $ini] {
		if {$section == ""} { continue }
		foreach {key value} [::ini::get $ini $section] {
			if {$key == ""} { continue }
			set __config([string tolower $section],[string tolower $key]) "$value"
		}
	}
	if {[file exists $configuinifile]} {
		putlog "Loading service.ini"
		set ini [::ini::open $configuinifile r]
		foreach section [::ini::sections $ini] {
			if {$section == ""} { continue }
			foreach {key value} [::ini::get $ini $section] {
				if {$key == ""} { continue }
				set __config([string tolower $section],[string tolower $key]) "$value"
			}
		}
	}
}

set __config(core,script) "$script"
set __config(core,copyright) "$copyright"

namespace export getconf