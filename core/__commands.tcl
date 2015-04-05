namespace eval commands {

	# TODO:
	#		cmd2level <command>
	#		handle2level <handle> ?channel?
	#		add error handling code for	command execution
	#		define and code a proper level class system based on number values (>=0<=499 channel, >=500 global)

	variable version "1.0.0"

	array set bind2proc {}
	
	variable dtrigger [service getconf core trigger]
	variable triggers [service getconf core triggers]
	
	proc processargs {arg arr} {
		array set res $arr
		if {[llength [array names res]] <= 0} { return $arg }
		set map [list]
		foreach {ele val} [array get res] {
			if {$ele == "" || $val == ""} { continue }
			lappend map ":${ele}: $val"
		}
		lappend map ":results: \{[array get res]\}"
		return [string map [join $map] $arg]
	}
	
	proc handler {nickname hostname handle channel text} {
		global botnick; variable dtrigger; variable triggers; variable bind2proc
		if {[validuser $handle]} {
			set trigger [getuser $handle XTRA trigger]
			if {$trigger eq "" || [lsearch -exact -- $trigger $triggers]<0} {
				setuser $handle XTRA trigger [set trigger $dtrigger]
			}
		} else {
			set trigger $dtrigger
		}
		set first [lindex [split $text] 0]
		if {[string equal -nocase $botnick $first]} {
			set command [lindex [split $text] 1]
			set lastbind "$first $command"
			set text [join [lreplace [split $text] 0 1]]
		} elseif {[lsearch -exact -- [string index $first 0] $triggers]>=0 && [string equal -nocase [string index $first 0] $trigger]} {
			set command [string range $text 1 end]
			set lastbind $first
			set text [join [lreplace [split $text] 0 0]]
		} else {
			return
		}
		if {![validcommand $command]} {
			putserv "NOTICE $nickname :ERROR: Unknown command '$command'."; return
		} else {
			set cmdl [cmd2level $command]
			if {$cmdl >= 500} {
				# global command
				set usrl [handle2level $handle]
				if {$cmdl > $usrl} {
					putserv "NOTICE $nickname :ERROR: You do not have the required access to use '$command."; return
				}
			} else {
				# channel command
				set usrl [handle2level $handle $channel]
				if {$cmdl > $usrl} {
					putserv "NOTICE $nickname :ERROR: You do not have the required access to use '$command' on $channel."; return
				}
			}
			if {![info exists bind2proc([string tolower $command],$cmdl)]} {
				putserv "NOTICE $nickname :ERROR: Failed to grab '$command' function from command registry."; return
			}
			set bind $bind2proc([string tolower $command],$cmdl)
			set function [lindex [split $bind] 0]
			set arguments [join [lrange $bind 1 end]]
			array set arr {}
			set arr(nickname) $nickname
			set arr(hostname) $hostname
			set arr(handle) $handle
			set arr(channel) $channel
			set arr(text) $text
			set arr(lastbind) $lastbind
			set arr(command) $command
			set arr(botnick) $botnick
			if {[catch {$function [expr {$arguments == "" ? "" : [processargs $arguments [array get arr]]}]} err]} {
				putserv "NOTICE $nickname :ERROR: There was an error whilst processing '$command'."
				# handle error here
			}
		}
	}			
	
	# tcl,debug 1000 service::tcldebug_cmd :nickname: :hostname: :handle: :channel: :text:
	
	proc register {bind level func args} {
		variable bind2proc
		if {($bind eq "" || $bind eq ",") || $flags eq "" || $func eq ""} { return 0 }
		foreach b [string tolower [split $bind ,]] {
			if {$b eq ""} { continue }
			set bind2proc($b,$level) "$func [join $args]"
		}
		return 1
	}
	
	proc deregister {bind} {
		variable bind2proc
		if {$bind eq "" || $bind eq ","} { return 0 }
		set f 0
		foreach b [string tolower [split $bind ,]] {
			if {$b eq ""} { continue }
			if {[llength [set e [array names bind2proc $b,*]]] == 1} {
				unset bind2proc($e); incr f
			}
		}
		return $f
	}
	
	proc registered {args} {
		variable bind2proc
		set l [list]
		if {[llength [array names bind2proc]]<=0} { return $l }
		if {[llength $args]<=0} {
			foreach e, v [array get bind2proc] {
				if {$e eq "" || $v eq ""} { continue }
				set b [lindex [split $e] 0]
				set l [lindex [split $e] 1]
				set f [lindex [split $v] 0]
				set a [join [lrange $v 1 end]]
				lappend l "$b $l $f $a"
			}
			return $l
		} else {
			set args [join $args]
			foreach e, v [array get bind2proc] {
				if {$e eq "" || $v eq ""} { continue }
				set b [lindex [split $e] 0]
				set l [lindex [split $e] 1]
				set f [lindex [split $v] 0]
				set a [join [lrange $v 1 end]]
				if {[string match -nocase $args $b] || [string match -nocase $args $l] || [string match -nocase $args $f]} {
					lappend l "$b $l $f $a"
				}
			}
			return $l
		}
	}
	
	proc level2cmd {max {min {0}}} {
		variable bind2proc
		set l [list]
		if {[llength [array names bind2proc]]<=0} { return $l }
		if {![string is digit $max]} { return $l }
		if {$min eq ""} {
			set min $max
		} elseif {$min > $max} {
			return $l
		} elseif {$mix < 0} {
			set min 0
		}
		foreach e [array names bind2proc] {
			if {$e eq ""} { continue }
			set b [lindex [split $e] 0]
			set l [lindex [split $e] 1]
			if {$l >= $min && $l <= $max} {
				lappend l $e
			}
		}
		return [join $l " "]
	}
	
}