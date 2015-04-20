service::commands::register banlist 400 [namespace current]::banlist_cmd

proc banlist_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	if {$text == ""} { putserv "NOTICE $nickname :Syntax: $lastbind -global|-all|-perm|-temp|-chan."; return }
	array set options {
		{global} {0}
		{all} {0}
		{perm} {0}
		{temp} {0}
		{chan} {0}
	}
	foreach option [split $text " "] {
		if {$option == ""} { continue }
		if {[string equal -nocase -global $option]} {
			set options(global) 1
		} elseif {[string equal -nocase -all $option]} {
			set options(all) 1
		} elseif {[string equal -nocase -perm $option]} {
			set options(perm) 1
		} elseif {[string equal -nocase -temp $option]} {
			set options(temp) 1
		} elseif {[string equal -nocase -chan $option]} {
			set options(chan) 1
		} else {
			putserv "NOTICE $nickname :ERROR: Invalid option '$option' specified. (Valid options are: -global|-all|-perm|-temp|-chan)"; return
		}
	}
	if {$options(global)} {
		if {![matchattr $handle nm]} { return }
		if {$options(chan)} {
			putserv "NOTICE $nickname :ERROR: Invalid option '-chan' specified with '-global' option."; return
		}
		if {($options(perm) == "0" && $options(temp) == "0") && !$options(all)} {
			putserv "NOTICE $nickname :ERROR: Please specify '-perm', '-temp' or '-all' along with '-global' option."; return
		}	
		if {[llength [banlist]]<=0} {
			putserv "NOTICE $nickname :There are no global bans."; return
		}
		putserv "NOTICE $nickname :#ID - Banmask - Creator - Expire Time:"
		set id 0; set perm 0; set nonperm 0
		foreach ban [banlist] {
			if {$ban == ""} { continue }
			incr id
			# 0 = mask / 5 = creator - 2 = expirets
			set mask [lindex $ban 0]; set creator [lindex $ban 5]; set expirets [lindex $ban 2]
			if {[ispermban $mask] && ($options(perm) || $options(all))} {
				incr perm
				putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
			} elseif {![ispermban $mask] && ($options(temp) || $options(all))} {
				incr nonperm
				putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
			}
		}
		putserv "NOTICE $nickname :End of global banlist (Total: $id Permanent: $perm Non-permanent: $nonperm)."
	} else {
		if {($options(perm) == "0" && $options(temp) == "0" && $options(chan) == "0") && !$options(all)} {
			putserv "NOTICE $nickname :ERROR: Please specify '-perm', '-temp', '-chan' or '-all'."; return
		}
		if {$options(chan) || $options(all)} {
			# {*!*@test.com r0t3n!r0t3n@away.users.quakenet.org 14} {*!*@test1.com Q!TheQBot@CServe.quakenet.org 5}
			set cb 0
			putserv "NOTICE $nickname :#ID - Banmask - Creator - Created:"
			foreach ban [chanbans $channel] {
				if {$ban == ""} { continue }
				set mask [lindex $ban 0]; set creator [lindex $ban 1]; set created [lindex $ban 2]
				if {![isban $ban $channel] && ($options(chan) || $options(all))} {
					incr cb
					putserv "NOTICE $nickname :#$cb - $mask - $creator - [clock format [expr {[clock seconds]-$created}] -format "%a %d %b %Y at %H:%M:%S %Z"] ([duration $created] ago)."
				}
			}
			putserv "NOTICE $nickname :End of $channel external-banlist (Total: $cb)."
		}
		if {$options(perm) || $options(temp) || $options(all)} {
			if {[llength [banlist $channel]]<=0} {
				putserv "NOTICE $nickname :There are no $channel bans."; return
			}
			putserv "NOTICE $nickname :#ID - Banmask - Creator - Expire Time:"
			set id 0; set perm 0; set nonperm 0
			foreach ban [banlist $channel] {
				if {$ban == ""} { continue }
				incr id
				# 0 = mask / 5 = creator - 2 = expirets
				set mask [lindex $ban 0]; set creator [lindex $ban 5]; set expirets [lindex $ban 2]
				if {[ispermban $mask] && ($options(perm) || $options(all))} {
					incr perm
					putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
				} elseif {![ispermban $mask] && ($options(temp) || $options(all))} {
					incr nonperm
					putserv "NOTICE $nickname :#$id - $mask - $creator - [expr {([expr $expirets - [unixtime]] > 0) ? "[clock format $expirets -format "%a %d %b %Y at %H:%M:%S %Z"] (in [duration [expr $expirets - [unixtime]]])" : "Never! (Perm ban)" }]"
				}
			}
			putserv "NOTICE $nickname :End of $channel internal-banlist (Total: $id Permanent: $perm Non-permanent: $nonperm)."
		}
	}
}