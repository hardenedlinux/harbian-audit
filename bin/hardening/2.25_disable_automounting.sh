#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS  Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 2.25 Disable Automounting (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

SERVICE_NAME="autofs"

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $SERVICE_NAME
    if [ $FNRET = 0 ]; then
    	info "Checking if $SERVICE_NAME is enabled"
    	is_service_active $SERVICE_NAME
    	if [ $FNRET = 0 ]; then
        	crit "$SERVICE_NAME is actived"
    	else
        	ok "$SERVICE_NAME is inactived"
    	fi
    else
        ok "$SERVICE_NAME is not installed"
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	is_pkg_installed $SERVICE_NAME
    if [ $FNRET = 0 ]; then
    	info "Checking if $SERVICE_NAME is active"
    	is_service_active $SERVICE_NAME
    	if [ $FNRET = 0 ]; then
			if [ $OS_RELEASE -eq 2 ]; then
				:
			else
        		is_debian_9 
			fi
        	if [ $FNRET = 0 ]; then
            	info "Disabling $SERVICE_NAME"
            	systemctl stop $SERVICE_NAME
            	systemctl disable $SERVICE_NAME
				if [ $OS_RELEASE -eq 2 ]; then
					yum -y autoremove $SERVICE_NAME
				else
            		apt-get -y purge --autoremove $SERVICE_NAME
				fi
        	else
            	info "Disabling $SERVICE_NAME"
            	update-rc.d $SERVICE_NAME remove > /dev/null 2>&1
        	fi
    	else
        	ok "$SERVICE_NAME is disabled"
			if [ $OS_RELEASE -eq 2 ]; then
				yum -y autoremove $SERVICE_NAME
			else
           		apt-get -y purge --autoremove $SERVICE_NAME				
			fi
    	fi
	else
        ok "$SERVICE_NAME is not installed"
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
