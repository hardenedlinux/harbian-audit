#!/bin/bash

#
# harbian audit 7/8/9  Hardening
# Modify by: Samson-W (sccxboy@gmail.com)
#

#
# 2.13 Add nosuid Option to Removable Media Partitions (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Fair warning, it only checks /media.* like partition in fstab, it's not exhaustive

# Quick factoring as many script use the same logic
PARTITION_PATTERN="/media\S*"
OPTION="nosuid"

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Verifying if there is $PARTITION_PATTERN like partition"
    FNRET=0
    is_a_partition "$PARTITION_PATTERN"
    if [ $FNRET -gt 0 ]; then
        ok "There is no partition like $PARTITION_PATTERN"
        FNRET=0
    else
		MEDIA_PARNAME=$(grep "[[:space:]]${PARTITION_PATTERN}[[:space:]]*" /etc/fstab | grep -v "^#" | awk '{print $2}')
        info "detected $PARTITION_PATTERN like"
        has_mount_option $MEDIA_PARNAME $OPTION
        if [ $FNRET -gt 0 ]; then
            crit "$MEDIA_PARNAME has no option $OPTION in fstab!"
            FNRET=1
        else
            ok "$MEDIA_PARNAME has $OPTION in fstab"
            FNRET=0
        fi       
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PARTITION_PATTERN is correctly set"
    elif [ $FNRET = 1 ]; then
		MEDIA_PARNAME=$(grep "[[:space:]]${PARTITION_PATTERN}[[:space:]]*" /etc/fstab | grep -v "^#" | awk '{print $2}')
        info "Adding $OPTION to fstab"
        add_option_to_fstab $MEDIA_PARNAME $OPTION
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
