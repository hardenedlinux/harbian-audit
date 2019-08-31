#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
#

#
# 8.1.2 Install and Enable auditd Service (Scored)
# Modify by: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

PACKAGE='auditd'
PACKAGE_REDHAT='audit'
SERVICE_NAME='auditd'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		PACKAGE=$PACKAGE_REDHAT
	fi
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
    else
        ok "$PACKAGE is installed"
        is_service_enabled $SERVICE_NAME
        if [ $FNRET = 0 ]; then
            ok "$SERVICE_NAME is enabled"
        else    
            crit "$SERVICE_NAME is not enabled"
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		PACKAGE=$PACKAGE_REDHAT
	fi
	is_pkg_installed $PACKAGE
	if [ $FNRET = 0 ]; then
		ok "$PACKAGE is installed"
	else
		warn "$PACKAGE is absent, installing it"
		if [ $OS_RELEASE -eq 2 ]; then
			yum install -y $PACKAGE
		else
			apt_install $PACKAGE
		fi
	fi
	is_service_enabled $SERVICE_NAME
	if [ $FNRET = 0 ]; then
		ok "$SERVICE_NAME is enabled"
	else    
		warn "$SERVICE_NAME is not enabled, enabling it"
		is_debian_9
		if [ $FNRET = 0 -o $OS_RELEASE -eq 2 ]; then
			systemctl enable $SERVICE_NAME
			systemctl start $SERVICE_NAME
		else
			update-rc.d $SERVICE_NAME remove >  /dev/null 2>&1
			update-rc.d $SERVICE_NAME defaults > /dev/null 2>&1
		fi
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
