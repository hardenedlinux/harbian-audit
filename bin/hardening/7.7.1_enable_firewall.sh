#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
# todo 7.7.* need test for CentOS
#

#
# 7.7.1 Ensure Firewall is active (Scored)
# Corresponds to the original 7.7 
# Modify Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick note here : CIS recommends your iptables rules to be persistent. 
# Do as you want, but this script does not handle this

PACKAGES='iptables iptables-persistent'
PACKAGES_REDHAT='iptables nftables firewalld'
SERVICENAME='netfilter-persistent'

# This function will be called if the script status is on enabled / audit mode
audit () {
    for PACKAGE in $PACKAGES
    do
        is_pkg_installed $PACKAGE
        if [ $FNRET != 0 ]; then
            crit "$PACKAGE is not installed!"
            FNRET=1
            break 
        else
            ok "$PACKAGE is installed"
            FNRET=0
        fi
    done
    if [ $FNRET = 0 ]; then
	    if [ $(systemctl status ${SERVICENAME}  | grep -c "Active:.active") -ne 1 ]; then
            crit "${SERVICENAME} service is not actived"
            FNRET=2
        else
            ok "${SERVICENAME} service is actived"
            FNRET=0
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
        if [ $FNRET = 0 ]; then
            ok "$PACKAGES is installed"
        elif [ $FNRET = 1 ]; then
            for PACKAGE in $PACKAGES
            do
                warn "$PACKAGE is absent, installing it"
                apt_install $PACKAGE
            done
        elif [ $FNRET = 2 ]; then
            warn "Enable ${SERVICENAME} service to actived"
            systemctl start ${SERVICENAME}
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
