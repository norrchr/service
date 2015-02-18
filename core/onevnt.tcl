bind evnt - {*} [namespace current]::onevnt

proc onevnt {type} {
	switch -exact -- $type {
		"init-server" {
			putquick "SBNC :partall" -next
			foreach channel [channels] {
				channel set $channel +service_startup
			}
		}
		"pre-rehash" {
			foreach bind [binds *[namespace current]*] {
				if {$bind == ""} { continue }
				catch {unbind [lindex $bind 0] [lindex $bind 1] [lindex $bind 2] [lindex $bind 4]}
			}
			namespace delete [namespace current]
			save
		}
		"default" {
			return 0
		}
	}
	return 0
}