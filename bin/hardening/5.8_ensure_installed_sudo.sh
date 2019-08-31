#!/bin/bash

#
# harbian audit 9 or CentOS Hardening
#

#
# 5.8 Ensure sudo is installed (Scored)
# Add feature: 
# Ensure sudo log file is set to /var/log/sudo.log 
# Add new by: 
# Author : Samson wen, Samson <sccxboy@gmail.com> 
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='sudo'
CONFIGFILE='/etc/sudoers'
LOGFILENAME='/var/log/sudo.log'
LOGFILENAME_REP='\/var\/log\/sudo.log'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
		FNRET=1
    else
        ok "$PACKAGE is installed"
		if [ $(grep -c "^Defaults.*logfile=" $CONFIGFILE) -eq 1 ]; then
			if [ $(grep "^Defaults.*logfile=" $CONFIGFILE | grep -c "$LOGFILENAME") -eq 1 ]; then
    	    	ok "Log file is set to $LOGFILENAME in $CONFIGFILE"
				FNRET=0
			else
				crit "Log file path was set, but is not set to $LOGFILENAME"
				FNRET=3
			fi
		else
			crit "sudo Log file is not set in $CONFIGFILE"
			FNRET=2
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {	
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    elif [ $FNRET = 1 ]; then
        warn "$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
		warn "sudo Log file is not set in $CONFIGFILE, add set to"
		add_end_of_file $CONFIGFILE "Defaults	logfile="$LOGFILENAME""
	else
		warn "Log file path was set, but is not set to $LOGFILENAME, modify"
		replace_in_file $CONFIGFILE "logfile=.*" "logfile=$LOGFILENAME_REP"
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
