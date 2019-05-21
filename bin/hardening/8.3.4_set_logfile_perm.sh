#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 8.3.4 Create and Set Permissions on syslog-ng Log Files (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PERMISSIONS='640'
USER='root'
GROUP='adm'
SERVICE_NAME_R="rsyslog"

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $SERVICE_NAME_R
	if [ $FNRET = 0 ]; then
		ok "$SERVICE_NAME_R has installed, so pass."
		FNRET=0
	else
		does_file_exist "$SYSLOG_BASEDIR/syslog-ng.conf"
	    if [ $FNRET != 0 ]; then
			warn "$SYSLOG_BASEDIR/syslog-ng.conf is not exist! "
			FNRET=1
		else
    		FILES=$(grep "file(" $SYSLOG_BASEDIR/syslog-ng.conf | grep '"' | cut -d'"' -f 2)
    		for FILE in $FILES; do
        		does_file_exist $FILE
        		if [ $FNRET != 0 ]; then
            		crit "$FILE does not exist"
        		else
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
        		fi
    		done
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
		does_file_exist "$SYSLOG_BASEDIR/syslog-ng.conf"
		if [ $FNRET != 0 ]; then
			warn "$SYSLOG_BASEDIR/syslog-ng.conf is not exist! "
		else
    		FILES=$(grep "file(" $SYSLOG_BASEDIR/syslog-ng.conf | grep '"' | cut -d'"' -f 2)
    		for FILE in $FILES; do
        		does_file_exist $FILE
        		if [ $FNRET != 0 ]; then
					info "$FILE does not exist, create $FILE"
					extend_touch_file $FILE
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
    		done
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
    does_user_exist $USER
    if [ $FNRET != 0 ]; then
        crit "$USER does not exist"
        exit 128
    fi
    does_group_exist $GROUP
    if [ $FNRET != 0 ]; then
        crit "$GROUP does not exist"
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
