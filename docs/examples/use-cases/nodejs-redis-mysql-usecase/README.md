# Nodejs + redis + mysql demo 

## environment
* OS:      Debian 9.6 
* Nodejs:  10.13.0
* MySQL:   10.1.26-MariaDB-0+deb9u1
* Redis:   5.0.1

## Install packages

### Install mysql

```
$ sudo apt install mysql-server
```
#### Configurate database

Create helloworld database

```
$ sudo mysql -uroot 

MariaDB [(none)]> CREATE DATABASE helloworld;
```
Grant proper access to the helloworld database:

```
MariaDB [(none)]> GRANT ALL PRIVILEGES ON helloworld.* TO 'helloworld'@'localhost' \
  IDENTIFIED BY 'HELLOWORLD_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON helloworld.* TO 'helloworld'@'%' \
  IDENTIFIED BY 'HELLOWORLD_DBPASS';
MariaDB [(none)]> quit
```

Replace HEllOWORLD_DBPASS with a suitable password.

### Install Redis

edit `/etc/apt/source.list` and add  `stretch-backports` source:

```
deb http://mirrors.163.com/debian/ stretch-backports main
deb-src http://mirrors.163.com/debian/ stretch-backports main
```
and update

```
$ sudo apt update
```

#### install the package
```
$ sudo apt -t stretch-backports install -y redis-server
```

#### Configurate Redis

modify `/etc/redis/redis.conf`, changce supervised no to 

```
supervised systemd
```

Configuring a Redis Password
modify /etc/redis/redis.conf you can find the 
```
# requirepass foobared
```

uncommnet it and change foobared to a suitable password

for example, you can gener:

```
openssl rand 60 | openssl base64 -A

jkO663LT4SLU522cIBaMrWshaEEP+67oRGIdDV3AEpIaS7IQ9yYWP78nmruBFM2cPdxSudvrrmlZeKil
```

systemctl restart redis

### Install Nodejs

```
$ sudo apt install curl -y
```
#as root
```
# curl -sL https://deb.nodesource.com/setup_10.x | bash -
# apt-get install -y nodejs
```

### Install pax-bites

```
cat <<EOF > debian_auto_deploy.sh
#!/bin/bash

WORKDIR=/tmp/debian-grsec-configs
mkdir -p $WORKDIR
cd $WORKDIR

echo "###########################################################################"
echo -e "[+] \e[93mInstalling paxctl-ng/elfix...\e[0m"
echo "----------------------------------------------"
apt-get install -y vim libc6-dev libelf-dev libattr1-dev build-essential git
wget https://dev.gentoo.org/%7Eblueness/elfix/elfix-0.9.2.tar.gz && tar zxvf elfix-0.9.2.tar.gz
cd elfix-0.9.2

./configure --enable-ptpax --enable-xtpax --disable-tests
make && make install
cd $WORKDIR

echo "###########################################################################"
echo -e "[+] \e[93mDeploying configs....\e[0m"
echo "----------------------------------------------"

echo 'DPkg::Post-Invoke {"/bin/bash /usr/sbin/pax-bites.sh -e /etc/pax_flags_debian.config"; };' >77pax-bites

cp 77pax-bites /etc/apt/apt.conf.d/
wget https://github.com/hardenedlinux/hardenedlinux_profiles/raw/master/debian/pax_flags_debian.config
cp pax_flags_debian.config /etc/

echo "###########################################################################"
echo -e "[+] \e[93mDeploying pax-bites...\e[0m"
echo "----------------------------------------------"
git clone https://github.com/hardenedlinux/pax-bites.git
cp pax-bites/pax-bites.sh  /usr/sbin/
pax-bites.sh -e /etc/pax_flags_debian.config
EOF
```
run command:

```
bash debian_auto_deploy.sh
```

after install paxctl and pax-bites

we should modify `/etc/pax_flags_debian.config`

add following content:

```
# Nodejs
/usr/bin/node;m
```
`-m` means `disable  MPROTECT`

for more details you can check it from `paxctl-ng`

perform change

```
pax-bites.sh -e /etc/pax_flags_debian.config
```


## Add new user for helloworld service
``` 
# adduser helloworld 
# sed -i '/root/ahelloworld    ALL=(ALL:ALL) ALL' /etc/sudoers
``` 

## Usage

Using helloworld to install the dependencies.

unzip the helloworld.zip

```
//Installation all dependencies:
//As helloworld
$ unzip helloworld.zip
$ cd helloworld
$ npm install
```

## modify the config file locate in `config/config.js`

you can setup the mysql and redis

```
BASE_DIR = __dirname;

module.exports = {
	port: 3000,
	//mysql
	mysql: {
		host: 'localhost',
		user: 'helloworld',
		password: 'HELLOWORLD_DBPASS',
		connectionLimit: 10,
		charset: 'utf8mb4',
	},
	database: 'helloworld',
	//redis
	redis: {
		tokenName: 'helloworld',
		host: '127.0.0.1',
		port: 6379,
		password: 'jkO663LT4SLU522cIBaMrWshaEEP+67oRGIdDV3AEpIaS7IQ9yYWP78nmruBFM2cPdxSudvrrmlZeKil',
	},
}
```

//Installation PM2: 
```
$ sudo npm install pm2 -g
$ sudo chmod -R 755 /usr/lib/node_modules/pm2  
```

```
$ su helloworld
$ export NODE_ENV=production && pm2 start ./app.js --name helloworld
$ pm2 startup systemd

[PM2] Init System found: systemd
[PM2] To setup the Startup Script, copy/paste the following command:
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u helloworld --hp /home/helloworld
```
change to root user and execute

```
$ env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u helloworld --hp /home/helloworld
```

and switch back to `helloworld` user

```
$ pm2 save
```
now start the service

```
# systemctl start pm2-helloworld
```

## Set iptables rules
```
$ sudo iptables -I INPUT -p tcp -m tcp --dport 3000 -j ACCEPT
```

## Test 
Open up http://{your server ip}:3000,then you can see the helloworld page.


Reference:  
https://nodejs.org/en/   
https://www.mysql.com/   
http://pm2.keymetrics.io/   
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-debian-9   
