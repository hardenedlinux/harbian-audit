#!/bin/bash

#
# harbian audit 9  Hardening
# todo test for centos

#
# 6.18 Ensure virul scan Server update is enabled (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4
VIRULSERVER='clamav-daemon'
CLAMAVCONF_DIR='/etc/clamav/clamd.conf'
UPDATE_SERVER='clamav-freshclam'

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $(systemctl | grep  $VIRULSERVER | grep "active running" | wc -l) -ne 1 ]; then
        crit "$VIRULSERVER is not runing"
        FNRET=1
    else
        ok "$VIRULSERVER is runing"
        UPDATE_DIR=$(grep -i databasedirectory "$CLAMAVCONF_DIR" | awk '{print $2}')
        if [ -d $UPDATE_DIR -a -e $CLAMAVCONF_DIR ]; then
            NOWTIME=$(date +"%s")
			# This file extension name maybe change to .cvd or .cld
            VIRUSTIME=$(stat -c "%Y" "$UPDATE_DIR"/daily.*)
            INTERVALTIME=$((${NOWTIME}-${VIRUSTIME}))
            if [ "${INTERVALTIME}" -ge 604800 ];then
                crit "Database file has a date older than seven days from the current date"
                FNRET=3
            else
                ok "Database file has a date less than seven days from the current date"
                FNRET=0
            fi
        else
            crit "Clamav config file or update dir is not exist"
            FNRET=2
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "Database file has a date less than seven days from the current date"
    elif [ $FNRET = 1 ]; then
        warn "Install $VIRULSERVER"
        apt-get install -y $VIRULSERVER
    elif [ $FNRET = 2 ]; then
        warn "Clamav config file or update dir is not exist, please check that is exist or check config"
    elif [ $FNRET = 3 ]; then
        warn "Database file has a date older than seven days from the current date, start clamav-freshclam.service to update"
        apt-get install -y $UPDATE_SERVER
        systemctl start $UPDATE_SERVER
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
