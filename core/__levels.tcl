proc accesslevel {handle {channel ""}} {
	if {$channel == ""} {
		if {[matchattr $handle A]} {
			return 8
		} elseif {[matchattr $handle D]} {
			return 7
		} elseif {[matchattr $handle S]} {
			return 6
		} elseif {[matchattr $handle n]} {
			return 5
		} elseif {[matchattr $handle m]} {
			return 4
		} elseif {[matchattr $handle o]} {
			return 3
		} elseif {[matchattr $handle vf]} {
			return 2
		} elseif {[matchattr $handle B]} {
			return 1
		} else {
			return 0
		}
	} elseif {![validchan $channel]} {
		return 0
	} else {
		if {[matchattr $handle |n $channel]} {
			return 5
		} elseif {[matchattr $handle |m $channel]} {
			return 4
		} elseif {[matchattr $handle |o $channel]} {
			return 3
		} elseif {[matchattr $handle |vf $channel]} {
			return 2
		} elseif {[matchattr $handle |B $channel]} {
			return 1
		} elseif {[matchattr $handle ADSnm]} {
			# bot staff hack
			return 6
		} else {
			return 0
		}
	}
	return 0
}