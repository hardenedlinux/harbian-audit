# harbian-audit审计与加固

## 简介 
此项目是一个Debian GNU/Linux加固发行版本审计工具。主要的测试环境是基于Debian GNU/Linux 9，其它版本未充分测试。此项目主要是针对的Debian GNU/Linux服务器版本，对桌面版本及SELinux相关的项没有实现。
此项目的框架基于[OVH-debian-cis](https://github.com/ovh/debian-cis)，根据Debian GNU/Linux 9的一些特性进行了优化，并根据安全部署合规STIG（[STIG Redhat V1R4](https://iasecontent.disa.mil/stigs/zip/U_Red_Hat_Enterprise_Linux_7_V1R4_STIG.zip)及[STIG Ubuntu V1R2](https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_Canonical_Ubuntu_16-04_LTS_V1R2_STIG.zip)）及CIS（[cisecurity.org](https://www.cisecurity.org/)）进行了安全检查项的添加，同时也根据HardenedLinux社区就具体生产环境添加了一些安全检查项的审计功能的实现。此项目不仅具有安全项的审计功能，同时也有自动修改的功能。

审计功能的使用示例： 
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
## 快速上手使用介绍

### 下载及初始化 
```console
$ git clone https://github.com/hardenedlinux/harbian-audit.git && cd harbian-audit
$ sudo cp debian/default /etc/default/cis-hardening
$ sudo sed -i "s#CIS_ROOT_DIR=.*#CIS_ROOT_DIR='$(pwd)'#" /etc/default/cis-hardening
$ sudo bin/hardening.sh --init
```
### 对所有的安全检查项进行审计 
```
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
```
### 设置加固级别并进行自动修复  
```
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

## 用法简介 

### 需要预装的软件  
如果是使用的最小安装方式安装的Debian GNU/Linux系统，在使用此项目之前，需要安装如下的软件：
```
sudo apt-get install -y bc net-tools pciutils 
```
如果系统是Redhat/CentOS，在使用此项目前，需要安装如下的软件包：
```
sudo yum install -y bc net-tools pciutils NetworkManager 
```

### 需要预先进行的配置 
在使用此项目前，必须给所有要用到的用户设置了密码。如果没有设置密码的话，将在进行自动化加固后不能够登录到系统。例如(用户：root和test）:
```
$ sudo -s 
# passwd 
# passwd test 
```

### 项目本身的配置 
审计及修复的脚本代码位于bin/hardening目录中，每个脚本文件对应位于/etc/conf.d/[script_name].cfg的一个配置文件。每个脚本都能够单独设置为enabled或disabled，例如：
``disable_system_accounts``:

```
# Configuration for script of same name
status=disabled
# Put here your exceptions concerning admin accounts shells separated by spaces
EXCEPTIONS=""
```

``status``参数可能的3个值： 
- ``disabled`` (do nothing): 此脚本在执行时不会被运行 
- ``audit`` (RO): 此脚本只会进行审计的检测 
- ``enabled`` (RW): 此脚本不仅进行审计的检测，也能进行自动修改。

要生成每个脚本对应的配置文件并设置审计的级别，使用如下命令： 
1) 当第一次执行本项目时，通过参数audit-all来生成etc/conf.d/[script_name].cfg 
```
# bash bin/hardening.sh --audit-all
```
2) 使用参数set-hardening-level来设置对应级别的脚本的[script_name].cfg配置文件为enabled状态  
```
# bash bin/hardening.sh --set-hardening-level <level>
```
通用配置文件为``etc/hardening.cfg``，这个文件可以对日志文件的级别、备份目录进行控制，备份目录是当自动修复时对原配置文件进行备份的目录。

### 审计及修复的操作 (进行加固后，必须进行“修复后”章节中的操作)
要进行审计及修复，运行``bin/hardening.sh``，此命令有两个主要的执行模式：
- ``--audit``: 对所有配置为enabled对应的脚本进行审计；
- ``--apply``: 对所有配置为enabled对应的脚本进行审计及修复；
另外, ``--audit-all`` 参数能够强制执行所有审计脚本，包括配置为disabled的脚本，此操作不会对系统有任何的影响(不会修复)；
``--audit-all-enable-passed``参数可以用作快速启动配置的快捷方式，将在审计模式执行所有的脚本。如果脚本对应的审计通过，此脚本对应的配置文件将自动配置为enabled。如果你已经自定义了你的配置文件，别使用此参数进行执行。

使用如下命令进行加固/修复系统:
```
# bash bin/hardening.sh --apply 
```

## 修复后必须进行的操作 (非常重要)
当set-hardening-level配置为5（最高等级）且使用--apply运行了后，需要进行如下的操作：
1) 当9.5项被修复后(Restrict Access to the su Command), 如果必须使用su的场景，例如如果使用ssh远程登录，当以普通用户登录后需要使用su命令时，可以使用如下命令进行解除限制：
```
# sed -i '/^[^#].*pam_wheel.so.*/s/^/# &/' /etc/pam.d/su 
```
暂时注释掉包含pam_wheel.so的行，当使用完su命令后，请去掉此行的注释。

2) 当7.4.4项被修复后（7.4.4_hosts_deny.sh）, 系统将拒绝所有的连接（例如ssh连接），所以需要设置/etc/hosts.allow文件中允许访问此主机的列表，例如：
```
# echo "ALL: 192.168.1. 192.168.5." >> /etc/hosts.allow
```
此示例配置表示仅允许192.168.1.[1-255] 192.168.5.[1-255]两个网段能够访问此系统。 具体配置请根据实际场景进行配置。 

3) 为普通用户设置能力，例如(用户名为test):
```
# sed -i "/^root/a\test    ALL=(ALL:ALL) ALL" /etc/sudoers 
```

4) 设置基本的iptables防火墙规则 
根据实现场景进行防火墙规则的配置，可参考HardenedLinux社区归纳的基于Debian GNU/Linux的防火墙规则的基本规则：
[etc.iptables.rules.v4.sh](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.iptables.rules.v4.sh)
执行如下的命令进行部署:
```
$ INTERFACENAME="your network interfacename(Example eth0)"
$ sed -i "s/PUB_IFS=.*/PUB_IFS=\"$INTERFACENAME\"/g" docs/configurations/etc.iptables.rules.v4.sh 
$ sudo bash docs/configurations/etc.iptables.rules.v4.sh 
$ sudo -s
# iptables-save > /etc/iptables/rules.v4 
# ip6tables-save > /etc/iptables/rules.v6 
```
5) 使用passwd命令改变所有用户的密码，以满足pam_cracklib模块配置的密码复杂度及健壮性。

## 特别注意 
一些检查项需要依赖多次修复，且操作系统需要多次重启。需要进行两次修复的项有： 
8.1.1.2  
8.1.1.3  
8.1.12  

需要修复3次的项： 
4.5  

## 玩（如何添加检查项）

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
将对应的配置文件配置为enabled，并进行审计及加固的测试：
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

### 手动修复的操作文档列表  
[How to config grub2 password protection](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_config_grub2_password_protection.mkd)  
[How to persistent iptables rules with debian 9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_persistent_iptables_rules_with_debian_9.mkd)  
[How to deploy audisp-remote for auditd log](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/manual-operation-docs/how_to_deploy_audisp_remote_for_audit_log.mkd)

### 应用场景示例文档列表   
[Nodejs + redis + mysql demo](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/nodejs-redis-mysql-usecase/README.md)  
[deploy-hyperledger-cello-on-debian-9](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/hyperledger-cello-usecase/README.mkd)  
[nginx-mutual-ssl-proxy-http](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/tls-transmission-usecase/nginx-mutual-ssl-proxy-http-service/Readme.mkd)  
[nginx-mutual-ssl-proxy-tcp-udp](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/use-cases/tls-transmission-usecase/using-Nginx-as-SSL-tunnel-4TCP-UDP-service/Readme.mkd)   

## harbian-audit合规制定的镜像  

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



