#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10 Hardening
#

# This script only support Debian-like desktop, So set to x11 service list 
# 8.1.32 Collect ufw related items (Scored)
# Add by Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4
HARDENING_EXCEPTION=x11

# Find all files with setuid or setgid set
AUDIT_PARAMS='-a always,exit -F dir=/etc/ufw/ -F perm=wa -k ufw_config_file_chg
-a always,exit -F path=/etc/default/ufw -F perm=wa -k ufw_config_file_chg
-a always,exit -F path=/usr/sbin/ufw -F perm=wax -k ufw_command_wax
'
FILE='/etc/audit/rules.d/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $ISEXCEPTION -eq 1 ]; then
		warn "Exception is set to 1, so it's pass!"
	else
   		# define custom IFS and save default one
    	d_IFS=$IFS
    	c_IFS=$'\n'
    	IFS=$c_IFS
    	for AUDIT_VALUE in $AUDIT_PARAMS; do
        	debug "$AUDIT_VALUE should be in file $FILE"
			check_audit_path $AUDIT_VALUE 
			if [ $FNRET -eq 1 ];then
				warn "path is not exsit! Please check file path is exist!"
				continue
			else
        		IFS=$d_IFS
				RESULT=$(echo $AUDIT_VALUE | awk -F"-F" '{print $2}' | awk -F"=" '{print $2}')
				does_valid_pattern_exist_in_file $FILE "$RESULT"
        		IFS=$c_IFS
        		if [ $FNRET != 0 ]; then
            		crit "$RESULT is not in file $FILE"
        		else
            		ok "$RESULT is present in $FILE"
				fi
        	fi
    	done
    	IFS=$d_IFS
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $ISEXCEPTION -eq 1 ]; then
		warn "Exception is set to 1, so it's pass!"
	else
    	IFS=$'\n'
    	for AUDIT_VALUE in $AUDIT_PARAMS; do
        	debug "$AUDIT_VALUE should be in file $FILE"
			check_audit_path $AUDIT_VALUE 
			if [ $FNRET -eq 1 ];then
				warn "path is not exsit! Please check file path is exist!"
				continue
			else
				RESULT=$(echo $AUDIT_VALUE | awk -F"-F" '{print $2}' | awk -F"=" '{print $2}')
				does_valid_pattern_exist_in_file $FILE "$RESULT"
        		if [ $FNRET != 0 ]; then
            		warn "$AUDIT_VALUE is not in file $FILE, adding it"
            		add_end_of_file $FILE $AUDIT_VALUE
					check_auditd_is_immutable_mode
        		else
            		ok "$AUDIT_VALUE is present in $FILE"
				fi
        	fi
    	done
	fi
}

# This function will create the config file for this check with default values
create_config() {
cat <<EOF
status=disabled
# Put here exception to pass this case, if set is 1, don't need apply, let to pass.
ISEXCEPTION=0
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
