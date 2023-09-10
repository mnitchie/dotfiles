# Strata VPN
alias vpn="/opt/cisco/secureclient/bin/vpn"

function vpnup {
	PSWD=$(security find-generic-password -a ${USER} -s stratavpn -w)
	printf 'michael.nitchie\n%s\npush' "$PSWD" | vpn -s connect sslvpn.strataoncology.com
}
