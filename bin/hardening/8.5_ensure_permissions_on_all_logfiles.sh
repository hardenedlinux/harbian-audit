#!/bin/bash

#
# harbian audit 9  Hardening
#

#
# 8.5 Ensure permissions on all logfiles are configured (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

LOGDIR='/var/log'
PERMISS_MODE='/7137'
PERMISS_SET='0640'

# This function will be called if the script status is on enabled / audit mode
audit () {
	countnum=$(find $LOGDIR -type f -perm $PERMISS_MODE -ls | wc -l)
	if [ $countnum -gt 0 ]; then
		crit  "Permissions of all log files are not correctly configured!"
		FNRET=1
	else
		ok "Permissions of all log files have correctly configured!"
		FNRET=0
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ FNRET = 0 ]; then
		ok "Permissions of all log files have correctly configured!"
	else
		warn  "Permissions of all log files are not correctly configured! Set it"
		chmod -R $PERMISS_SET $LOGDIR/*
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
