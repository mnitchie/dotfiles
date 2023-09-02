# Strata VPN
#alias vpn="/opt/cisco/secureclient/bin/vpn"
alias vpn="/opt/cisco/anyconnect/bin/vpn"

function vpnup {
	PSWD=$(security find-generic-password -a ${USER} -s stratavpn -w)
	printf 'michael.nitchie\n%s\npush' "$PSWD" | vpn -s connect sslvpn.strataoncology.com
}
