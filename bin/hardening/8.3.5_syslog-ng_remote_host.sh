#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 8.3.5 Configure syslog-ng to Send Logs to a Remote Log Host (Not Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
SERVICE_NAME_R="rsyslog"
PATTERN='^destination.*(tcp|udp)[[:space:]]*\([[:space:]]*\".*\"[[:space:]]*\)'

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $SERVICE_NAME_R
	if [ $FNRET = 0 ]; then
		ok "$SERVICE_NAME_R has installed, so pass."
		FNRET=0
	else
		if [ -d "$SYSLOG_BASEDIR" ]; then
    		FILES="$SYSLOG_BASEDIR/syslog-ng.conf $SYSLOG_BASEDIR/conf.d/*"
    		does_pattern_exist_in_file "$FILES" "$PATTERN"
    		if [ $FNRET != 0 ]; then
        		crit "$PATTERN is not present in $FILES"
    		else
        		ok "$PATTERN is present in $FILES"
    		fi
		else
			warn "$SYSLOG_BASEDIR is not exist!"
			FNRET=1	
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	is_pkg_installed $SERVICE_NAME_R
	if [ $FNRET = 0 ]; then
		ok "$SERVICE_NAME_R has installed, so pass."
		FNRET=0
	else
		if [ $FNRET = 1 ]; then  
			warn "$SYSLOG_BASEDIR is not exist!"
		else
    		FILES="$SYSLOG_BASEDIR/syslog-ng.conf $SYSLOG_BASEDIR/conf.d/*"
    		does_pattern_exist_in_file "$FILES" "$PATTERN"
    		if [ $FNRET != 0 ]; then
        		crit "$PATTERN is not present in $FILES, please set a remote host to send your logs"
    		else
        		ok "$PATTERN is present in $FILES"
    		fi
		fi
	fi
}

# This function will create the config file for this check with default values
create_config() {
    cat <<EOF
status=disabled
SYSLOG_BASEDIR='/etc/syslog-ng'
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
