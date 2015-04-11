proc badbanmask {mask} {
	if {$mask eq ""} {
		return 1
	} elseif {[regexp -nocase -- {^([a-z0-9\?\*\^\_\`\{\}\[\]\|\\]{1,})(!{1,1})([a-z0-9\?\*\^\_\`\{\}\[\]\|\\]{1,})(@{1,1})([a-z0-9\?\*\.\-]{1,})$} $mask]} {
		return [widebanmask $mask]
	} else {
		return 1
	}
	return 0
}

proc widebanmask {mask} {
	if {$mask eq ""} { return 0 }
	return [regexp -nocase -- {^(\*|\?{1,})(!{1,1})(\*|\?{1,})(@{1,1})(\*|\?{1,})$} $mask]
}

proc validbanmask {mask} {
	if {[llength $mask]>1} { return 0 }
	set validnickident [list 63 94 95 96 123 125 91 93 124 92]; # *42
	set validhost [list 63 46 45]; # *42
	set ex 0; set at 0; set ti 0; set la 0
	set n 1; set i 0; set h 0; set r 1
	for {set c 0} {$c<[string length $mask]} {incr c; set la 0} {
		set ch [string index $mask $c]
		scan $ch %c as
		if {$c>=1} { scan [string index $mask [expr {$c-1}]] %c la }
		#putlog "#$c Char: $ch - Ascii: $as - Last: $la"
		if {$as >= 48 && $as <= 57} { continue }; # valid digit
		if {$as >= 65 && $as <= 90} { continue }; # valid uppercase letter
		if {$as >= 97 && $as <= 122} { continue }; # valid lowercase letter
		if {($n || $i) && [lsearch -exact $validnickident $as]!=-1} { continue }; # valid char for nickname and ident
		if {$h && [lsearch -exact $validhost $as]!=-1} { continue }; # valid char for hostmask
		if {$as == 33} {
			# we have ! -- we can only have one ! in a valid banmask
			if {$ex} { set r 0; break }; # ! already parsed -- invalid banmask
			set ex 1; set n 0; set i 1; set h 0; # valid -- pass on over to ident
		}
		if {$as == 64} {
		# we have @ -- we can only have one @ in a valid banmask
			if {!$ex} { set r 0; break }; # we have @ before ! -- invalid
			if {$at} { set r 0; break }; # @ already parsed -- invalid banmask
			set at 1; set n 0; set i 0; set h 1; # valid -- pass on over to hostmask
		}
		if {$as == 42 && $as == $la} {
			# we have two *'s side by side -- invalid
			set r 0; break
		}
		if {$as == 126} {
			# we have ~ -- only valid once for ident
			if {!$i} { set r 0; break }; # invalid
			if {$i && $ti} {  set r 0; break}; # invalid
			set ti 1; # valid
		}
	}
	if {$ex && $at && $r} { return [widebanmask $mask] }
	return 0
}