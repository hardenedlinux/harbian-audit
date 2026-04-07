#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 13
#

#
# 4.1.2 Ensure ufw service is configured
#

set -e
set -u

HARDENING_LEVEL=2




audit () {
    is_debian_ge_13
    if [ $FNRET = 0 ]; then
        service_enable_check 'ufw.service'
    else
        ok "Rule is not applicable to OS versions prior to Debian 13."
        FNRET=0
    fi
}

apply () {
    # The main framework automatically calls audit() first to set FNRET based on the current system state.
    # Therefore, we just use the existing $FNRET instead of calling is_debian_ge_13 again which would clobber it.
    if [ $FNRET = 0 ]; then
        ok "Already compliant. Nothing to apply for 4.1.2 Ensure ufw service is configured."
    elif [ $FNRET != 0 ]; then
        is_debian_ge_13
        local is_supported=$FNRET
        if [ $is_supported = 0 ]; then
            service_enable_apply 'ufw.service'
        else
            ok "Rule is not applicable to OS versions prior to Debian 13."
        fi
    fi
}

check_config() {
    :
}

if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
    echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
    echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory?"
    exit 128
fi
