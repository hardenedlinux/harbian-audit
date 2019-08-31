#!/bin/bash

#
# harbian audit 9 or CentOS Hardening
#

#
# 5.4 Ensure ctrl-alt-del is disabled (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com> 
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

TARGETNAME='ctrl-alt-del.target'

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $(find /lib/systemd/ /etc/systemd/ -name ctrl-alt-del.target -exec ls -l {} \; | grep -c "/dev/null") -ne $(find /lib/systemd/ /etc/systemd/ -name ctrl-alt-del.target -exec ls -l {} \; | wc -l) ]; then
        crit "$TARGETNAME is enabled."
        FNRET=1
    else
        ok "$TARGETNAME is disabled."
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$TARGETNAME is disabled."
    else
        TARGETS=$(find /lib/systemd/ /etc/systemd/ -name ctrl-alt-del.target -exec ls {} \;| grep -v "/dev/null" | awk '{print $NF}')
        for TARGET in $TARGETS
        do
            warn "Disable $TARGET"
            if [ $TARGET ==  "/etc/systemd/*" ]; then
                systemctl mask $TARGET
            else
                rm $TARGET 
            fi
        done
        systemctl daemon-reload
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
