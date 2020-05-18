#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10 or CentOS 8 Hardening
# Modify author:
# Samson-W (sccxboy@gmail.com)
#

#
# 8.1.3 Enable Auditing for Processes That Start Prior to auditd (Scored)
#
# todo test for centos

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILE='/etc/default/grub'
KEYWORD='GRUB_CMDLINE_LINUX'
OPTION='audit'
SETVAL=1
SERVICENAME='auditd.service'
PROCCMDLIN='/proc/cmdline'

# This function will be called if the script status is on enabled / audit mode
audit () {
	# Debian 10 (Buster), auditd is a system service 
	is_debian_ge_10
	if [ $FNRET = 0 ]; then
		is_service_active $SERVICENAME
		if [ $FNRET -eq 0 ]; then
			ok "$SERVICENAME is active!"
			FNRET=0
		else
			crit "$SERVICENAME is inactive!"
			FNRET=1
		fi
	else
		if [ $(grep -c "${OPTION}=${SETVAL}" $PROCCMDLIN) -eq 1 ]; then
			ok "There are "${OPTION}=${SETVAL}" in $PROCCMDLIN"
			FNRET=0
		else
			crit "There aren't "${OPTION}=${SETVAL}" in ${PROCCMDLIN}"
            		FNRET=1
    	fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "${OPTION}'s set is correctly."
    elif [ $FNRET = 1 ]; then
		# Debian 10 (Buster), auditd is a system service 
		is_debian_ge_10
		if [ $FNRET = 0 ]; then
			warn "Start $SERVICENAME"
			systemctl start $SERVICENAME
		else
			does_valid_pattern_exist_in_file $FILE "${OPTION}=${SETVAL}"
			if [ $FNRET = 0 ]; then 
        			warn "$OPTION was present in $FILE, just need to reboot the system  after setting it"
			else
				warn "$OPTION is not present in $FILE, add it to $KEYWORD line, need to reboot the system  after setting it"
       				sed -i "s;\(${KEYWORD}=\)\(\".*\)\(\"\);\1\2 ${OPTION}=${SETVAL}\3;" $FILE
				if [ $OS_RELEASE -eq 1 ]; then
        				/usr/sbin/update-grub2 
				elif [ $OS_RELEASE -eq 2 ]; then
					grub2-mkconfig –o /boot/grub2/grub.cfg
				fi
			fi
		fi
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
