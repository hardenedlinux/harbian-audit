#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 5.8 Ensure openssh server is enabled (Scored)
# Authors : Samson wen, Samson <sccxboy@gmail.com> 
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGES='openssh-server openssh-client'


# This function will be called if the script status is on enabled / audit mode
audit () {
    for PACKAGE in $PACKAGES
    do
        is_pkg_installed $PACKAGE
        if [ $FNRET != 0 ]; then
            crit "$PACKAGE is not installed!"
        else
            ok "$PACKAGE is installed"
        fi
    done
}

# This function will be called if the script status is on enabled mode
apply () {
    for PACKAGE in $PACKAGES
    do
        is_pkg_installed $PACKAGE
        if [ $FNRET = 0 ]; then
            ok "$PACKAGE is installed"
        else
            warn "$PACKAGE is absent, installing it"
            apt_install $PACKAGE
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