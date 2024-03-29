#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9 or CentOS Hardening
# todo base centos7 v2r3 of STIG

#
# 6.19 Configure Network Time Protocol (NTP) (Scored)
# Modify Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3
HARDENING_EXCEPTION=ntp

ANALOGOUS_PKG='chrony systemd-timesyncd'
PACKAGE='ntp'
NTP_CONF_DEFAULT_PATTERN='^restrict -4 default (kod nomodify notrap nopeer noquery|ignore)'
NTP_CONF_FILE='/etc/ntp.conf'
NTP_INIT_PATTERN='RUNASUSER=ntp'
NTP_INIT_FILE='/etc/init.d/ntp'
NTP_POOL_CFG_PATTERN='^(server|pool)'
NTP_POOL_CFG='pool 2.debian.pool.ntp.org iburst'

# This function will be called if the script status is on enabled / audit mode
audit () {
    for PKG in $ANALOGOUS_PKG; do
        is_pkg_installed $PKG
        if [ $FNRET = 0 ]; then
             ok "Analogous pagkage $PKG is installed. So pass check."
             exit               
        fi              
    done        

        is_pkg_installed $PACKAGE
        if [ $FNRET != 0 ]; then
            crit "$PACKAGE is not installed!"
        else
            ok "$PACKAGE is installed, checking configuration"
            does_pattern_exist_in_file $NTP_CONF_FILE $NTP_POOL_CFG_PATTERN
            if [ $FNRET != 0 ]; then
                crit "$NTP_POOL_CFG_PATTERN not found in $NTP_CONF_FILE"
            else
                ok "$NTP_POOL_CFG_PATTERN found in $NTP_CONF_FILE"
            fi
            does_pattern_exist_in_file $NTP_CONF_FILE $NTP_CONF_DEFAULT_PATTERN
            if [ $FNRET != 0 ]; then
                crit "$NTP_CONF_DEFAULT_PATTERN not found in $NTP_CONF_FILE"
            else
                ok "$NTP_CONF_DEFAULT_PATTERN found in $NTP_CONF_FILE"
            fi
            does_pattern_exist_in_file $NTP_INIT_FILE "^$NTP_INIT_PATTERN"
            if [ $FNRET != 0 ]; then
                crit "$NTP_INIT_PATTERN not found in $NTP_INIT_FILE"
            else
                ok "$NTP_INIT_PATTERN found in $NTP_INIT_FILE"
            fi
        fi
}

# This function will be called if the script status is on enabled mode
apply () {
    is_pkg_installed $ANALOGOUS_PKG
    if [ $FNRET = 0 ]; then
        ok "Analogous pagkage $ANALOGOUS_PKG is installed. So pass check. "
    else
        is_pkg_installed $PACKAGE
        if [ $FNRET = 0 ]; then
            ok "$PACKAGE is installed"
        else
            crit "$PACKAGE is absent, installing it"
            apt_install $PACKAGE
            info "Checking $PACKAGE configuration"
        fi
        does_pattern_exist_in_file $NTP_CONF_FILE $NTP_POOL_CFG_PATTERN
        if [ $FNRET != 0 ]; then
        	warn "$NTP_POOL_CFG_PATTERN not found in $NTP_CONF_FILE, adding it"
            backup_file $NTP_CONF_FILE
            add_end_of_file $NTP_CONF_FILE $NTP_POOL_CFG
        else
            ok "$NTP_POOL_CFG_PATTERN found in $NTP_CONF_FILE"
        fi
        does_pattern_exist_in_file $NTP_CONF_FILE $NTP_CONF_DEFAULT_PATTERN
        if [ $FNRET != 0 ]; then
            warn "$NTP_CONF_DEFAULT_PATTERN not found in $NTP_CONF_FILE, adding it"
            backup_file $NTP_CONF_FILE
            add_end_of_file $NTP_CONF_FILE "restrict -4 default kod notrap nomodify nopeer noquery"
        else
            ok "$NTP_CONF_DEFAULT_PATTERN found in $NTP_CONF_FILE"
        fi
        does_pattern_exist_in_file $NTP_INIT_FILE "^$NTP_INIT_PATTERN"
        if [ $FNRET != 0 ]; then
            warn "$NTP_INIT_PATTERN not found in $NTP_INIT_FILE, adding it"
            backup_file $NTP_INIT_FILE
            add_line_file_before_pattern $NTP_INIT_FILE $NTP_INIT_PATTERN "^UGID" 
        else
            ok "$NTP_INIT_PATTERN found in $NTP_INIT_FILE"
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
