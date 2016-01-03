#!/bin/sh

# This script is used with Laravel Homestead after all other
# provisioning scripts.

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# The text "> /dev/null 2>&1" silences all messages from the command.
# Be warned, this hides errors as well.

# The location of this script on the Homestead VM (copied not synced during provisioning):
# /vagrant/src/stubs/after.sh

# For this script to work, in your project folder, you need a "shared" folder
# with the following files:
# shared/instantclient-basic-linux.x64-12.1.0.2.0.zip
# shared/instantclient-sdk-linux.x64-12.1.0.2.0.zip
# These files can be downloaded from:
# http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html

# Homestead now uses PHP 7.0 as of box version 0.4.0
# Use version Homestead 0.3.3 for PHP 5.6

# Great Vagrant script example
# https://github.com/ornicar/lila/blob/master/bin/provision-vagrant.sh

#0. Update and upgrade apt-get
echo "Updating Apt-Get..."
apt-get update > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1

# 1. Install missing packages via apt-get
apt-get install -y nano curl wget rsync rpm build-essential g++ make
apt-get install -y make vim python-software-properties
apt-get install -y libaio1 php-pear unzip tar software-properties-common

# 1a. PHP version-specific packages
apt-get install -y php5-dev php5-ldap php5-json php5-xsl php5-intl php5-mcrypt
apt-get install -y php5-curl

# 2. Create all needed environment variables for this script to work.
export SHARED_DIR='/home/vagrant/ivrtest/shared'
export ORACLE_HOME='/opt/oracle/instantclient'
export LD_LIBRARY_PATH=$ORACLE_HOME
export TNS_ADMIN='/opt/oracle/tns'
export INSTANT_ZIP_VERSION='linux.x64-12.1.0.2.0' #linux (x86-x64 version)
export INSTANT_WORKING_FOLDER='instantclient_12_1'
export INSTANT_MAJOR_VERSION='12'

# 3. Make sure the instantclient files exist.
if [ -f $SHARED_DIR/instantclient-basic-$INSTANT_ZIP_VERSION.zip ]; then
    echo "Found $SHARED_DIR/instantclient-basic-$INSTANT_ZIP_VERSION.zip file."
else
    echo "!!! Missing $SHARED_DIR/instantclient-basic-$INSTANT_ZIP_VERSION.zip file."
    exit 1;
fi

if [ -f $SHARED_DIR/instantclient-sdk-$INSTANT_ZIP_VERSION.zip ]; then
    echo "Found $SHARED_DIR/instantclient-sdk-$INSTANT_ZIP_VERSION.zip file."
else
    echo "!!! Missing $SHARED_DIR/instantclient-sdk-$INSTANT_ZIP_VERSION.zip file."
    exit 1;
fi

# 4. Unzip the files, copying the "sdk" folder contents into the parent folder.
cd /tmp
cp $SHARED_DIR/instantclient-* .

cd /opt
if [ -d /opt/oracle ]; then
    rm -Rf oracle
fi

mkdir oracle
mkdir /opt/oracle
cd /opt/oracle
echo "*** Unzipping the Oracle drivers ***"
unzip /tmp/instantclient-basic-$INSTANT_ZIP_VERSION.zip
unzip /tmp/instantclient-sdk-$INSTANT_ZIP_VERSION.zip
ln -s /opt/oracle/$INSTANT_WORKING_FOLDER /opt/oracle/instantclient
cp -R /opt/oracle/$INSTANT_WORKING_FOLDER/sdk/* /opt/oracle/$INSTANT_WORKING_FOLDER

cd /opt/oracle/$INSTANT_WORKING_FOLDER
cp sdk/include/* .

#5. Creating symbolic links as needed.
ln -s libclntshcore.so.$INSTANT_MAJOR_VERSION.1 libclntshcore.so
ln -s libclntsh.so.$INSTANT_MAJOR_VERSION.1 libclntsh.so
ln -s libocci.so.$INSTANT_MAJOR_VERSION.1 libocci.so
ln -s libnnz$INSTANT_MAJOR_VERSION.so libnnz.so

echo '/opt/oracle/instantclient/' | tee -a /etc/ld.so.conf.d/oracle_instant_client.conf
ldconfig

echo "*** Setting permissions on Oracle folders ***"
chown -R root:www-data /opt/oracle
chown -R root:root /opt/oracle/instantclient/
chmod -R g+x /opt/oracle/instantclient/

#6. Download and install the Oci8 driver.
cd $ORACLE_HOME
mkdir /opt/oracle/src
cd /opt/oracle/src
# Latest version of oci8 for PHP 5.x is 2.0.10 as of 12/31/2015
# https://pecl.php.net/package/oci8
pecl download oci8-2.0.10
tar -xvf oci8-*
cd oci8-*
echo "*** Running phpize... ***"
phpize
./configure --with-oci8=share,instantclient,/opt/oracle/instantclient
make
make install

echo -e "\r\nextension=oci8.so" >> /etc/php5/fpm/php.ini
echo -e "\r\nextension=oci8.so" >> /etc/php5/cli/php.ini

#7. Install Pear Mail
echo "*** Upgrading & Installing PEAR Mail ***"
pear upgrade --force xml_util
pear upgrade-all
pecl upgrade
pear install -a Console_GetoptPlus
pear install -a mail
pear install -a mail_mime

#8. Restart PHP and Nginx
echo "*** Restarting PHP and Nginx... ***"
service php5-fpm restart
service nginx restart
