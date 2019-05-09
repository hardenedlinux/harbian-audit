#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 9.3.23 Check SSH public host key permission (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

USER='root'
GROUP='root'
PERMISSIONS='0644'


# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $(find /etc/ssh/ -name "*ssh_host*key" ! -uid 0 -o ! -gid 0 | wc -l) -gt 0 ]; then
		crit "There are file ownership was not set to $USER:$GROUP"
	else
		ok "There are file has correct ownership"
	fi
    if [ $(find /etc/ssh/ -name "*.pub" -perm /133 | wc -l) -gt 0 ]; then
        crit "There are file file has a mode more permissive than $PERMISSIONS"
    else
        ok "Not any file has a mode more permissive than $PERMISSIONS"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $(find /etc/ssh/ -name "*ssh_host*key" ! -uid 0 -o ! -gid 0 | wc -l) -gt 0 ]; then
		warn "There are file ownership was not set to $USER:$GROUP"
		find /etc/ssh/ -name "*ssh_host*key" ! -uid 0 -o ! -gid 0 -exec chown $USER:$GROUP {} \;
	else
		ok "There are file has correct ownership"
	fi
    if [ $(find /etc/ssh/ -name "*.pub" -perm /133 | wc -l) -gt 0 ]; then
        warn "Set ssh public host key permission to $PERMISSIONS"
        find /etc/ssh/ -name "*.pub" -perm /133 -exec chmod $PERMISSIONS {} \;
    else
        ok "Any file has a mode more permissive than $PERMISSIONS"
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
