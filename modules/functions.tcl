# from http://wiki.tcl.tk/1474
proc globr {{dir .} args} {
	set res {}
	foreach i [lsort [glob -nocomplain -dir $dir *]] {
		if {[file isdirectory $i]} {
			eval [list lappend res] [eval [linsert $args 0 globr $i]]
		} else {
			if {[llength $args]} {
				foreach arg $args {
					if {[string match $arg $i]} {
						lappend res $i
						break
					}
				}
			} else {
				lappend res $i
			}
		}
	}
	return $res
}

proc loadedmodules {} {
	set loaded [list]
	set modules [globr scripts/service/modules/ *.module]
	foreach module $modules {
		if {$module eq ""} { continue }
		set module [lindex [split [file tail $module] .] 0]
		if {[ismodule $module]} {
			lappend loaded $module
		}
	}
	return $loaded
}

proc availablemodules {} {
	set mods [list]
	set modules [globr scripts/service/modules/ *.module]
	foreach module $modules {
		if {$module eq ""} { continue }
		lappend mods [lindex [split [file tail $module] .] 0]
	}
	return $mods
}		

proc loadmodules {} {
	set modules [globr scripts/service/modules/ *.module]
	if {[llength $modules] <= 0} {
		putlog "No service modules detected"; return
	} else {
		putlog "Detected [llength $modules] module(s): [join $modules ", "]"
		foreach module $modules {
			if {$module eq ""} { continue }
			set name [lindex [split [file tail $module] .] 0]
			putlog "Attempting to load '$name' module (Path: $module):"
			if {[catch {source $module} err]} {
				putlog "Error loading module '$name' (Path: $module):"
				foreach li $err {
					putlog "${name} error: $li"
				}
				putlog "${name} end of error."
			} else {
				putlog "${name} module successfully loaded."
			}
		}
	}
	namespace ensemble create
}

proc loadmodule {module} {
	set module [string tolower $module]
	if {[string match "*/*" $module]} {
		if {![file exists $module]} {
			set name [lindex [split [file tail $module] .] 0]
			putlog "Path does not exist: $path"; return -1
		} elseif {[ismodule $name]} {
			# reload module
			unloadmodule $name
			loadmodule $module
		} else {
			if {[catch {source $module} err]} {
				putlog "Error loading module '$name' (Path: $module):"
				foreach li $err {
					putlog "${name} error: $li"
				}
				putlog "${name} end of error."; return 0
			} else {
				putlog "${name} module successfully loaded."; return 1
			}
		}
	} else {
		# is a name
		if {![file exists [set path scripts/service/modules/${module}/${module}.module]]} {
			putlog "${module} can not find module path: $path"; return -1
		} elseif {[ismodule $module]} {
			# reload module
			unloadmodule $module
			loadmodule $module
		} else {
			if {[catch {source $path} err]} {
				putlog "Error loading module '$module' (Path: $path):"
				foreach li $err {
					putlog "${module} error: $li"
				}
				putlog "${module} end of error."; return 0
			} else {
				putlog "${module} module successfully loaded."; return 1
			}
		}
	}
	namespace ensemble create
	return -2
}		

proc unloadmodule {module} {
	set module [string tolower $module]
	if {[namespace exists $module]} {
		catch {${module}::__unload__}
		namespace delete $module
		return 1
	} else {
		return 0
	}
}

proc ismodule {module} {
	set module [string tolower $module]
	return [namespace exists $module]
}