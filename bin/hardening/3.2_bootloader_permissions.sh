#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 3.2 Set Permissions on bootloader config (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=1

# Assertion : Grub Based.

FILE='/boot/grub/grub.cfg'
PKGNAME='grub-pc'
PERMISSIONS='400'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		FILE='/boot/grub2/grub.cfg'
	else
		:
	fi
    has_file_correct_permissions $FILE $PERMISSIONS
    if [ $FNRET = 0 ]; then
        ok "$FILE has correct permissions"
        FNRET=0
    else
        crit "$FILE permissions were not set to $PERMISSIONS"
        FNRET=1
    fi 
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		FILE='/boot/grub2/grub.cfg'
	else
		:
	fi
    if [ $FNRET = 0 ]; then
        ok "$FILE has correct permissions"
    else
        info "fixing $FILE permissions to $PERMISSIONS"
        chmod 0$PERMISSIONS $FILE
    fi
}

# This function will check config parameters required
check_config() {
	if [ $OS_RELEASE -eq 2 ]; then
		FILE='/boot/grub2/grub.cfg'
		PKGNAME='grub2-pc'
	else
		:
	fi

	is_pkg_installed "$PKGNAME"
    if [ $FNRET != 0 ]; then
        warn "$PKGNAME is not installed, not handling configuration"
        exit 128
    fi
    if [ $FNRET != 0 ]; then
        crit "$FILE does not exist"
        exit 128
    fi
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
