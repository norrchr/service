proc autosave {minute hour day month year} {
	putlog "\[ $[namespace current]::script - auto \] - Performing autosave..."
	save
}