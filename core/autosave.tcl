bind time - {?0 * * * *} [namespace current]::autosave
bind time - {?5 * * * *} [namespace current]::autosave

proc autosave {minute hour day month year} {
	putlog "\[ $[namespace current]::script - auto \] - Performing autosave..."
	save
}