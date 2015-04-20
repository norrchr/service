service::commands::register version -1 version_cmd

proc version_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set modules [loadedmodules]
	puthelp "NOTICE $nickname :[getconf core script]: [getconf core version]_[getconf core verstxt] by [getconf core author] loaded! (Line Count: $linecount) ([llength $modules] module(s) loaded[expr {[llength $modules]>0  ? ": [join $modules ", "]" : ""}])."
}