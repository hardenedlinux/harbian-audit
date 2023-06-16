#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10/11/12 Hardening
#

#
# 7.7.5.1 Ensure default deny firewall policy for v6 (Scored)
# for ipv6
# Add this feature:Author : Samson wen, Samson <sccxboy@gmail.com>
#

#set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS6=$(which ip6tables)
IPV6_ENABLE=1
PACKAGE_NFT='nftables'

# This function will be called if the script status is on enabled / audit mode
audit () {
	check_ipv6_is_enable
	IPV6_ENABLE=$FNRET
	if [ $IPV6_ENABLE -eq 0 ]; then
	is_pkg_installed $PACKAGE_NFT
    	if [ $FNRET != 0 ]; then
    		if [ $(${IPS6} -S | grep -c "\-P INPUT DROP") -eq 0 -o  $(${IPS6} -S | grep -c "\-P OUTPUT DROP") -eq 0 -o  $(${IPS6} -S | grep -c "\-P FORWARD DROP") -eq 0 ]; then
				crit "Ip6tables: Firewall policy is not default deny!"
				FNRET=1
			else
				ok "Ip6tables has set default deny for firewall policy!"
				FNRET=0
			fi
		else
			if [ $(nft list chain ip6 filter INPUT 2>/dev/null | grep -c 'input.*policy.*drop') -eq 0 -o $(nft list chain ip6 filter OUTPUT 2>/dev/null | grep -c 'output.*policy.*drop') -eq 0 -o $(nft list chain ip6 filter FORWARD 2>/dev/null | grep -c 'forward.*policy.*drop') -eq 0 ]; then
				crit "nftables's ipv6: Firewall policy is not default deny!"
				FNRET=11
			else
				ok "nftables's ipv6 has set default deny for firewall policy!"
				FNRET=10
			fi
		fi
	else
		ok "Ipv6 has set disabled, so pass."
		FNRET=0
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $IPV6_ENABLE -eq 0 ]; then
    	if [ $FNRET = 0 ]; then
        	ok "Ip6tables has set default deny for firewall policy!"
    	elif [ $FNRET = 1 ]; then
        	warn "Ip6tables is not set default deny for firewall policy! need the administrator to manually add it. Howto set: ip6tables -P INPUT DROP; ip6tables -P OUTPUT DROP; ip6tables -P FORWARD DROP."
    	elif [ $FNRET = 10 ]; then
			ok "nftables's ipv6 has set default deny for firewall policy!"
    	elif [ $FNRET = 11 ]; then
			warn "nftables's ipv6: Firewall policy is not default deny!"
    	fi
	else
		ok "Ipv6 has set disabled, so pass."
	fi
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
