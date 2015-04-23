namespace eval commands {

	bind pubm - "*" [namespace current]::handler

	variable version "1.1.5"
	
	namespace export register deregister registered level2cmds cmd2level handle2level
	namespace ensemble create

	array set bind2proc {}
	
	variable dtrigger [service::getconf core trigger]
	variable triggers [service::getconf core triggers]
	
	proc processargs {arg arr} {
		array set res $arr
		if {[llength [array names res]] <= 0} { return $arg }
		set li [list]
		foreach v [split $arg " "] {
			if {$v eq ""} { lappend li ""; continue }
			if {[string index $v 0] eq ":" && [string index $v end] eq ":"} {
				set v [string tolower [string range $v 1 end-1]]
				if {[info exists res($v)]} {
					lappend li $res($v)
				} else {
					lappend li ""
				}
			} else {
				lappend $v
			}
		}
		return $li
	}
	
	proc handler {nickname hostname handle channel text} {
		global botnick lastbind lasttrigger lastcommand; variable dtrigger; variable triggers; variable bind2proc
		if {[validuser $handle]} {
			set trigger [getuser $handle XTRA mytrigger]
			if {$trigger eq ""} {
				setuser $handle XTRA mytrigger [set trigger $dtrigger]
			}
		} else {
			set trigger $dtrigger
		}
		set first [lindex [split $text] 0]
		if {[string equal -nocase $botnick $first]} {
			set lasttrigger "$first "
			set lastcommand [lindex [split $text] 1]
			set lastbind "$first $lastcommand"
			set text [join [lreplace [split $text] 0 1]]
			# [lsearch -exact [string index $first 0] $triggers]>=0
		} elseif {[string equal -nocase [string index $first 0] $trigger]} {
			set lasttrigger [string index $first 0]
			set lastcommand [string range $first 1 end]
			set lastbind $first
			set text [join [lreplace [split $text] 0 0]]
		} else {
			if {[service::ismodule badwords]} {
				if {[catch {set r [service badwords processline $nickname $hostname $handle $channel $text]} err]} {
					putlog "ERROR: Could not processline for badwords:"
					foreach li [split $err \n] {
						putlog "$li"
					}
					putlog "End of error."
				} elseif {$r} {
					# result == 1 (blocking)
					return
				}
			}
			# call other modules here
			return
		}
		if {![validcommand $lastcommand]} {
			putserv "NOTICE $nickname :ERROR: Unknown command '$lastcommand'."; return
		} else {
			set cmdl [cmd2level $lastcommand]
			if {$cmdl >= 600} {
				# global command
				set usrl [handle2level $handle]
				if {$cmdl > $usrl} {
					putserv "NOTICE $nickname :ERROR: You do not have the required access to use '$lastcommand."; return
				}
			} elseif {$cmdl<=500 && $cmdl>=0} {
				# channel command
				set usrl [handle2level $handle $channel]
				if {$cmdl > $usrl} {
					putserv "NOTICE $nickname :ERROR: You do not have the required access to use '$lastcommand' on $channel."; return
				}
			} elseif {$cmdl ne -1} {
				putserv "NOTICE $nickname :ERROR: An error occurred whilst checking your access level."; return
			}
			if {![info exists bind2proc([string tolower $lastcommand],$cmdl)]} {
				putserv "NOTICE $nickname :ERROR: Failed to grab '$lastcommand' function from command registry."; return
			}
			set bind $bind2proc([string tolower $lastcommand],$cmdl)
			set function [lindex [split $bind] 0]
			#set arguments [join [lrange $bind 1 end]]
			#array set arr {}
			#set arr(nickname) $nickname
			#set arr(hostname) $hostname
			#set arr(handle) $handle
			#set arr(channel) $channel
			#set arr(text) \{$text\}
			#set arr(lastbind) \{$lastbind\}
			#set arr(command) $lastcommand
			#set arr(botnick) $botnick
			#if {[catch {$function [expr {$arguments ne "" ? "" : [processargs $arguments [array get arr]]}]} err]}
			#if {[catch {$function [set values [processargs $arguments [array get arr]]]} err]}
			if {[catch {$function $nickname $hostname $handle $channel $text} err]} {
				putserv "NOTICE $nickname :ERROR: There was an error whilst processing '$lastcommand'. (This error has been reported to bot admins)"
				set rc [service getconf core adminchan]
				putserv "PRIVMSG $rc :An error occurred whilst processing '$lastcommand' for $nickname ($handle):"
				putserv "PRIVMSG $rc :Function: $function - Arguments: \"$nickname\" \"$hostname\" \"$handle\" \"$channel\" \{$text\}"
				#putserv "PRIVMSG $rc :Function: $function - Arguments: [expr {$arguments eq "" ? "N/A" : $arguments}]"
				#if {$values ne ""} {
				#	putserv "PRIVMSG $rc :Values ([llength $values]): $values"
				#}
				foreach li [split $err \n] {
					if {$li eq ""} { continue }
					putserv "PRIVMSG $rc :$li"
				}
				putserv "PRIVMSG $rc :End of error report."
			}
		}
	}			
	
	# tcl,debug 1000 service::tcldebug_cmd :nickname: :hostname: :handle: :channel: :text:
	
	proc register {bind level func args} {
		variable bind2proc
		if {($bind eq "" || $bind eq ",") || $level eq "" || $func eq ""} { return 0 }
		set bind [string tolower $bind]
		foreach b [split $bind ,] {
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
			if {[llength [set e [array names bind2proc $b,*]]] eq 1} {
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
			foreach {e v} [array get bind2proc] {
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
			foreach {e v} [array get bind2proc] {
				if {$e eq "" || $v eq ""} { continue }
				set b [lindex [split $e] 0]
				set l [lindex [split $e] 1]
				set f [lindex [split $v] 0]
				set a [join [lrange $v 1 end]]
				if {[string match -nocase [join $args] $b] || [string match -nocase [join $args] $l] || [string match -nocase [join $args] $f]} {
					lappend l "$b $l $f $a"
				}
			}
			return $l
		}
	}
	
	proc level2cmds {max {min {0}}} {
		variable bind2proc
		set li [list]
		if {[llength [array names bind2proc]]<=0} { return $li }
		if {![string is digit $max]} { return $li }
		if {$min eq ""} {
			set min $max
		} elseif {$min > $max} {
			return $l
		} elseif {$min < 0} {
			set min 0
		}
		foreach e [array names bind2proc] {
			if {$e eq ""} { continue }
			set b [lindex [split $e ,] 0]
			set l [lindex [split $e ,] 1]
			if {$l >= $min && $l <= $max} {
				lappend li $b
			}
		}
		return [join $li " "]
	}
	
	proc cmd2level {command} {
		variable bind2proc
		if {$command eq ""} { return -1 }
		if {[llength [array names bind2proc]]<=0} { return -1 }
		foreach e [array names bind2proc] {
			if {$e eq ""} { continue }
			set b [lindex [split $e ,] 0]
			set l [lindex [split $e ,] 1]
			if {[string equal -nocase $command $b]} {
				return $l
			}
		}
		return -1
	}
	
	proc validcommand {command} {
		variable bind2proc
		if {$command eq ""} { return 0 }
		if {[llength [array names bind2proc]]<=0} { return 0 }
		foreach e [array names bind2proc] {
			set b [lindex [split $e ,] 0]
			set l [lindex [split $e ,] 1]
			if {[string equal -nocase $command $b]} {
				return 1
			}
		}
		return 0
	}
	
	proc handle2level {handle {channel {}}} {
		if {$handle eq "" || ![validuser $handle]} { return -1 }
		if {$channel eq ""} {
			if {[matchattr $handle A] || [matchattr $handle D]} {
				# global admin/dev
				return 1000
			} elseif {[matchattr $handle n]} {
				# global owner
				return 950
			} elseif {[matchattr $handle S]} {
				# network service
				return 900
			} elseif {[matchattr $handle m]} {
				# global master
				return 850
			} elseif {[matchattr $handle o]} {
				# global operator
				return 800
			} elseif {[matchattr $handle v] || [matchattr $handle f]} {
				# global voice/friend
				return 750
			} elseif {[matchattr $handle B]} {
				# global ban
				return 700
			} else {
				# global nothing
				return 600
			}
		} elseif {![validchan $channel]} {
			return 0
		} else {
			if {[matchattr $handle ADn|n $channel]} {
				# global admin/dev/owner or channel owner
				return 500
			} elseif {[matchattr $handle S|S $channel]} {
				# network service
				return 499
			} elseif {[matchattr $handle m|m $channel]} {
				# global master or channel master
				return 450
			} elseif {[matchattr $handle o|o $channel]} {
				# global operator or channel operator
				return 400
			} elseif {[matchattr $handle v|v $channel] || [matchattr $handle f|f $channel]} {
				# global voice/friend or channel voice/friend
				return 350
			} elseif {[matchattr $handle B|B $channel]} {
				# global ban or channel ban
				return 300
			} else {
				# channel nothing
				return 0
			}
		}
	}
	
	putlog "[namespace current] version $version loaded."
	
}

namespace export commands