#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10/11/12  Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 2.23 Disable Mounting of squashfs Filesystems (Not Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

HARBIAN_SEC_CONF_FILE='/etc/modprobe.d/harbian-security-workaround.conf'
KERNEL_OPTION="CONFIG_SQUASHFS"
MODULE_NAME="squashfs"

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_kernel_option_enabled $KERNEL_OPTION $MODULE_NAME
    if [ $FNRET = 0 ]; then # 0 means true in bash, so it IS activated
        debug "$MODULE_NAME's kernel option is enabled"
	check_blacklist_module_set $MODULE_NAME
    	if [ $FNRET = 0 ]; then
		ok "$MODULE_NAME was set to blacklist"
	else
		crit "$MODULE_NAME is not set to blacklist"
	fi
    else
        ok "$MODULE_NAME's kernel option is disabled"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    is_kernel_option_enabled $KERNEL_OPTION $MODULE_NAME
    if [ $FNRET = 0 ]; then # 0 means true in bash, so it IS activated
        debug "$MODULE_NAME's kernel option is enabled"
		check_blacklist_module_set $MODULE_NAME
    	if [ $FNRET = 0 ]; then
		ok "$MODULE_NAME was set to blacklist"
	else
		warn "$MODULE_NAME is not set to blacklist, add to config file $HARBIAN_SEC_CONF_FILE"
		if [ -w $HARBIAN_SEC_CONF_FILE ]; then
			add_end_of_file "$HARBIAN_SEC_CONF_FILE" "blacklist $MODULE_NAME"
		else
			touch $HARBIAN_SEC_CONF_FILE
			add_end_of_file "$HARBIAN_SEC_CONF_FILE" "blacklist $MODULE_NAME"
		fi
	fi
    else
        ok "$KERNEL_OPTION is disabled, nothing to do"
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
