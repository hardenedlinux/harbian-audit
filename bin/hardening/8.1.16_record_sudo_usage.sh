#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
#

#
# 8.1.16 Collect System Administrator Actions (sudolog) (Scored)
# Modify by: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

SUDOLOG='/var/log/sudo.log' 
AUDIT_VALUE='-w /var/log/sudo.log -p wa -k sudoaction'
FILE='/etc/audit/rules.d/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
    # define custom IFS and save default one
    d_IFS=$IFS
    IFS=$'\n'
	if [ -f $SUDOLOG ]; then
		debug "$AUDIT_VALUE should be in file $FILE"
		does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
		if [ $FNRET != 0 ]; then
			crit "$AUDIT_VALUE is not in file $FILE"
			FNRET=2
		else 
			ok "$AUDIT_VALUE is present in $FILE"
		fi
	else
		crit "file $SUDOLOG is not exist!"
		FNRET=1
	fi
	IFS=$d_IFS
}

# This function will be called if the script status is on enabled mode
apply () {
    # define custom IFS and save default one
    d_IFS=$IFS
    IFS=$'\n'
	if [ $FNRET = 1 ]; then
		warn "file $SUDOLOG is not exist! Set default logfile path in /etc/sudoers."
		sed -i '$aDefaults	logfile="/var/log/sudo.log"' /etc/sudoers
		does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
		if [ $FNRET != 0 ]; then
			warn "$AUDIT_VALUE is not in file $FILE, adding it"
            add_end_of_file $FILE $AUDIT_VALUE
			check_auditd_is_immutable_mode
		fi
	elif [ $FNRET = 2 ]; then
		warn "$AUDIT_VALUE is not in file $FILE, adding it"
		add_end_of_file $FILE $AUDIT_VALUE
		check_auditd_is_immutable_mode
	else
		ok "$AUDIT_VALUE is present in $FILE"
	fi
	IFS=$d_IFS
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
