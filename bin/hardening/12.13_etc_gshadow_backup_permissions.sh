#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10/11/12 or CentOS 8 Hardening
#

#
# 12.13 Verify Permissions on /etc/gshadow- (Scored)
# Author: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=1

FILE='/etc/gshadow-'
PERMISSIONS='640'
PERMISSIONS_CENTOS='0'
USER='root'
GROUP='shadow'
GROUP_CENTOS='root'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		PERMISSIONS=$PERMISSIONS_CENTOS
		GROUP=$GROUP_CENTOS
	else
		:
	fi
	has_file_correct_ownership $FILE $USER $GROUP
	if [ $FNRET = 0 ]; then
		ok "$FILE has correct ownership"
	else
		crit "$FILE ownership was not set to $USER:$GROUP"
	fi
    has_file_correct_permissions $FILE $PERMISSIONS
    if [ $FNRET = 0 ]; then
        ok "$FILE has correct permissions"
    else
        crit "$FILE permissions were not set to $PERMISSIONS"
    fi 
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		PERMISSIONS=$PERMISSIONS_CENTOS
		GROUP=$GROUP_CENTOS
	else
		:
	fi
	has_file_correct_ownership $FILE $USER $GROUP
	if [ $FNRET = 0 ]; then
		ok "$FILE has correct ownership"
	else
		warn "fixing $FILE ownership to $USER:$GROUP"
		chown $USER:$GROUP $FILE
	fi
    has_file_correct_permissions $FILE $PERMISSIONS
    if [ $FNRET = 0 ]; then
        ok "$FILE has correct permissions"
    else
        info "fixing $FILE permissions to $PERMISSIONS"
        chmod 0$PERMISSIONS $FILE
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
