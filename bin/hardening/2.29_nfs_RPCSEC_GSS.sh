#!/bin/bash

#
# harbian audit 9   Hardening
#

#
# 2.29 Set RPCSEC_GSS option for nfs/nfs4 filesystem/Partition (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick factoring as many script use the same logic
PARTITION_TYPE="nfs"
OPTION="sec=krb5:krb5i:krb5p"
FSTAB='/etc/fstab'

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Verifying that $PARTITION_TYPE is a filesystem/partition"
    is_mounted "$PARTITION_TYPE"
    if [ $FNRET -gt 0 ]; then
        no_entity " There is no mount directory with file system type $PARTITION_TYPE"
        FNRET=2
    else
        ok "$PARTITION_TYPE is a partition"
        has_mount_option $PARTITION_TYPE $OPTION
        if [ $FNRET -gt 0 ]; then
            crit "$PARTITION_TYPE has no option $OPTION in fstab!"
            FNRET=1
        else
            ok "$PARTITION_TYPE has $OPTION in fstab"
            has_mounted_option $PARTITION_TYPE $OPTION
            if [ $FNRET -gt 0 ]; then
                warn "$PARTITION_TYPE is not mounted with $OPTION at runtime"
                FNRET=3 
            else
                ok "$PARTITION_TYPE mounted with $OPTION"
            fi
        fi       
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PARTITION_TYPE is correctly set"
    elif [ $FNRET = 2 ]; then
        no_entity " There is no mount directory with file system type $PARTITION_TYPE"
    elif [ $FNRET = 1 ]; then
        info "Adding $OPTION to fstab"
        for PARTITION in $(grep $PARTITION_TYPE $FSTAB | grep -v $OPTION | awk '{print $2}') 
        do
            add_option_to_fstab $PARTITION $OPTION
            info "Remounting $PARTITION from fstab"
            remount_partition $PARTITION
        done
    elif [ $FNRET = 3 ]; then
        info "Remounting $PARTITION_TYPE from fstab"
        remount_partition $PARTITION_TYPE
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
