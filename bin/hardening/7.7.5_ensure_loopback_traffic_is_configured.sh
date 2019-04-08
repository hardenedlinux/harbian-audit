#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.5 Ensure loopback traffic is configured (Scored)
# Include ipv4 and ipv6
# Add this feature:Authors : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS4=$(which iptables)
IPS6=$(which ip6tables)

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $(${IPS4} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -eq 0 -o $(${IPS4} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -eq 0 ]; then
		crit "Ip4tables: loopback traffic INPUT is not configured!"
		if [ $(${IPS6} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -eq 0 -o $(${IPS6} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -eq 0 ]; then
			crit "Ip6tables: loopback traffic INPUT is not configured!"
			FNRET=1
			return $FNRET
		else
			ok "Ip6tables loopback traffic INPUT has configured!"
			FNRET=0
		fi
	else
		ok "Ip4tables loopback traffic INPUT has configured!"
		FNRET=0
	fi

    if [ $(${IPS4} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -eq 0 -o $(${IPS4} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -eq 0 ]; then
		crit "Ip4tables: loopback traffic INPUT is not configured!"
		if [ $(${IPS6} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -eq 0 -o $(${IPS6} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -eq 0 ]; then
			crit "Ip6tables: loopback traffic INPUT is not configured!"
			FNRET=1
			return $FNRET
		else
			ok "Ip6tables loopback traffic INPUT has configured!"
			FNRET=0
		fi
	else
		ok "Ip4tables loopback traffic INPUT has configured!"
		FNRET=0
	fi

    if [ $(${IPS4} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -eq 0 -o $(${IPS4} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -eq 0 ]; then
		crit "Ip4tables: loopback traffic INPUT is not configured!"
		if [ $(${IPS6} -S | grep -c "^\-A INPUT \-i lo \-j ACCEPT") -eq 0 -o $(${IPS6} -S | grep -c "^\-A INPUT \-i 127.0.0.1 \-j ACCEPT") -eq 0 ]; then
			crit "Ip6tables: loopback traffic INPUT is not configured!"
			FNRET=1
			return $FNRET
		else
			ok "Ip6tables loopback traffic INPUT has configured!"
			FNRET=0
		fi
	else
		ok "Ip4tables loopback traffic INPUT has configured!"
		FNRET=0
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "Iptables/Ip6tables has set default deny for firewall policy!"
    else
        warn "Iptables/Ip6tables is not set default deny for firewall policy! need the administrator to manually add it. Howto set: iptables/ip6tables -P INPUT DROP; iptables/ip6tables -P OUTPUT DROP; iptables/ip6tables -P FORWARD DROP."
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
