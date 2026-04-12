# harbian-audit审计与加固

## 简介 
本项目是面向 Debian GNU/Linux、CentOS 8 和 Ubuntu 发行版的安全审计与加固工具。当前主要测试环境为 Debian GNU/Linux 9/10/11/12/13、CentOS 8 以及 Ubuntu 22，其他版本尚未经过充分测试。本项目主要面向服务器场景，暂未针对桌面环境实现对应检查项。
本项目基于 [OVH-debian-cis](https://github.com/ovh/debian-cis) 框架，并结合 Debian GNU/Linux 9 的一些特性进行了优化。同时参考了安全合规基线 STIG（[STIG Red_Hat_Enterprise_Linux_7_V2R5](redhat-STIG-DOCs/U_Red_Hat_Enterprise_Linux_7_V2R5_STIG.zip) 及 [STIG Ubuntu V1R2](https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_Canonical_Ubuntu_16-04_LTS_V1R2_STIG.zip)）和 CIS（[cisecurity.org](https://www.cisecurity.org/)），补充了安全检查项；另外也结合 HardenedLinux 社区在实际生产环境中的经验，实现了一些额外安全检查项的审计功能。项目不仅支持安全审计，也支持自动修复。

审计功能的使用示例： 
```console
# bash bin/hardening.sh --audit-all
[...]
hardening                 [INFO] Treating /home/test/harbian-audit/bin/hardening/13.15_check_duplicate_gid.sh
13.15_check_duplicate_gid [INFO] Working on 13.15_check_duplicate_gid
13.15_check_duplicate_gid [INFO] Checking Configuration
13.15_check_duplicate_gid [INFO] Performing audit
13.15_check_duplicate_gid [ OK ] No duplicate GIDs
13.15_check_duplicate_gid [ OK ] Check Passed

[...]
################### SUMMARY ###################
      Total Available Checks : 271
         Total Checks Run : 271
         Total Passed Checks : [ 226/271 ]
         Total Failed Checks : [  44/271 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 83.39 %
```
## 快速上手使用介绍

### 下载及初始化 
```console
$ git clone https://github.com/hardenedlinux/harbian-audit.git && cd harbian-audit
# cp etc/default.cfg /etc/default/cis-hardening
# sed -i "s#CIS_ROOT_DIR=.*#CIS_ROOT_DIR='$(pwd)'#" /etc/default/cis-hardening
# bin/hardening.sh --init
```
### 对所有安全检查项执行审计 
```
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
      Total Available Checks : 270
         Total Checks Run : 270
         Total Passed Checks : [ 226/270 ]
         Total Failed Checks : [  44/270 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 83.70 %
```
### 设置加固级别并执行自动修复  
```
# bin/hardening.sh --set-hardening-level 5  
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
```

## 用法简介 

### 需要预装的软件  
如果 Debian GNU/Linux 系统采用最小化安装方式，在使用本项目之前需要先安装以下软件：
```
# apt-get install -y bc net-tools pciutils 
```
如果系统是 RedHat/CentOS，在使用本项目前，需要安装以下软件包：
```
# yum install -y bc net-tools pciutils NetworkManager epel-release 
```

### 需要预先进行的配置 
在使用本项目前，必须为所有会用到的用户设置密码。否则在执行自动化加固后，相关用户可能无法登录系统。例如（用户：root 和 test）：
```
 
# passwd 
# passwd test 
```

### 项目本身的配置 
审计与修复脚本位于 `bin/hardening` 目录中，每个脚本文件都对应一个位于 `/etc/conf.d/[script_name].cfg` 的配置文件。每个脚本都可以单独设置为 `enabled` 或 `disabled`，例如：
``disable_system_accounts``:

```
# Configuration for script of same name
status=disabled
# Put here your exceptions concerning admin accounts shells separated by spaces
EXCEPTIONS=""
```

`status` 参数有 3 个可选值： 
- `disabled` (do nothing): 执行时不运行该脚本 
- `audit` (RO): 仅执行审计检查 
- `enabled` (RW): 执行审计检查，并尝试自动修复

如需为每个脚本生成对应配置文件，并设置审计级别，可使用以下命令： 
1. 首次执行本项目时，可通过 `audit-all` 参数生成 `etc/conf.d/[script_name].cfg`：
```
# bash bin/hardening.sh --audit-all
```
2. 使用 `set-hardening-level` 参数，将对应级别的 `[script_name].cfg` 配置文件设为 `enabled` 状态：  
```
# bash bin/hardening.sh --set-hardening-level <level>
```
通用配置文件为 `etc/hardening.cfg`。该文件可用于控制日志级别和备份目录；备份目录用于在自动修复时保存原始配置文件。

### 审计及修复操作（执行加固后，必须完成“修复后必须进行的操作”章节中的内容）
执行审计或修复时，运行 `bin/hardening.sh`。该命令主要有两种执行模式：
- `--audit`: 对所有配置为 `enabled` 的脚本执行审计
- `--apply`: 对所有配置为 `enabled` 的脚本执行审计并尝试修复

另外，`--audit-all` 参数会强制执行所有审计脚本，包括配置为 `disabled` 的脚本；该操作不会修改系统（即不会执行修复）。
`--audit-all-enable-passed` 参数可用作快速初始化配置的快捷方式：它会以审计模式执行所有脚本，如果某个脚本审计通过，则自动将其对应配置文件设为 `enabled`。如果你已经自定义了配置文件，不建议使用此参数。

使用以下命令对系统进行加固/修复：
```
# bash bin/hardening.sh --apply 
```

## 修复后必须进行的操作（非常重要）
当 `set-hardening-level` 设为 5（最高等级）并执行 `--apply` 后，还需要完成以下操作：
1. 当 9.4 项（Restrict Access to the su Command）被修复后，如果仍然存在必须使用 `su` 的场景，例如通过 SSH 以普通用户登录后再切换到其他用户，可以使用以下命令临时解除限制：
```
# sed -i '/^[^#].*pam_wheel.so.*/s/^/# &/' /etc/pam.d/su 
```
该命令会临时注释掉包含 `pam_wheel.so` 的行。使用完 `su` 后，请恢复该行的注释状态。

2. 当 7.4.4 项（`7.4.4_hosts_deny.sh`）被修复后，系统将拒绝所有连接（例如 SSH 连接），因此需要在 `/etc/hosts.allow` 中配置允许访问此主机的来源，例如：
```
# echo "ALL: 192.168.1. 192.168.5." >> /etc/hosts.allow
```
该示例表示仅允许 `192.168.1.[1-255]` 和 `192.168.5.[1-255]` 两个网段访问此系统。请根据实际场景调整配置。 

3. 为普通用户授予 sudo 权限，例如（用户名为 `test`）：
```
# sed -i "/^root/a\test    ALL=(ALL:ALL) ALL" /etc/sudoers 
```

4. 设置基础 iptables 防火墙规则  
请根据实际场景配置防火墙规则，可参考 HardenedLinux 社区整理的 Debian GNU/Linux 基础防火墙规则：
[etc.iptables.rules.v4.sh](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.iptables.rules.v4.sh)

基于iptables的部署:
```
$ INTERFACENAME="your network interfacename(Example eth0)"
# bash docs/configurations/etc.iptables.rules.v4.sh $INTERFACENAME

# iptables-save > /etc/iptables/rules.v4 
# ip6tables-save > /etc/iptables/rules.v6 
```
基于 nft 的部署：
按以下命令修改 `nftables.conf`（将对外网卡名称替换为实际值，例如 `eth0`）：
```
$ sed -i 's/^define int_if = ens33/define int_if = eth0/g' etc.nftables.conf 
# nft -f ./etc.nftables.conf 
```
5. 当所有安全基线项都修复完成后，可使用 `--final` 完成以下收尾工作：
   1. 使用 `passwd` 命令重新设置普通用户及 root 用户的密码，以满足 `pam_cracklib` 模块对密码强度的要求。
   2. 重新初始化 aide 工具的数据库。
```
# bin/hardening.sh --final
```

## 特别注意 

### 必须在第一次应用修复后处理的项  
8.1.35：此项一旦设置完成，将无法继续添加新的审计规则。

### 必须在所有项都修复完成后再处理的项  
8.4.1、8.4.2：这两项都与 aide 文件完整性检测有关，最好在所有修复完成后再执行，以便基于修复完成后的系统文件初始化完整性数据库。

### 一些检查项需要多次修复，且操作系统可能需要多次重启 
#### 需要执行两次修复的项  
8.1.1.2  
8.1.1.3  
8.1.12  
4.5  

## 扩展（如何添加检查项）

**获取源码**

```console
$ git clone https://github.com/hardenedlinux/harbian-audit.git
```

**添加一个自定义脚本**

```console
$ cp src/skel bin/hardening/99.99_custom_script.sh
$ chmod +x bin/hardening/99.99_custom_script.sh
$ cp src/skel.cfg etc/conf.d/99.99_custom_script.cfg
```
将对应配置文件设为 `enabled`，然后执行审计及加固测试：
```console
$ sed -i "s/status=.+/status=enabled/" etc/conf.d/99.99_custom_script.cfg
$ bash bin/hardening.sh --audit --only 99.99
$ bash bin/hardening.sh --apply --only 99.99
```

## 项目相关文档列表  

### Harbian-audit benchmark for Debian GNU/Linux 9 
This document is a description of the additions to the sections not included in the [CIS reference documentation](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100). Includes STIG reference documentation and additional checks recommended by the HardenedLinux community. 

[CIS Debian GNU/Linux 8 Benchmark v1.0.0](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100)  
[CIS Debian GNU/Linux 9 Benchmark v1.0.0](https://benchmarks.cisecurity.org/downloads/show-single/index.cfm?file=debian8.100)  
[harbian audit Debian Linux 9 Benchmark](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/harbian_audit_Debian_9_Benchmark_v0.1.mkd)  

### 手动修复操作文档列表  
[How to config grub2 password protection](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_config_grub2_password_protection.mkd)  
[How to persistent iptables rules with debian 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_persistent_iptables_rules_with_debian_9.mkd)  
[How to deploy audisp-remote for auditd log](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_deploy_audisp_remote_for_audit_log.mkd)
[How to migrating from iptables to nftables in debian10](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_migrating_from_iptables_to_nftables_in_debian10.md)  
[How to persistent nft rules with debian 10](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_persistent_nft_rules_with_debian_10.mkd)
[How to fix SELinux access denied](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_fix_SELinux_access_denied.mkd)

### 应用场景示例文档列表   
[Nodejs + redis + mysql demo](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/nodejs-redis-mysql-usecase/README.md)  
[deploy-hyperledger-cello-on-debian-9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/hyperledger-cello-usecase/README.mkd)  
[nginx-mutual-ssl-proxy-http](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/tls-transmission-usecase/nginx-mutual-ssl-proxy-http-service/Readme.mkd)  
[nginx-mutual-ssl-proxy-tcp-udp](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/tls-transmission-usecase/using-Nginx-as-SSL-tunnel-4TCP-UDP-service/Readme.mkd)   

## harbian-audit 合规镜像  

### AMI(Amazon Machine Image) Public

#### 相关文档  
[how to creating and making an AMI public](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/AMI/how_to_creating_and_making_an_AMI_public.mkd)  
[how to use harbian-audit complianced for GNU/Linux Debian 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/AMI/how_to_use_harbian_audit_complianced_Debian_9.mkd)  

### QEMU Image    

#### 相关文档   
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


## 参考列表  

- **Center for Internet Security**: https://www.cisecurity.org/
- **STIG V1R4**: https://iasecontent.disa.mil/stigs/zip/U_Red_Hat_Enterprise_Linux_7_V1R4_STIG.zip 
- **Firewall Rules**: https://github.com/citypw/arsenal-4-sec-testing/blob/master/bt5_firewall/debian_fw

