#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 13
#

#
# 1.5.5 Ensure kernel.dmesg_restrict is configured
#

set -e
set -u

HARDENING_LEVEL=2


sysctl_check() {
    local param=$1
    local exp_val=$2
    if [ "$(sysctl -n "$param" 2>/dev/null)" = "$exp_val" ]; then
        ok "$param is correctly set to $exp_val"
        FNRET=0
    else
        crit "$param is not set to $exp_val"
        FNRET=1
    fi
}

sysctl_apply() {
    local param=$1
    local exp_val=$2
    warn "Setting $param to $exp_val"
    sysctl -w "$param=$exp_val" || true
    echo "$param = $exp_val" >> /etc/sysctl.d/99-sysctl.conf
}

service_disable_check() {
    local svc=$1
    if systemctl is-enabled "$svc" 2>/dev/null | grep -q "enabled"; then
        crit "$svc is enabled"
        FNRET=1
    else
        ok "$svc is disabled or not installed"
        FNRET=0
    fi
}

service_disable_apply() {
    local svc=$1
    warn "Disabling $svc"
    systemctl disable "$svc" 2>/dev/null || true
    systemctl mask "$svc" 2>/dev/null || true
}

file_limit_check() {
    local conf=$1
    if grep -q "^$conf" /etc/security/limits.conf /etc/security/limits.d/* 2>/dev/null; then
        ok "Limits configured: $conf"
        FNRET=0
    else
        crit "Limits not configured: $conf"
        FNRET=1
    fi
}

file_limit_apply() {
    local conf=$1
    warn "Configuring limits: $conf"
    echo "$conf" >> /etc/security/limits.conf
}

pkg_installed_check() {
    local pkg=$1
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        ok "$pkg is installed"
        FNRET=0
    else
        crit "$pkg is not installed"
        FNRET=1
    fi
}

pkg_installed_apply() {
    local pkg=$1
    warn "Installing $pkg"
    apt-get install -y "$pkg" || true
}

service_enable_check() {
    local svc=$1
    if systemctl is-enabled "$svc" 2>/dev/null | grep -q "enabled"; then
        ok "$svc is enabled"
        FNRET=0
    else
        crit "$svc is not enabled"
        FNRET=1
    fi
}

service_enable_apply() {
    local svc=$1
    warn "Enabling $svc"
    systemctl enable "$svc" 2>/dev/null || true
    systemctl start "$svc" 2>/dev/null || true
}

replace_in_file_custom() {
    local file=$1
    local regex=$2
    local replace=$3
    if [ ! -f "$file" ]; then
        touch "$file"
    fi
    if grep -qE "$regex" "$file"; then
        sed -i -E "s|$regex|$replace|g" "$file"
    else
        echo "$replace" >> "$file"
    fi
}


audit () {
    is_debian_ge_13
    if [ $FNRET = 0 ]; then
        sysctl_check 'kernel.dmesg_restrict' '1'
    else
        ok "Rule is not applicable to OS versions prior to Debian 13."
        FNRET=0
    fi
}

apply () {
    # The main framework automatically calls audit() first to set FNRET based on the current system state.
    # Therefore, we just use the existing $FNRET instead of calling is_debian_ge_13 again which would clobber it.
    if [ $FNRET = 0 ]; then
        ok "Already compliant. Nothing to apply for 1.5.5 Ensure kernel.dmesg_restrict is configured."
    elif [ $FNRET != 0 ]; then
        is_debian_ge_13
        local is_supported=$FNRET
        if [ $is_supported = 0 ]; then
            sysctl_apply 'kernel.dmesg_restrict' '1'
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
