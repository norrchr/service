#rename newban anewban
#proc newban {ban creator comment {lifetime "60"} {options "none"}} { 
#	if {$ban == "*!*@" || $ban == "*!*@*" || $ban == "*!**@*" || $ban == "*!**@"} { 
#		putlog "newban: (bad banmask: $ban) - $ban $creator '$comment' [expr {[info exists lifetime] ? "$lifetime" : ""}] [expr {[info exists options] ? "$options" : ""}]"
#	} else { 
#		anewban $ban $creator $comment $lifetime $options
#	} 
#}


#rename newchanban anewchanban
#proc newchanban {channel ban creator comment {lifetime "60"} {options "none"}} { 
#	if {$ban == "*!*@" || $ban == "*!*@*" || $ban == "*!**@*" || $ban == "*!**@"} { 
#		putlog "newchanban: (bad banmask: $ban) - $channel $ban $creator '$comment' [expr {[info exists lifetime] ? "$lifetime" : ""}] [expr {[info exists options] ? "$options" : ""}]"
#	} else { 
#		anewchanban $channel $ban $creator $comment $lifetime $options
#	} 
#}