#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 8.2.5 Configure rsyslog to Send Logs to a Remote Log Host (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PATTERN='^*.*[^I][^I]*@'
PACKAGE_NG='syslog-ng'

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $PACKAGE_NG	
	if [ $FNRET = 0 ]; then
		ok "$PACKAGE_NG has installed, so pass."
	else
    	FILES="$SYSLOG_BASEDIR/rsyslog.conf $SYSLOG_BASEDIR/rsyslog.d/*.conf"
    	does_pattern_exist_in_file "$FILES" "$PATTERN"
    	if [ $FNRET != 0 ]; then
			crit "$PATTERN is not present in $FILES"
    	else
        	ok "$PATTERN is present in $FILES"
   	 	fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	is_pkg_installed $PACKAGE_NG	
	if [ $FNRET = 0 ]; then
		ok "$PACKAGE_NG has installed, so pass."
	else
    	FILES="$SYSLOG_BASEDIR/rsyslog.conf $SYSLOG_BASEDIR/rsyslog.d/*.conf"
    	does_pattern_exist_in_file "$FILES" "$PATTERN"
    	if [ $FNRET != 0 ]; then
        	crit "$PATTERN is not present in $FILES, please manual operation set a remote host to send your logs"
    	else
        	ok "$PATTERN is present in $FILES"
    	fi
	fi
}

# This function will create the config file for this check with default values
create_config() {
    cat <<EOF
status=disabled
SYSLOG_BASEDIR='/etc'
EOF
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
