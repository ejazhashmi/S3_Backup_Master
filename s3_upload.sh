#!/bin/bash
#
## Email Variables
EMAIL="your@email.com"

#Main Variables
TodayDate=`date --date="today" +%d-%m-%y`
s3bucket='s3://yourbucket/'

# An array of directories you want to backup (I included a few configuration directories to).
dirstobackup=(
'/your/directories/path/'
)

# The MySQL databases you want to backup or leave empty
dbstobackup=(
'yourdb'
)
# The directory we're going to store our backups in on this server.
tmpbackupdir='/home/backups'

## The expiry dates of the backups
### Only store 0 days of backups on the server.
### Changed to 0 days to not fill the server with unneccessary backups
Expiry[0]=`date --date="today" +%d-%m-%y`

### Only store 2 weeks worth of backups on S3
Expiry[1]=`date --date="1 week ago" +%d-%m-%y`

### Using ExpiryDayOfMonth to skip first day of the month when deleting so monthly backups are kept on s3
ExpiryDayOfMonth=`date --date="1 week ago" +%d`

### Todays date.
TodayDate=`date --date="today" +%d-%m-%y`

## Finally, setup the today specific variables.
Today_tmpbackupdir=$tmpbackupdir'/'$TodayDate

## Check we can write to the backups directory
if [ -w "$tmpbackupdir" ]
then
  # Do nothing and move along.
    echo 'Found and is writable:  '$tmpbackupdir
else
    echo "Can't write to: "$tmpbackupdir
    exit
fi

## Make the backup directory (Also make it writable)
echo ''
echo 'Making Directory: '$Today_tmpbackupdir
mkdir $Today_tmpbackupdir

## GZip the directories and put them into the backups folder
echo ''
for i in "${dirstobackup[@]}"
do
    webcontents=`echo $i | tr '/' '_'`'.tar.gz'
    echo 'Backing up '$i' to '$Today_tmpbackupdir'/'$webcontents
    tar -czpPf $Today_tmpbackupdir'/'$webcontents $i
done

## Backup the MySQL databases
echo ''
for i in "${dbstobackup[@]}"
do
    filename=''$i'.sql'
    echo 'Dumping DB '$i' to '$Today_tmpbackupdir'/'$filename
    nice -n 19 mysqldump --quick --routines --events $i > $Today_tmpbackupdir'/'$filename
    tar -czpPf $Today_tmpbackupdir'/'$filename'.tar.gz' $Today_tmpbackupdir'/'$filename
    rm -R $Today_tmpbackupdir'/'$filename
done

## Sending new files to S3
echo 'Uploading Files to S3'
echo 'Syncing '$Today_tmpbackupdir' to '$s3bucket$HOSTNAME/$TodayDate'/'
s3cmd put --recursive -P --no-progress $Today_tmpbackupdir $s3bucket$HOSTNAME/ >/dev/null 2>&1
if [ $? -ne 0 ]; then
    SUBJECT="S3 Backup failed on $HOSTNAME"
    EMAILMESSAGE="/tmp/emailmessage3.txt"
        echo "This is to update you you that the S3 Backup Failed '$Today_TmpBackupDir' failed."> $EMAILMESSAGE
        echo "You should check things out immediately." >>$EMAILMESSAGE
    mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE
fi

# Cleanup.
echo ''
echo 'Removing local expired backup: '$tmpbackupdir'/'${Expiry[0]}
rm -R $tmpbackupdir'/'${Expiry[0]}

if [ "$ExpiryDayOfMonth" != '01' ]; then
    echo 'Removing remote expired backup: 's3://qinetqtbackups/$HOSTNAME/${Expiry[1]}'/'
    s3cmd del s3://qinetqtbackups/$HOSTNAME/${Expiry[1]}'/' --recursive >/dev/null 2>&1
    else
    echo 'No need to remove backup on the 1st'
fi

echo "S3 Backup Date:$TodayDate
Bucket:$s3bucket$HOSTNAME/" >> /root/j.facts
echo 'All Done! Yay! (",)'

## Notify admin that the script has finished
SUBJECT="S3 Backup Completed on $HOSTNAME!"
EMAILMESSAGE="/home/status/emailmessage4.txt"
echo "This is to inform you that S3 Backup Upload has completed."> $EMAILMESSAGE
mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE

## Email Report of What Exists on S3 in Today's Folder
exec 1>'/home/status/s3report.txt'
s3cmd ls $s3bucket$HOSTNAME/$TodayDate/
SUBJECT="S3 Backup Report of $HOSTNAME"
EMAILMESSAGE="/home/status/s3report.txt"
mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE
