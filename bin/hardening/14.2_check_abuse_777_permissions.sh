#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10/11 Hardening
#

#
# 14.2 To ensure there are no files permissions are set to 777 (Scored)
# Author: Samson-W (samson@hardenedlinux.org) author add this
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
HARDENING_EXCEPTION=sechardened

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $ISEXCEPTION -eq 1 ]; then
		warn "Exception is set to 1, so it's pass!"
	else
		ABUSECOUNT=$(find / -xdev -type f -perm -777 | wc -l )
		if [ $ABUSECOUNT -gt 0 ]; then
			crit "$ABUSECOUNT files abuse the 777 permission."
			FNRET=1
		else
			ok "There are no files that abuse 777 permissions."
			FNRET=0
		fi	
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $ISEXCEPTION -eq 1 ]; then
		warn "Exception is set to 1, so it's pass!"
	else
		if [ $FNRET -eq 0 ]; then
			ok "There are no files that abuse 777 permissions."
		else
			warn "Some files abuse 777 permissions. Please check and correct yourself!"
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
