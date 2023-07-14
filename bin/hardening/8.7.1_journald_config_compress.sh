#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10/11/12
#

#
# 8.7.1 Ensure journald is configured to compress large log files (Scored)
# Author : Samson wen, Samson <samson@hardenedlinux.org>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

CONFFILE='/etc/systemd/journald.conf'
OPTION='Compress'
OPTION_VAL='yes'

# This function will be called if the script status is on enabled / audit mode
audit () {
	check_param_pair_by_str $CONFFILE $OPTION $OPTION_VAL 
	if [ $FNRET = 0 ]; then
		ok "$OPTION set is $OPTION_VAL in $CONFFILE."
	elif [ $FNRET = 1 ]; then
		crit "$CONFFILE is not found!"
	elif [ $FNRET = 2 ]; then
		crit "$OPTION set is not $OPTION_VAL in $CONFFILE!"
	elif [ $FNRET = 3 ]; then
		crit  "$OPTION is not present in $CONFFILE!"
	fi
}

apply () {
	if [ $FNRET = 0 ]; then
		ok "$OPTION set is $OPTION_VAL in $CONFFILE."
	elif [ $FNRET = 1 ]; then
		crit "$CONFFILE is not found, please check!"
	elif [ $FNRET = 2 ]; then
		warn "$OPTION set is not $OPTION_VAL in $CONFFILE, reset to $OPTION_VAL"
		reset_option_str_to_journald $CONFFILE $OPTION $OPTION_VAL
	elif [ $FNRET = 3 ]; then
		warn  "$OPTION is not present in $CONFFILE, add to $CONFFILE"
		add_end_of_file $CONFFILE "${OPTION}=${OPTION_VAL}"
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
