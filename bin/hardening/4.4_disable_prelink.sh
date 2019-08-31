#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 4.4 Disable Prelink (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='prelink'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET = 0 ]; then
        crit "$PACKAGE is installed!"
    else
        ok "$PACKAGE is absent"
    fi
    :
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then 
		if [ $FNRET = 0 ]; then
        	crit "$PACKAGE is installed, purging it"
			"$(which $PACKAGE)" -ua
			yum autoremove $PACKAGE -y
		else
        	ok "$PACKAGE is absent"
		fi
	elif [ $OS_RELEASE -eq 1 ]; then
		if [ $FNRET = 0 ]; then
        	crit "$PACKAGE is installed, purging it"
        	/usr/sbin/prelink -ua
        	apt-get purge $PACKAGE -y
        	apt-get autoremove
    	else
        	ok "$PACKAGE is absent"
    	fi
	else
		crit "Current OS is not support!"
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
