#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
#

#
# 8.1.7 Record Events That Modify the System's Mandatory Access Controls (Scored)
# Modify by: Samson-W (sccxboy@gmail.com)
#
# todo test for centos

set -u # One variable unset, it's over

HARDENING_LEVEL=4

SELINUX_PKG="selinux-basics"
SELINUX_PKG_REDHAT="selinux-policy"

SE_AUDIT_PARAMS="-a always,exit -F dir=/etc/selinux/ -F perm=wa -k MAC-policy
-a always,exit -F dir=/usr/share/selinux/ -F perm=wa -k MAC-policy
-a always,exit -F path=$(which chcon 2>/dev/null) -F perm=x -F auid>=1000 -F auid!=4294967295 -k perm_chng
-a always,exit -F path=$(which semanage 2>/dev/null) -F auid>=1000 -F auid!=4294967295 -k perm_chng
-a always,exit -F path=$(which setsebool 2>/dev/null) -F auid>=1000 -F auid!=4294967295 -k perm_chng
-a always,exit -F path=$(which setfiles 2>/dev/null) -F auid>=1000 -F auid!=4294967295 -k perm_chng"

APPARMOR_PKG="apparmor"
AA_AUDIT_PARAMS='-w /etc/apparmor/ -p wa -k MAC-policy
-w /etc/apparmor.d/ -p wa -k MAC-policy
-a always,exit -F path=/sbin/apparmor_parser -F perm=x -F auid>=1000 -F auid!=4294967295 -k MAC-policy'

set -e # One error, it's over
FILE='/etc/audit/rules.d/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
	# Set default to apparmor 
	AUDIT_PARAMS=$AA_AUDIT_PARAMS
    # define custom IFS and save default one
    d_IFS=$IFS
    IFS=$'\n'
	if [ $OS_RELEASE -eq 2 ]; then 
		SELINUX_PKG=$SELINUX_PKG_REDHAT
	fi
	is_pkg_installed $SELINUX_PKG
	if [ $FNRET = 0 ]; then
		AUDIT_PARAMS=$SE_AUDIT_PARAMS
		info "SELinux has installed!"
	else
		is_pkg_installed $APPARMOR_PKG
		if [ $FNRET = 0 ]; then
			AUDIT_PARAMS=$AA_AUDIT_PARAMS
			info "Apparmor has installed!"
		else
			crit "SELinux and Apparmor not install!"
		fi
	fi
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE should be in file $FILE"
        does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
        if [ $FNRET != 0 ]; then
            crit "$AUDIT_VALUE is not in file $FILE"
        else
            ok "$AUDIT_VALUE is present in $FILE"
        fi
    done
    IFS=$d_IFS
}

# This function will be called if the script status is on enabled mode
apply () {
    d_IFS=$IFS
    IFS=$'\n'
	if [ $OS_RELEASE -eq 2 ]; then 
		SELINUX_PKG=$SELINUX_PKG_REDHAT
	fi
	is_pkg_installed $SELINUX_PKG
	if [ $FNRET = 0 ]; then
		AUDIT_PARAMS=$SE_AUDIT_PARAMS
		info "SELinux has installed!"
	else
		is_pkg_installed $APPARMOR_PKG
		if [ $FNRET = 0 ]; then
			AUDIT_PARAMS=$AA_AUDIT_PARAMS
			info "Apparmor has installed!"
		else
			crit "SELinux and Apparmor not install!"
		fi
	fi
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE should be in file $FILE"
        does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
        if [ $FNRET != 0 ]; then
            warn "$AUDIT_VALUE is not in file $FILE, adding it"
            add_end_of_file $FILE $AUDIT_VALUE
			check_auditd_is_immutable_mode
        else
            ok "$AUDIT_VALUE is present in $FILE"
        fi
    done
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
