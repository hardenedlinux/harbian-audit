# How to use QEMU image of harbian-audit complicanced Debian GNU/Linux 9 

## Overview 
Image name: harbian-audit_Debian_9.qcow2  
Disk size: 50G 
File system: 
```
harbian-audit@harbian:~$ df -h 
Filesystem                    Size  Used Avail Use% Mounted on
udev                          2.0G     0  2.0G   0% /dev
tmpfs                         396M  5.5M  391M   2% /run
/dev/mapper/harbian--vg-root   15G  1.3G   12G  10% /
tmpfs                         2.0G  8.0K  2.0G   1% /dev/shm
tmpfs                         5.0M     0  5.0M   0% /run/lock
tmpfs                         2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/vda1                     236M   37M  187M  17% /boot
tmpfs                         2.0G     0  2.0G   0% /tmp
/dev/mapper/harbian--vg-home   27G   45M   25G   1% /home
tmpfs                         396M     0  396M   0% /run/user/1000
```
grub password protection:   
username: harbiansuper  
password: harbian_AUDIT,12@)  

Users info:   
user: root  
passwd: 1qaz@WSX3edc$RFV5tgb     

user: harbian-audit   
passwd: 2wsx#EDC4rfv%TGB6yhn   

## Get QEMU image   

### Download address  
[https://drive.google.com/file/d/1osqL0REFisSedOhL04dupC1aDM6jVpdm/view?usp=sharing](https://drive.google.com/file/d/1osqL0REFisSedOhL04dupC1aDM6jVpdm/view?usp=sharing)   

![1](./picture/download_01.png)  
![2](./picture/download_02.png)  
![3](./picture/download_03.png)  

### Verify  
```
$ wget https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/QEMU/signature/harbian-audit_Debian_9.qcow2.sig 
$ wget https://github.com/hardenedlinux/harbian-audit/blob/master/docs/complianced_image/QEMU/signature/harbian-audit_Debian_9.qcow2.tar.gz.sig 
$ gpg --verify harbian-audit_Debian_9.qcow2.tar.gz.sig harbian-audit_Debian_9.qcow2.tar.gz
$ tar -xzvf harbian-audit_Debian_9.qcow2.tar.gz   
$ gpg --verify harbian-audit_Debian_9.qcow2.sig harbian-audit_Debian_9.qcow2  
```

## Use the QEMU image to create virtual machine  

![1](./picture/import-image_01.png)  
![2](./picture/import-image_02.png)  
![3](./picture/import-image_03.png)  
![4](./picture/import-image_04.png)  


