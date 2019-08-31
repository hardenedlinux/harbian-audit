#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 6.20 Configure Network Time Protocol (chrony) (Scored)
# Author: Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
HARDENING_EXCEPTION=ntp

ANALOGONS_PKG='ntp'
PACKAGE='chrony'
NTP_CONF_FILE='/etc/chrony/chrony.conf'
NTP_SERVER_PATTERN='^(server|pool)'
NTP_POOL_CFG='pool 2.debian.pool.ntp.org iburst'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		ok "Redhat or CentOS does not have this check, so PASS"
	else
    	is_pkg_installed $ANALOGONS_PKG
    	if [ $FNRET = 0 ]; then
			ok "Analogons pagkage $ANALOGONS_PKG is installed. So pass check."
		else
    		is_pkg_installed $PACKAGE
    		if [ $FNRET != 0 ]; then
        		crit "$PACKAGE is not installed!"
    		else	
        		ok "$PACKAGE is installed, checking configuration"
        		does_pattern_exist_in_file $NTP_CONF_FILE $NTP_SERVER_PATTERN
        		if [ $FNRET != 0 ]; then
            		crit "$NTP_SERVER_PATTERN not found in $NTP_CONF_FILE"
        		else
            		ok "$NTP_SERVER_PATTERN found in $NTP_CONF_FILE"
        		fi
    		fi
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		ok "Redhat or CentOS does not have this check, so PASS"
	else
    	is_pkg_installed $ANALOGONS_PKG
    	if [ $FNRET = 0 ]; then
			ok "Analogons pagkage $ANALOGONS_PKG is installed. So pass check."
		else
        	is_pkg_installed $PACKAGE
        	if [ $FNRET = 0 ]; then
            	ok "$PACKAGE is installed"
        	else
            	crit "$PACKAGE is absent, installing it"
            	apt_install $PACKAGE
            	info "Checking $PACKAGE configuration"
      			does_pattern_exist_in_file $NTP_CONF_FILE $NTP_SERVER_PATTERN
        		if [ $FNRET != 0 ]; then
            		warn "$NTP_SERVER_PATTERN not found in $NTP_CONF_FILE, adding it"
            		backup_file $NTP_CONF_FILE
            		add_end_of_file $NTP_CONF_FILE $NTP_POOL_CFG
        		else
            		ok "$NTP_SERVER_PATTERN found in $NTP_CONF_FILE"
        		fi
				exit 1
        	fi
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
