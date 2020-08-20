# harbian-audit with the UOS server deploy

## Introduction 
This release only support UOS server V20.

## Usage

### Pre-Install 
```
# apt-get install -y bc net-tools pciutils network-manager 
```

### Start harbian-audit 
```console
$ git clone https://github.com/hardenedlinux/harbian-audit.git && cd harbian-audit
# cp etc/default.cfg /etc/default/cis-hardening
# sed -i "s#CIS_ROOT_DIR=.*#CIS_ROOT_DIR='$(pwd)'#" /etc/default/cis-hardening
# bin/hardening.sh --init
# bin/hardening.sh --audit-all
hardening                 [INFO] Treating /home/test/harbian-audit/bin/hardening/1.1_install_updates.sh
1.1_install_updates       [INFO] Working on 1.1_install_updates
1.1_install_updates       [INFO] Checking Configuration
1.1_install_updates       [INFO] Performing audit
1.1_install_updates       [INFO] Checking if apt needs an update
1.1_install_updates       [INFO] Fetching upgrades ...
1.1_install_updates       [ OK ] No upgrades available
1.1_install_updates       [ OK ] Check Passed
[...]
################### SUMMARY ###################
      Total Available Checks : 272
         Total Runned Checks : 272
         Total Passed Checks : [ 240/272 ]
         Total Failed Checks : [  32/272 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 88.24 %
# bin/hardening.sh --set-hardening-level 5
# sed -i 's/^status=.*/status=disabled/' etc/conf.d/7.4.4_hosts_deny.cfg
# sed -i 's/^status=.*/status=disabled/' etc/conf.d/8.1.32_freeze_auditd_conf.cfg
# sed -i 's/^status=.*/status=disabled/' etc/conf.d/8.4.1_install_aide.cfg
# sed -i 's/^status=.*/status=disabled/' etc/conf.d/8.4.2_aide_cron.cfg
# sed -i 's/^status=.*/status=disabled/' etc/conf.d/9.5_pam_restrict_su.cfg
# bin/hardening.sh --apply 
hardening                 [INFO] Treating /home/test/harbian-audit/bin/hardening/1.1_install_updates.sh
1.1_install_updates       [INFO] Working on 1.1_install_updates
1.1_install_updates       [INFO] Checking Configuration
1.1_install_updates       [INFO] Performing audit
1.1_install_updates       [INFO] Checking if apt needs an update
1.1_install_updates       [INFO] Fetching upgrades ...
1.1_install_updates       [ OK ] No upgrades available
1.1_install_updates       [INFO] Applying Hardening
1.1_install_updates       [ OK ] No Upgrades to apply
1.1_install_updates       [ OK ] Check Passed
[...]
# sed -i 's/^status=.*/status=enabled/' etc/conf.d/8.1.32_freeze_auditd_conf.cfg
# sed -i 's/^status=.*/status=enabled/' etc/conf.d/8.4.1_install_aide.cfg
# sed -i 's/^status=.*/status=enabled/' etc/conf.d/8.4.2_aide_cron.cfg
# ./bin/hardening.sh --apply --only 8.4.1
# ./bin/hardening.sh --apply --only 8.4.2
# ./bin/hardening.sh --apply --only 8.1.32
```

## After remediation (Very important)
When exec --apply and set-hardening-level are set to 5 (the highest level), you need to do the following:

1) When applying 9.5(Restrict Access to the su Command), you must use the root account to log in to the OS because ordinary users cannot perform subsequent operations. 
If you can only use ssh for remote login, you must use the su command when the normal user logs in. Then do the following:
```
# sed -i '/^[^#].*pam_wheel.so.*/s/^/# &/' /etc/pam.d/su 
```
Temporarily comment out the line containing pam_wheel.so. After you have finished using the su command, please uncomment the line.

2) When applying 7.4.4_hosts_deny.sh, the OS cannot be connected through the ssh service, so you need to set allow access host list on /etc/hosts.allow, example:
```
# echo "ALL: 192.168.1. 192.168.5." >> /etc/hosts.allow
```
This example only allows 192.168.1.[1-255] 192.168.5.[1-255] to access this system. Need to be configured according to your situation. 

3) Set capabilities for usual user, example(user name is test):
```
# sed -i "/^root/a\test    ALL=(ALL:ALL) ALL" /etc/sudoers 
```

4) Set basic firewall rules 
Set the corresponding firewall rules according to the applications used. HardenedLinux community for Debian GNU/Linux basic firewall rules: 

Iptabels format rules:
[etc.iptables.rules.v4.sh](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.iptables.rules.v4.sh)
to do the following:
```
$ INTERFACENAME="your network interfacename(Example eth0)"
# bash docs/configurations/etc.iptables.rules.v4.sh $INTERFACENAME

# iptables-save > /etc/iptables/rules.v4 
# ip6tables-save > /etc/iptables/rules.v6 
```

5) Config grub2 password protection
[Config grub2 password protection](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_config_grub2_password_protection.mkd) 

## Special Note 
Some check items check a variety of situations and are interdependent, they must be applied (fix) multiple times, and the OS must be a reboot after each applies (fix). 

### Items that must be applied after the first application(reboot after is better)
8.1.32  Because this item is set, the audit rules will not be added. 

### Items that must be applied after all application is ok
8.4.1   
8.4.2   
These are all related to the aide. It is best to fix all the items after they have been fixed to fix the integrity of the database in the system. 

### Items that need to be fix twice  
8.1.1.2  
8.1.1.3  
8.1.12  
4.5  

## Document 

### Harbian-audit benchmark for Debian GNU/Linux 9 
This document is a description of the additions to the sections not included in the [CIS reference documentation](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100). Includes STIG reference documentation and additional checks recommended by the HardenedLinux community. 

[CIS Debian GNU/Linux 8 Benchmark v1.0.0](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100)  
[CIS Debian GNU/Linux 9 Benchmark v1.0.0](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100)  
[harbian audit Debian Linux 9 Benchmark](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/harbian_audit_Debian_9_Benchmark_v0.1.mkd)  
  
## harbian-audit License   
GPL 3.0 

## OVH Disclaimer

This project is a set of tools. They are meant to help the system administrator
built a secure environment. While we use it at OVH to harden our PCI-DSS compliant
infrastructure, we can not guarantee that it will work for you. It will not
magically secure any random host.

Additionally, quoting the License:

> THIS SOFTWARE IS PROVIDED BY OVH SAS AND CONTRIBUTORS ``AS IS'' AND ANY
> EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
> WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
> DISCLAIMED. IN NO EVENT SHALL OVH SAS AND CONTRIBUTORS BE LIABLE FOR ANY
> DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
> (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
> LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
> ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
> (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
> SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## OVH License
3-Clause BSD

## Reference

- **Center for Internet Security**: [https://www.cisecurity.org](https://www.cisecurity.org)
- **STIG V1R4**: [https://iasecontent.disa.mil/stigs/zip/U_Red_Hat_Enterprise_Linux_7_V1R4_STIG.zip](https://iasecontent.disa.mil/stigs/zip/U_Red_Hat_Enterprise_Linux_7_V1R4_STIG.zip) 
- **Firewall Rules**: [https://github.com/citypw/arsenal-4-sec-testing/blob/master/bt5_firewall/debian_fw](https://github.com/citypw/arsenal-4-sec-testing/blob/master/bt5_firewall/debian_fw)
- **harbian-audit Readme**: [https://github.com/hardenedlinux/harbian-audit/blob/master/README.md](https://github.com/hardenedlinux/harbian-audit/blob/master/README.md)
