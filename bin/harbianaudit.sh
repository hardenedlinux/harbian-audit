#!/bin/bash
# For make deb package 
/opt/harbianaudit/bin/hardening.sh --init
/opt/harbianaudit/bin/hardening.sh --audit-all
/opt/harbianaudit/bin/hardening.sh --set-hardening-level 5
sed -i 's/^status=.*/status=disabled/' /opt/harbianaudit/etc/conf.d/7.4.4_hosts_deny.cfg
sed -i 's/^status=.*/status=disabled/' /opt/harbianaudit/etc/conf.d/8.1.32_freeze_auditd_conf.cfg
sed -i 's/^status=.*/status=disabled/' /opt/harbianaudit/etc/conf.d/8.4.1_install_aide.cfg
sed -i 's/^status=.*/status=disabled/' /opt/harbianaudit/etc/conf.d/8.4.2_aide_cron.cfg
sed -i 's/^status=.*/status=disabled/' /opt/harbianaudit/etc/conf.d/9.5_pam_restrict_su.cfg
/opt/harbianaudit/bin/hardening.sh --apply
sed -i 's/^status=.*/status=enabled/' /opt/harbianaudit/etc/conf.d/8.1.32_freeze_auditd_conf.cfg
sed -i 's/^status=.*/status=enabled/' /opt/harbianaudit/etc/conf.d/8.4.1_install_aide.cfg
sed -i 's/^status=.*/status=enabled/' /opt/harbianaudit/etc/conf.d/8.4.2_aide_cron.cfg
/opt/harbianaudit/bin/hardening.sh --apply --only 8.4.1
/opt/harbianaudit/bin/hardening.sh --apply --only 8.4.2
/opt/harbianaudit/bin/hardening.sh --apply --only 8.1.32
