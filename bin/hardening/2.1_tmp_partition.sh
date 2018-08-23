#!/bin/bash

#
# harbian audit Debian 9 Hardening
#

#
# 2.1 Create Separate Partition for /tmp (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

# Quick factoring as many script use the same logic
PARTITION="/tmp"
TMPMOUNTNAME="tmp.mount"
TMPMOUNTO="/usr/share/systemd/tmp.mount"
TMPMOUNTN="/etc/systemd/system/tmp.mount"

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Verifying that $PARTITION is a file system/partition"
    FNRET=0
    is_mounted "$PARTITION"
    if [ $FNRET -gt 0 ]; then
    	crit "$PARTITION is not mounted"
        FNRET=1
    else
        ok "$PARTITION is mounted"
    fi
    :
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PARTITION is correctly set"
    else
        info "mounting $PARTITION"
	if [ -a $TMPMOUNTN ]; then
		$SUDO_CMD systemctl enable "$TMPMOUNTNAME"
	elif [ -a $TMPMOUNTO ]; then
		$SUDO_CMD cp $TMPMOUNTO $TMPMOUNTN
		$SUDO_CMD systemctl enable "$TMPMOUNTNAME"
	fi
	$SUDO_CMD systemctl daemon-reload 
	$SUDO_CMD systemctl start "$TMPMOUNTNAME"
    fi
}

# This function will check config parameters required
check_config() {
    # No parameter for this script
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
