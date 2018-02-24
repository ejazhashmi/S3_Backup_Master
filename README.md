# How to install S3 offsite backups on Servers

# Step 1 install required packages
apt-get install --assume-yes --force-yes python-setuptools makepasswd

# Step 2 downloads and installs S3cmd 

cd /root/
wget -q https://github.com/s3tools/s3cmd/archive/master.zip
unzip -qq master.zip
cd /root/s3cmd-master
python setup.py install
cd /root/scripts/
rm -rf /root/s3cmd-master && rm -rf /root/master.zip

# Step 3 Configure S3cmd

s3cmd --configure

Access Key:

Secret Key :

Default Region [US]: Just Enter to select default region.

Encryption password: Just Enter

Path to GPG program [/usr/bin/gpg]:Just Enter to select default

Use HTTPS protocol [Yes]:Just Enter to select default

HTTP Proxy server name:Just Enter to select default

test access with supplied credentials? [Y/n] Y

Success. Your access key and secret key worked fine :-)

# ep 4 save configuration
Save settings? [y/N] Y
Configuration saved to '/root/.s3cfg'

# ep 5 download and edit the script

wget https://raw.githubusercontent.com/ejazhashmi/S3_Backup_Master/master/s3_upload.sh

After download the script run the following commands.

chmod +x s3_upload.sh

# Step 6
Open the script edit the following

vi /root/scripts/s3_upload.sh


dirstobackup=(
'/var/www/webroot/'
'Any other directory includes in quotes with full path'
)

dbstobackup=(
'mysql'
'To add more include name in quotes'
)

# Step 7 create tmp backup directory
Create the following directory before running the script

mkdir /home/backups && mkdir -p /home/status/

# Step 8 setup the cron to run daily.

Enable Cron to run daily on off peak hours

# #S3 Backup
0 3 * * *       /root/scripts/s3_upload.sh >/dev/null 2>&1


## In order to list down backups of S3 
s3cmd ls s3://yourbucket/*
                       


