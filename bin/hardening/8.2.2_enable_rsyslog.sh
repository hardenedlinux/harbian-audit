#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 8.2.2 Ensure the rsyslog Service is activated (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

SERVICE_NAME="rsyslog"
PACKAGE_NG='syslog-ng'

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $PACKAGE_NG	
	if [ $FNRET = 0 ]; then
		ok "$PACKAGE_NG has installed, so pass."
		FNRET=0
	else
    	info "Checking if $SERVICE_NAME is enabled"
    	is_service_enabled $SERVICE_NAME
    	if [ $FNRET = 0 ]; then
        	ok "$SERVICE_NAME is enabled"
			FNRET=0
    	else
        	crit "$SERVICE_NAME is disabled"
			FNRET=1
    	fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET != 0 ]; then
        info "Enabling $SERVICE_NAME"
        systemctl enable $SERVICE_NAME > /dev/null 2>&1
        systemctl daemon-reload $SERVICE_NAME > /dev/null 2>&1
        systemctl start $SERVICE_NAME > /dev/null 2>&1
    else
        ok "$SERVICE_NAME is enabled or $PACKAGE_NG is installed."
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
