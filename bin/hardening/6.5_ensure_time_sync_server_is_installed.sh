#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9  Hardening
#

#
# 6.19 Ensure time synchronization server is installed ( Not Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
PACKAGES='ntp chrony systemd-timesyncd'

# This function will be called if the script status is on enabled / audit mode
audit () {
    for PACKAGE in $PACKAGES; do 
        is_pkg_installed $PACKAGE
        if [ $FNRET != 0 ]; then
            warn "$PACKAGE is absent"
        else
            ok "$PACKAGE is installed"
	        exit $FNRET
        fi
    done
    crit "$PACKAGES is absent"
}

# This function will be called if the script status is on enabled mode
apply () {
    for PACKAGE in $PACKAGES; do 
        is_pkg_installed $PACKAGE
        if [ $FNRET != 0 ]; then
            warn "$PACKAGE is absent, install..."
            apt-get install -y $PACKAGE
	        exit $FNRET
        else
            ok "$PACKAGE is installed,"
	        exit $FNRET
        fi
    done
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
