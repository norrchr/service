proc vip_authbl_default {channel nickname handle lastbind text} {
	putserv "NOTICE $nickname :SYNTAX: $lastbind add|del|list|on|off|status."
}