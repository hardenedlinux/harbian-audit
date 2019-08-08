# harbian-audit Hardening

## Introduction 

Hardened Debian GNU/Linux distro auditing.  

The main test environment is in debian 9, and other versions are not fully tested. There are no implementations of desktop and SELinux related items in this release.

The code framework is based on the [OVH-debian-cis](https://github.com/ovh/debian-cis) project, Modified some of the original implementations according to the features of Debian 9, added and implemented check items for [STIG Redhat V1R4](https://iasecontent.disa.mil/stigs/zip/U_Red_Hat_Enterprise_Linux_7_V1R4_STIG.zip) [STIG Ubuntu V1R2](https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_Canonical_Ubuntu_16-04_LTS_V1R2_STIG.zip) and [cisecurity.org](https://www.cisecurity.org/) recommendations, and also added and implemented some check items by the HardenedLinux community. The audit and apply functions of the infrastructure are implemented, and the automatic fix function is implemented for the items that can be automatically fixed. 


```console
$ sudo bash bin/hardening.sh --audit-all
[...]
hardening                 [INFO] Treating /home/test/harbian-audit/bin/hardening/13.15_check_duplicate_gid.sh
13.15_check_duplicate_gid [INFO] Working on 13.15_check_duplicate_gid
13.15_check_duplicate_gid [INFO] Checking Configuration
13.15_check_duplicate_gid [INFO] Performing audit
13.15_check_duplicate_gid [ OK ] No duplicate GIDs
13.15_check_duplicate_gid [ OK ] Check Passed

[...]
################### SUMMARY ###################
      Total Available Checks : 278
         Total Runned Checks : 278
         Total Passed Checks : [ 239/278 ]
         Total Failed Checks : [  39/278 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 85.97 %
```
## Quickstart

```console
$ git clone https://github.com/hardenedlinux/harbian-audit.git && cd harbian-audit
$ sudo cp debian/default /etc/default/cis-hardening
$ sudo sed -i "s#CIS_ROOT_DIR=.*#CIS_ROOT_DIR='$(pwd)'#" /etc/default/cis-hardening
$ sudo bin/hardening.sh --init
$ sudo bin/hardening.sh --audit-all
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
      Total Available Checks : 278
         Total Runned Checks : 278
         Total Passed Checks : [ 239/278 ]
         Total Failed Checks : [  39/278 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 85.97 %
$ sudo bin/hardening.sh --set-hardening-level 5
$ sudo bin/hardening.sh --apply 
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
```

## Usage

### Pre-Install 

If use Network install from a minimal CD to installed Debian GNU/Linux, need install packages before use the hardening tool. 
```
sudo apt-get install -y bc net-tools pciutils network-manager 
```

Redhat/CentOS need install packages before use the hardening tool:
```
sudo yum install -y bc net-tools pciutils NetworkManager 
```

### Pre-Set 
You must set a password for all users before hardening. Otherwise, you will not be able to log in after the hardening is completed. Example(OS user: root and test): 
```
$ sudo -s 
# passwd 
# passwd test 
```

### Configuration

Hardening scripts are in ``bin/hardening``. Each script has a corresponding
configuration file in ``etc/conf.d/[script_name].cfg``.

Each hardening script can be individually enabled from its configuration file.
For example, this is the default configuration file for ``disable_system_accounts``:

```
# Configuration for script of same name
status=disabled
# Put here your exceptions concerning admin accounts shells separated by spaces
EXCEPTIONS=""
```

``status`` parameter may take 3 values:
- ``disabled`` (do nothing): The script will not run.
- ``audit`` (RO): The script will check if any change *should* be applied.
- ``enabled`` (RW): The script will check if any change should be done and automatically apply what it can.

You can also set the configuration item to enable by modifying the level, following command: 
1) Generate etc/conf.d/[script_name].cfg by audit-all when first use 
```
# bash bin/hardening.sh --audit-all
```
2) Enable [script_name].cfg by set-hardening-level 
Use the command to set the hardening level to make the corresponding level audit entry take effect. 
```
# bash bin/hardening.sh --set-hardening-level <level>
```
Global configuration is in ``etc/hardening.cfg``. This file controls the log level
as well as the backup directory. Whenever a script is instructed to edit a file, it
will create a timestamped backup in this directory.

### Run aka "Harden your distro (After the hardened, you must perform the "After remediation" section)

To run the checks and apply the fixes, run ``bin/hardening.sh``.

This command has 2 main operation modes:    
- ``--audit``: Audit your system with all enabled and audit mode scripts    
- ``--apply``: Audit your system with all enabled and audit mode scripts and apply changes for enabled scripts    

Additionally, ``--audit-all`` can be used to force running all auditing scripts, including disabled ones. this will *not* change the system.  

``--audit-all-enable-passed`` can be used as a quick way to kickstart your configuration. It will run all scripts in audit mode. If a script passes, it will automatically be enabled for future runs. Do NOT use this option if you have already started to customize your configuration.

Use the command to harden your OS:
```
# bash bin/hardening.sh --apply 
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

### Iptabels format rules:
[etc.iptables.rules.v4.sh](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.iptables.rules.v4.sh)
to do the following:
```
$ INTERFACENAME="your network interfacename(Example eth0)"
$ sed -i "s/PUB_IFS=.*/PUB_IFS=\"$INTERFACENAME\"/g" docs/configurations/etc.iptables.rules.v4.sh 
$ sudo bash docs/configurations/etc.iptables.rules.v4.sh 
$ sudo -s
# iptables-save > /etc/iptables/rules.v4 
# ip6tables-save > /etc/iptables/rules.v6 
```

### nft format rules:
[nftables.conf](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.nftables.conf)
to do the following(your network interfacename(Example eth0)):
```
$ sed -i 's/^define int_if = ens33/define int_if = eth0/g' etc.nftables.conf 
$ sudo nft -f ./etc.nftables.conf 
```

5) Use the passwd command to change the passwords of all users, and change the password to a secure and reliable password entry with the same password complexity set by the pam_cracklib module.

## Special Note 
Some check items check a variety of situations and are interdependent, they must be applied (fix) multiple times, and the OS must be a reboot after each applies (fix). 

Items that need to be fix twice:  
8.1.1.2  
8.1.1.3  
8.1.12  

Items that need to be fix three times:   
4.5  

## Hacking

**Getting the source**

```console
$ git clone https://github.com/hardenedlinux/harbian-audit.git
```

**Adding a custom hardening script**

```console
$ cp src/skel bin/hardening/99.99_custom_script.sh
$ chmod +x bin/hardening/99.99_custom_script.sh
$ cp src/skel.cfg etc/conf.d/99.99_custom_script.cfg
```

Code your check explaining what it does then if you want to test

```console
$ sed -i "s/status=.+/status=enabled/" etc/conf.d/99.99_custom_script.cfg
$ bash bin/hardening.sh --audit --only 99.99
$ bash bin/hardening.sh --apply --only 99.99
```

## Document 

### Harbian-audit benchmark for Debian GNU/Linux 9 
This document is a description of the additions to the sections not included in the [CIS reference documentation](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100). Includes STIG reference documentation and additional checks recommended by the HardenedLinux community. 

[CIS Debian GNU/Linux 8 Benchmark v1.0.0](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100)  
[CIS Debian GNU/Linux 9 Benchmark v1.0.0](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100)  
[harbian audit Debian Linux 9 Benchmark](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/harbian_audit_Debian_9_Benchmark_v0.1.mkd)  

### Manual Operation docs 
[How to config grub2 password protection](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_config_grub2_password_protection.mkd)  
[How to persistent iptables rules with debian 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_persistent_iptables_rules_with_debian_9.mkd)  
[How to deploy audisp-remote for auditd log](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_deploy_audisp_remote_for_audit_log.mkd)  
[How to migrating from iptables to nftables in debian10](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_migrating_from_iptables_to_nftables_in_debian10.md)  
[How to persistent nft rules with debian 10](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_persistent_nft_rules_with_debian_10.mkd)  

### Use case docs  
[Nodejs + redis + mysql demo](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/nodejs-redis-mysql-usecase/README.md)  
[deploy-hyperledger-cello-on-debian-9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/hyperledger-cello-usecase/README.mkd)  
[nginx-mutual-ssl-proxy-http](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/tls-transmission-usecase/nginx-mutual-ssl-proxy-http-service/Readme.mkd)  
[nginx-mutual-ssl-proxy-tcp-udp](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/tls-transmission-usecase/using-Nginx-as-SSL-tunnel-4TCP-UDP-service/Readme.mkd)   

## harbian-audit complianced image 

### AMI(Amazon Machine Image) Public
The HardenedLinux community has created public AMI images for three different regions.

Destination region: US East(Ohio)   
AMI ID: ami-0459b7f679f8941a4   
AMI Name: harbian-audit complianced for Debian GNU/Linux 9   

Destination region: EU(Frankfurt)  
AMI ID: ami-022f30970530a0c5b   
AMI Name: harbian-audit complianced for Debian GNU/Linux 9   

Destination region: Asia Pacific(Tokyo)  
AMI ID: ami-003de0c48c2711265   
AMI Name: harbian-audit complianced for Debian GNU/Linux 9   

#### Docs  
[how to creating and making an AMI public](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/AMI/how_to_creating_and_making_an_AMI_public.mkd)  
[how to use harbian-audit complianced for GNU/Linux Debian 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/AMI/how_to_use_harbian_audit_complianced_Debian_9.mkd)  

### QEMU Image    

#### Docs   
[How to creating and making a QEMU image of harbian-audit complianced Debian GNU/Linux 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/QEMU/how_to_creating_and_making_a_QEMU_img.mkd)  
[How to use QEMU image of harbian-audit complicanced Debian GNU/Linux 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/QEMU/how_to_use_QEMU_image_of_harbian_audit_complianced_Debian_9.mkd)   


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

- **Center for Internet Security**: https://www.cisecurity.org/
- **STIG V1R4**: https://iasecontent.disa.mil/stigs/zip/U_Red_Hat_Enterprise_Linux_7_V1R4_STIG.zip 
- **Firewall Rules**: https://github.com/citypw/arsenal-4-sec-testing/blob/master/bt5_firewall/debian_fw



