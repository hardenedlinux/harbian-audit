#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
#Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 4.1 Restrict Core Dumps (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

LIMIT_FILE='/etc/security/limits.conf'
LIMIT_PATTERN='^\*[[:space:]]*hard[[:space:]]*core[[:space:]]*0$'
SYSCTL_PARAM='fs.suid_dumpable'
SYSCTL_EXP_RESULT=0
SERVICE_NAME='kdump'

audit_debian () {
    does_pattern_exist_in_file $LIMIT_FILE $LIMIT_PATTERN
    if [ $FNRET != 0 ]; then
        crit "$LIMIT_PATTERN not present in $LIMIT_FILE"
    else
        ok "$LIMIT_PATTERN present in $LIMIT_FILE"
    fi
    has_sysctl_param_expected_result "$SYSCTL_PARAM" "$SYSCTL_EXP_RESULT"
    if [ $FNRET != 0 ]; then
        crit "$SYSCTL_PARAM was not set to $SYSCTL_EXP_RESULT"
    elif [ $FNRET = 255 ]; then
        warn "$SYSCTL_PARAM does not exist -- Typo?"
    else
        ok "$SYSCTL_PARAM correctly set to $SYSCTL_EXP_RESULT"
    fi
}

audit_redhat () {
	is_service_active $SERVICE_NAME
	if [ $FNRET -eq 0 ]; then
		crit "$SERVICE_NAME is actived"
		FNRET=1
	else
		ok "$SERVICE_NAME is inactived"
		FNRET=0
	fi
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
        audit_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        audit_redhat
    else
        crit "Current OS is not support!"
        FNRET=44
    fi
}

apply_debian () {
    does_pattern_exist_in_file $LIMIT_FILE $LIMIT_PATTERN
    if [ $FNRET != 0 ]; then
        warn "$LIMIT_PATTERN not present in $LIMIT_FILE, adding at the end of  $LIMIT_FILE"
        add_end_of_file $LIMIT_FILE "* hard core 0"
    else
        ok "$LIMIT_PATTERN present in $LIMIT_FILE"
    fi
    has_sysctl_param_expected_result "$SYSCTL_PARAM" "$SYSCTL_EXP_RESULT"
    if [ $FNRET != 0 ]; then
        warn "$SYSCTL_PARAM was not set to $SYSCTL_EXP_RESULT -- Fixing"
        set_sysctl_param $SYSCTL_PARAM $SYSCTL_EXP_RESULT
    elif [ $FNRET = 255 ]; then
        warn "$SYSCTL_PARAM does not exist -- Typo?"
    else
        ok "$SYSCTL_PARAM correctly set to $SYSCTL_EXP_RESULT"
    fi 

}

apply_redhat () {
	if [ $FNRET -eq 1 ]; then
		info "Disabling $SERVICE_NAME"
		systemctl stop $SERVICE_NAME
		systemctl disable $SERVICE_NAME
	else
		ok "$SERVICE_NAME is disabled"
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 1 ]; then
        apply_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        apply_redhat
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
