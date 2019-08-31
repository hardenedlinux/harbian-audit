#!/bin/bash

#
# harbian audit 7/8/9 or CentOS Hardening
#

#
# 6.14 Ensure SNMP Server is not enabled (Not Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
HARDENING_EXCEPTION=snmp

PACKAGES='snmpd'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		ok "Redhat or CentOS does not have this check, so PASS"
	else
    	for PACKAGE in $PACKAGES; do
        	is_pkg_installed $PACKAGE
        	if [ $FNRET = 0 ]; then
            	if [ $ISEXCEPTION -eq 1 ]; then
                	warn "$PACKAGE is installed! But Exception is set to 1, so it's pass!"
            	else
                	crit "$PACKAGE is installed!"
            	fi
        	else
            	ok "$PACKAGE is absent"
        	fi
    	done
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		ok "Redhat or CentOS does not have this check, so PASS"
	else
    	for PACKAGE in $PACKAGES; do
        	is_pkg_installed $PACKAGE
        	if [ $FNRET = 0 ]; then
            	if [ $ISEXCEPTION -eq 1 ]; then
                	warn "$PACKAGE is installed! But the exception is set to true, so don't need any operate."
            	else
                	crit "$PACKAGE is installed, purging it"
                	apt-get purge $PACKAGE -y
            	fi
        	else
            	ok "$PACKAGE is absent"
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
