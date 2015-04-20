bind evnt - "*" [namespace current]::onevnt
bind join - "*" [namespace current]::onjoin
bind part - "*" [namespace current]::onpart
bind sign - "*" [namespace current]::onquit
bind splt - "*" [namespace current]::onsplt
bind rejn - "*" [namespace current]::onrejn
bind need - "*" [namespace current]::onneed
bind flud - "*" [namespace current]::onflud
bind raw - "MODE" [namespace current]::onraw
bind raw - "KICK" [namespace current]::onraw
bind raw - "TOPIC" [namespace current]::onraw
bind raw - "NICK" [namespace current]::onraw
bind raw - "INVITE" [namespace current]::onraw
bind raw - "315" [namespace current]::onraw
bind time - "* * * * *" [namespace current]::ontime_automsg
bind time - "?0 * * * *" [namespace current]::ontime_autosave
bind time - "?5 * * * *" [namespace current]::ontime_autosave