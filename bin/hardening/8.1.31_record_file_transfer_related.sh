#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10 Hardening
#

#
# 8.1.31 Collect file transfer related items (Scored)
# Add by Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILE='/etc/audit/rules.d/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
	echo "DONT_AUDITD_BY_UID $DONT_AUDITD_BY_UID"
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
}

# This function will be called if the script status is on enabled mode
apply () {
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
}

# This function will check config parameters required
check_config() {
	if [ $DONT_AUDITD_BY_UID -eq 1 ]; then
AUDIT_PARAMS='-a always,exit -F path=/usr/bin/scp -F perm=x -k file_transfer_exec
-a always,exit -F path=/usr/bin/wget -F perm=x -k file_transfer_exec
-a always,exit -F path=/usr/bin/sftp -F perm=x -k file_transfer_exec
-a always,exit -F path=/usr/bin/curl -F perm=x -k file_transfer_exec'
	else
AUDIT_PARAMS='-a always,exit -F path=/usr/bin/scp -F perm=x -F auid>=1000 -F auid!=4294967295 -k file_transfer_exec
-a always,exit -F path=/usr/bin/wget -F perm=x -F auid>=1000 -F auid!=4294967295 -k file_transfer_exec
-a always,exit -F path=/usr/bin/sftp -F perm=x -F auid>=1000 -F auid!=4294967295 -k file_transfer_exec
-a always,exit -F path=/usr/bin/curl -F perm=x -F auid>=1000 -F auid!=4294967295 -k file_transfer_exec'
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
