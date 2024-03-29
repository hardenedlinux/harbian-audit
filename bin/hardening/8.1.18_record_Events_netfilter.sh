#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 10/11/12 Hardening
#

#
# 8.1.18 Record netfilter related Events (Scored)
# Author: Samson-W (samson@hardenedlinux.org) author add this 
# todo test for centos

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILE='/etc/audit/rules.d/audit.rules'
PACKAGE_NFT='nftables'

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $PACKAGE_NFT
    	if [ $FNRET != 0 ]; then
		ok "OS not support nft, so pass"
	else 
    	# define custom IFS and save default one
    	d_IFS=$IFS
    	c_IFS=$'\n'
    	IFS=$c_IFS
    	for AUDIT_VALUE in $AUDIT_PARAMS; do
        	debug "$AUDIT_VALUE should be in file $FILE"
        	IFS=$d_IFS
        	does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
        	IFS=$c_IFS
        	if [ $FNRET != 0 ]; then
            	crit "$AUDIT_VALUE is not in file $FILE"
        	else
            	ok "$AUDIT_VALUE is present in $FILE"
        	fi
    	done
    	IFS=$d_IFS
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	is_pkg_installed $PACKAGE_NFT
    	if [ $FNRET != 0 ]; then
		ok "OS not support nft, so pass"
	else 
    	IFS=$'\n'
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
	fi
}

# This function will check config parameters required
check_config() {
	if [ $DONT_AUDITD_BY_UID -eq 1 ]; then
AUDIT_PARAMS='-w /etc/nftables.conf -p wa -k nft_config_file_change
-w /usr/share/netfilter-persistent/plugins.d/ -p wa -k nft_config_file_change
-w /usr/sbin/netfilter-persistent -p x -k nft_persistent_use
-w /usr/sbin/nft -p x -k nft_cmd_use'
	else
AUDIT_PARAMS='-w /etc/nftables.conf -p wa -k nft_config_file_change
-w /usr/share/netfilter-persistent/plugins.d/ -p wa -k nft_config_file_change
-w /usr/sbin/netfilter-persistent -p x -F auid>=1000 -F auid!=4294967295 -k nft_persistent_use
-w /usr/sbin/nft -p x -F auid>=1000 -F auid!=4294967295 -k nft_cmd_use'
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
