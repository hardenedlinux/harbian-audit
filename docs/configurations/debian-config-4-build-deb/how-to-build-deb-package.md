# How to build the deb package  

## Pre-install 
```
# apt-get install build-essential dh-make debhelper lintian wget 
```
## Config evc var for dh_make 
```
$ cat >>~/.bashrc <<EOF
DEBEMAIL="samson@hardenedlinux.org"
DEBFULLNAME="Samson W"
export DEBEMAIL DEBFULLNAME
EOF
$ . ~/.bashrc
```
## Download realese  
```
$ wget https://github.com/hardenedlinux/harbian-audit/archive/V0.4.1.tar.gz
$ tar zxvf V0.4.1.tar.gz 
```
## Init and dh_make 
```
~$ rm V0.4.1.tar.gz
~$  tar -czvf harbian-audit-0.4.1.tar.gz --exclude=.gitignore harbian-audit-0.4.1
~$ cd harbian-audit-0.4.1
~/harbian-audit-0.4.1$ dh_make -f ../harbian-audit-0.4.1.tar.gz
```
## Config files of debian dir 
```
~/harbian-audit-0.4.1$ rm -rf debian
~/harbian-audit-0.4.1$ cp -r docs/configurations/debian-config-4-build-deb/debian/ debian
~/harbian-audit-0.4.1$ rm debian/Readme
```

## Build deb package  
```
~/harbian-audit-0.4.1$ dpkg-buildpackage --sign-key=<your-gpg-key-id>
```
If don't sign the source package and the .buildinfo and .changes files
```
~/harbian-audit-0.4.1$ dpkg-buildpackage -us -uc
```

## Sign deb package 
```
~/harbian-audit-0.4.1$ cd ..
~$ sha512sum harbianaudit_0.4.1-1_all.deb  > harbianaudit_0.4.1-1_all.deb.sha512sum
~$ gpg -ab harbianaudit_0.4.1-1_all.deb 
```
