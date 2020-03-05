#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9  Hardening
# todo test for centos

#
# 6.18 Ensure virul scan Server update is enabled (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4
CLAMAVCONF_DIR='/etc/clamav/clamd.conf'
UPDATE_SERVER='clamav-freshclam'

audit_debian () {
	does_file_exist $CLAMAVCONF_DIR
	if [ $FNRET -eq 0 ]; then
		UPDATE_DIR=$(grep -i databasedirectory "$CLAMAVCONF_DIR" | awk '{print $2}')
		if [ -d $UPDATE_DIR -a -e $CLAMAVCONF_DIR ]; then
			NOWTIME=$(date +"%s")
			# This file extension name maybe change to .cvd or .cld
			VIRUSTIME=$(stat -c "%Y" "$UPDATE_DIR"/daily.*)
			INTERVALTIME=$((${NOWTIME}-${VIRUSTIME}))
			if [ "${INTERVALTIME}" -ge 604800 ];then
				crit "Clamav database file has a date older than seven days from the current date"
				FNRET=3
			else
				ok "Clamav database file has a date less than seven days from the current date"
				FNRET=0
			fi
		else
			crit "Clamav update dir is not configuration"
			FNRET=2
		fi
	else
			crit "Clamav config file $CLAMAVCONF_DIR not exist"
			FNRET=1
	fi
}

# todo
audit_centos () {
	:
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
		audit_debian
	elif [ $OS_RELEASE -eq 2 ]; then
		audit_centos
	else
		crit "Current OS is not support!"
	fi
}

apply_debian () {
    if [ $FNRET = 0 ]; then
        ok "Clamav database file has a date less than seven days from the current date"
    elif [ $FNRET = 1 ]; then
        warn "Clamav $CLAMAVCONF_DIR is not exist, please check that is exist or check config"
    elif [ $FNRET = 2 ]; then
        warn "Clamav update dir is not exist, please check that is exist or check config"
    elif [ $FNRET = 3 ]; then
        warn "Clamav database file has a date older than seven days from the current date, start clamav-freshclam.service to update"
        apt-get install -y $UPDATE_SERVER
        systemctl start $UPDATE_SERVER
	else
		:
    fi
}

# todo
apply_centos () {
	:
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 1 ]; then
		apply_debian
	elif [ $OS_RELEASE -eq 2 ]; then
		apply_centos
	else
		crit "Current OS is not support!"
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
