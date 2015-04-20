service::commands::register status 400 [namespace current]::status_cmd

proc status_cmd {nickname hostname handle channel text} {
	global lastbind
	helper_xtra_set "lastcmd" $handle "$channel $lastbind $text"
	set option [lindex [split $text] 0]; set color 0
	if {[string equal -nocase "-color" $option] || [string equal -nocase "-colour" $option]} {
		set color 1
	}
	array set status {}
	set status(Protection) [expr {[channel get $channel service_prot] ? "enabled" : "disabled"}]
	set status(Hard-protection) [expr {[channel get $channel service_prot_hard] ? "enabled" : "disabled"}]
	set status(Flyby) [expr {[channel get $channel service_flyby] ? "enabled" : "disabled"}]
	set status(Auto-op) [expr {[channel get $channel service_ao] ? "enabled" : "disabled"}]
	set status(Auto-voice) [expr {[channel get $channel service_av] ? "enabled" : "disabled"}]
	set status(Autolimit) [expr {[channel get $channel service_autolimit] ? "enabled" : "disabled"}]
	set status(Flood) [expr {[channel get $channel service_flood] ? "enabled" : "disabled"}]
	set status(Vip) [expr {[channel get $channel service_vip] ? "enabled" : "disabled"}]
	set status(Vip-skin) [expr {[channel get $channel service_vips] ? "enabled" : "disabled"}]
	set status(Vip-notice) [expr {[channel get $channel service_vipn] ? "notice" : "channel"}]
	set status(Badchan) [expr {[channel get $channel service_badchan] ? "enabled" : "disabled"}]
	set status(Authban) [expr {[channel get $channel service_authban] ? "enabled" : "disabled"}]
	set status(Welcome) [expr {[channel get $channel service_welcome] ? "enabled" : "disabled"}]
	set status(Known) [expr {[channel get $channel service_known] ? "enabled" : "disabled"}]
	set status(Bitchmode) [expr {[channel get $channel service_bitchmode] ? "enabled" : "disabled"}]
	set status(Badword) [expr {[channel get $channel service_badword] ? "enabled" : "disabled"}]
	set status(Auto-msg) [expr {[channel get $channel service_automsg] ? "enabled" : "disabled"}]
	set status(Peak) [expr {[channel get $channel service_peak] ? "enabled" : "disabled"}]
	set status(Enforce-modes) [expr {[channel get $channel service_enforcemodes] ? "enabled" : "disabled"}]
	set status(Enforced-modes) [string map { k, {} l, {} } [channel get $channel service_enforcedmodes]]
	putserv "NOTICE $nickname :Service status for ${channel}:"
	set li [list]
	foreach {type} [lsort [array names status]] {
		if {$type == ""} { continue }
		set stat $status($type)
		if {$stat == ""} { continue }
		if {$color} {
			if {$stat == "enabled"} { 
				set stat "\00303$stat\003"
			} elseif {$stat == "disabled"} {
				set stat "\00304$stat\003"
			} else {
				set stat "\00308$stat\003"
			}
		}
		lappend li "${type}: \002${stat}\002"
		if {[llength $li]>=7} {
			putserv "NOTICE $nickname :\([join $li "\) - \("]\)"
			set li [list]
		}
	}
	if {[llength $li]>=1} {
		putserv "NOTICE $nickname :\([join $li "\) - \("]\)."
	}
	#putserv "NOTICE $nickname :Service status for $channel: (Protection: \002$prot\002 (Hard protection: \002$hard\002)) - (Vip-scanner: \002$vip\002 (Vip-skin: \002$vips\002) (Vip message type: \002$vipn\002)) - (Badchan: \002$badchan\002) - (Authban: \002$authban\002) - (Badword: \002$badword\002) -"
	#putserv "NOTICE $nickname : (Anti-Advertise: \002$advert\002) - (Welcome: \002$welcome\002) - (Known-only: \002$known\002) - (Spamscan: \002$spam\002) - (Anti-Flood: \002$flood\002) - (Flyby: \002$flyby\002) - (Auto-op: \002$ao\002) - (Auto-voice: \002$av\002) - (Auto-limit: \002$al\002) - (Bitchmode: \002$bitchmode\002)."
}