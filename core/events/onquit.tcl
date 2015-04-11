proc onquit {nickname hostname handle channel {info ""}} {
	if {[isbotnick $nickname]} {
		foreach user [userlist] {
			setuser $user XTRA loggedin 0
		}
	} elseif {![onchan $nickname]} {
		setuser $handle XTRA loggedin 0
	}
	return 0
}