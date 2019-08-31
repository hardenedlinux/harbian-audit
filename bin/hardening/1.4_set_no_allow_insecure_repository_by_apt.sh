#!/bin/bash

#
# harbian audit Debian 9/CentOS Hardening
#

#
# 1.4 Set no allow insecure repository when by apt update (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2
OPTION='AllowInsecureRepositories'

YUM_OPTION='repo_gpgcheck'
YUM_CONFFILE='/etc/yum.conf'

audit_debian () {
    if [ $(grep -v "^#" /etc/apt/ -r | grep -c "${OPTION}.*true") -gt 0 ]; then
        crit "The allow insecure repository when by apt update is enable"
        FNRET=1
    else
        ok "The allow insecure repository when by apt update is disable"
        FNRET=0
    fi
}

audit_redhat ()
{
    if [ $(grep -c "^$YUM_OPTION" $YUM_CONFFILE) -gt 0 ]; then
		if [ $(grep "^$YUM_OPTION" $YUM_CONFFILE | awk -F"=" '{print $2}') -eq 1 ]; then
			ok "The allow insecure repository when by yum update is disable"
			FNRET=0
        else
            crit "The signature of repodata option is disable "
            FNRET=1
        fi
    else
        crit "Option $YUM_OPTION is not set in $YUM_CONFFILE!"
        FNRET=2
    fi
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
        audit_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        audit_redhat
    else
        crit "Current OS is not support!"
        FNRET=44
    fi
}

apply_debian () {
    if [ $FNRET = 0 ]; then 
        ok "The allow insecure repository when by apt update is disable"
    else
        warn "Set no allow insecure repository when by apt update"
        for CONFFILE in $(grep -i "${OPTION}" /etc/apt/ -r | grep -v "^#" | awk -F: '{print $1}')
        do
            sed -i "s/${OPTION}.*true.*/${OPTION} \"false\";/g" ${CONFFILE}
        done
    fi
}

apply_redhat () {
	if [ $FNRET = 0 ]; then
		ok "The signature of repodata option is enable "
    elif [ $FNRET = 1 ]; then
        warn "Set to enabled signature of repodata option"
        sed -i "s/$YUM_OPTION=.*/$YUM_OPTION=1/g" $YUM_CONFFILE
    else
        warn "Add $YUM_OPTION option to $YUM_CONFFILE"
        add_end_of_file $YUM_CONFFILE "$YUM_OPTION=1"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 1 ]; then
        apply_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        apply_redhat
    else
        crit "Current OS is not support!"
    fi
}
# This function will check config parameters required
check_config() {
    # No parameters for this function
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
