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