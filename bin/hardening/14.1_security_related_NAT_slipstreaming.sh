#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10 Hardening
#

#
# 14.1  Defense for NAT Slipstreaming (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
HARDENING_EXCEPTION=sechardened

HARBIAN_SEC_CONF_FILE='/etc/modprobe.d/harbian-security-workaround.conf'
BLACKLIST_CONF_ITEMS='nf_nat_sip nf_conntrack_sip'
SYSCTL_PARAM='net.netfilter.nf_conntrack_helper'
SYSCTL_EXP_RESULT=0

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $ISEXCEPTION -eq 1 ]; then
		warn "Exception is set to 1, so it's pass!"
	else
		for BLACKLIST_CONF in $BLACKLIST_CONF_ITEMS; do	
			check_blacklist_module_set $BLACKLIST_CONF
    		if [ $FNRET = 0 ]; then
				ok "$BLACKLIST_CONF was set to blacklist"
			else
				crit "$BLACKLIST_CONF is not set to blacklist"
			fi
		done
		if [ -r /proc/sys/net/netfilter/nf_conntrack_helper ]; then
    		has_sysctl_param_expected_result $SYSCTL_PARAM $SYSCTL_EXP_RESULT
    		if [ $FNRET != 0 ]; then
				crit "$SYSCTL_PARAM was not set to $SYSCTL_EXP_RESULT"
    		elif [ $FNRET = 255 ]; then
        		warn "$SYSCTL_PARAM does not exist -- Typo?"
    		else
        		ok "$SYSCTL_PARAM correctly set to $SYSCTL_EXP_RESULT"
			fi
		else
			crit "/proc/sys/net/netfilter/nf_conntrack_helper is not exist, connection tracking may not be enabled, so please determine the risk yourself."
    	fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $ISEXCEPTION -eq 1 ]; then
		warn "Exception is set to 1, so it's pass!"
	else
		for BLACKLIST_CONF in $BLACKLIST_CONF_ITEMS; do	
			check_blacklist_module_set $BLACKLIST_CONF
    		if [ $FNRET = 0 ]; then
				ok "$BLACKLIST_CONF was set to blacklist"
			else
				warn "$BLACKLIST_CONF is not set to blacklist, add to config file $HARBIAN_SEC_CONF_FILE"
				if [ -w $HARBIAN_SEC_CONF_FILE ]; then
					add_end_of_file "$HARBIAN_SEC_CONF_FILE" "blacklist $BLACKLIST_CONF"
				else
					touch $HARBIAN_SEC_CONF_FILE
					add_end_of_file "$HARBIAN_SEC_CONF_FILE" "blacklist $BLACKLIST_CONF"
				fi
			fi
		done
		if [ -r /proc/sys/net/netfilter/nf_conntrack_helper ]; then
    		has_sysctl_param_expected_result $SYSCTL_PARAM $SYSCTL_EXP_RESULT
    		if [ $FNRET != 0 ]; then
				warn "$SYSCTL_PARAM was not set to $SYSCTL_EXP_RESULT -- Fixing"
				set_sysctl_param $SYSCTL_PARAM $SYSCTL_EXP_RESULT
				sysctl -w $SYSCTL_PARAM=$SYSCTL_EXP_RESULT > /dev/null
    		elif [ $FNRET = 255 ]; then
        		warn "$SYSCTL_PARAM does not exist -- Typo?"
    		else
        		ok "$SYSCTL_PARAM correctly set to $SYSCTL_EXP_RESULT"
    		fi
		else
			warn "/proc/sys/net/netfilter/nf_conntrack_helper is not exist, just set $SYSCTL_PARAM = $SYSCTL_EXP_RESULT to /etc/sysctl.conf"
			if [ $(grep "^$SYSCTL_PARAM = $SYSCTL_EXP_RESULT" /etc/sysctl.conf | wc -l) -eq 0 ]; then
				echo "$SYSCTL_PARAM = $SYSCTL_EXP_RESULT" >> /etc/sysctl.conf
			else
				:
			fi
		fi
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
