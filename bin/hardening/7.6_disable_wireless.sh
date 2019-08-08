#!/bin/bash

#
# harbian audit 9 or CentOS Hardening
#

#
# 7.6 Ensure wireless interfaces are disabled (Not Scored)
# Author : Samson wen, Samson <samson@hardenedlinux.org>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $(lspci  | grep -ic wireless ) -eq 0 ]; then
		info "The OS is not wireless device! "
		FNRET=0
	else
		if [ $(wc -l /proc/net/wireless) -lt 3 ]; then
			ok "Wireless interfaces are disabled!"
			FNRET=0
		else
			crit "Wireless interfaces is not disabled!"
			FNRET=1
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $FNRET = 0 ]; then
		ok "Wireless interfaces are disabled!"
	else
		warn "Wireless interfaces is not disabled! Disabled wireless."
		nmcli radio wifi off
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
## Source Root Dir Parameter
#if [ ! -r /etc/default/cis-hardening ]; then
#    echo "There is no /etc/default/cis-hardening file, cannot source CIS_ROOT_DIR variable, aborting"
#    exit 128
#else
#    . /etc/default/cis-hardening
#    if [ -z ${CIS_ROOT_DIR:-} ]; then
#        echo "No CIS_ROOT_DIR variable, aborting"
#        exit 128
#    fi
#fi 

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
