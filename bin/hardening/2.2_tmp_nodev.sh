#!/bin/bash

#
# harbian audit Debian 7/8/9 Hardening
# Modify by: Samson-W (sccxboy@gmail.com)
#

#
# 2.2 Set nodev option for /tmp Partition/filesystem (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick factoring as many script use the same logic
PARTITION="/tmp"
OPTION="nodev"
SERVICEPATH="/usr/share/systemd/tmp.mount"
SERVICENAME="tmp.mount"

# This function will be called if the script status is on enabled / audit mode
audit () {
    
    info "Verifying that $PARTITION is a partition/filesystem"
    FNRET=0
    #If /tmp is set in /etc/fstab, only check /etc/fstab and disable tmp.mount service if it's exist
    is_a_partition "$PARTITION"
    if [ $FNRET -eq 0 ]; then
		ok "$PARTITION is a partition"
		has_mount_option $PARTITION $OPTION
		if [ $FNRET -eq 0 ]; then
		    ok "$PARTITION has $OPTION in fstab"
		    FNRET=0
	    else
            crit "$PARTITION has no option $OPTION in fstab!"
            FNRET=1
       fi
    else
        warn "$PARTITION is not partition in /etc/fstab, check tmp.mount service"
        if [ -e $SERVICEPATH ]; then
            has_mount_option_systemd $SERVICEPATH $OPTION 
            if [ $FNRET -gt 0 ]; then
                crit "$PARTITION has no option $OPTION in systemd service!"
                FNRET=3
            else
                ok "$PARTITION has $OPTION in systemd service"
                FNRET=0
            fi
        else
            crit "$TMPMOUNTO is not exist!"
            FNRET=2  
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PARTITION is correctly set"
    elif [ $FNRET = 2 ]; then
        crit "$PARTITION is not a partition, correct this by yourself, I cannot help you here"
    elif [ $FNRET = 1 ]; then
        info "Adding $OPTION to fstab"
        add_option_to_fstab $PARTITION $OPTION
        info "Remounting $PARTITION from fstab"
        remount_partition $PARTITION
    elif [ $FNRET = 3 ]; then
        info "Remounting $PARTITION from systemd"
        add_option_to_systemd $SERVICEPATH $OPTION $SERVICENAME
        remount_partition_by_systemd $SERVICENAME $PARTITION
    fi 
}

# This function will check config parameters required
check_config() {
    # No param for this script
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
