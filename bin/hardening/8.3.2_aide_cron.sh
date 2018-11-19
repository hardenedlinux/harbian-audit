#!/bin/bash

#
# harbian audit 9  Hardening
#

#
# 8.3.2 Implement Periodic Execution of File Integrity (Scored)
# Modify by:
# Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILES='/etc/crontab /etc/cron.d/*'
PATTERN='/usr/bin/aide.wrapper --check'

# This function will be called if the script status is on enabled / audit mode
audit () {
    does_pattern_exist_in_file "$FILES" "$PATTERN"
    if [ $FNRET != 0 ]; then
        crit "$PATTERN is not present in $FILES"
	FNRET=1
    else
        ok "$PATTERN is present in $FILES"
	FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET != 0 ]; then
        warn "$PATTERN is not present in $FILES, setting aide cron"
        echo "0 10 * * * ${PATTERN} > /dev/null 2>&1 " > /etc/cron.d/CIS_8.3.2_aide
    else
        ok "$PATTERN is present in $FILES"
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
