#define Variable
user="mt940"
host="s4hprd"
localDir="/mt940-asg/prd"
remoteDir="mt940/prd"
logsc=/opt/mt940/sync_prd.log
sentlog=$localDir"/sent"
#temporary list file
tmpbca=/opt/mt940/prdtmpbca.txt
tmpbag=/opt/mt940/prdtmpbag.txt
tmpmdr=/opt/mt940/prdtmpmdr.txt

#####-------------------------------- Start script ----------------------------------------####

### copy BCA ###
find $localDir/BCA -maxdepth 1 -type f -mtime +1 -exec ls {} \; >> $tmpbca
echo Start Copy BCA >> $logsc
cat $tmpbca >> $logsc

while read file ; do
export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
ls

cd $remoteDir/BCA
mput $file
!mv $file $sentlog/BCA
EOF


done < $tmpbca
rm $tmpbca

echo verify file on RISE prd BCA >> $logsc
export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
cd $remoteDir/BCA
ls >> $logsc
EOF
echo End of verify on RISE prd BCA >> $logsc

echo End of copy BCA >> $logsc
#### End of Copy BCA ###
###-------------------------------------------------####


### Copy MDR  ####
find $localDir/MDR -maxdepth 1 -type f -mtime +1 -exec ls {} \; >> $tmpmdr
echo Start Copy MDR >> $logsc
cat $tmpmdr >> $logsc

while read file ; do
export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
ls

cd $remoteDir/MDR
mput $file
!mv $file $sentlog/MDR
EOF

done < $tmpmdr
rm $tmpmdr

echo verify file on RISE prd MDR >> $logsc
export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
cd $remoteDir/MDR
ls >> $logsc
EOF
echo End of verify on RISE prd MDR >> $logsc

echo End of Copy MDR >> $logsc
#### End of Copy MDR ####
####------------------------------------------------####


#### Copy BAG ####
find $localDir/BAG -maxdepth 1 -type f -mtime +1 -exec ls {} \; >> $tmpbag
echo Start Copy BAG >> $logsc
cat $tmpbag >> $logsc

while read file ; do
export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
ls

cd $remoteDir/BAG
mput $file
!mv $file $sentlog/BAG
EOF

done < $tmpbag
rm $tmpbag

echo verify file on RISE prd BAG >> $logsc
export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
cd $remoteDir/BAG
ls >> $logsc
EOF
echo End of verify on RISE prd BAG>> $logsc

echo End of Copy BAG >> $logsc
### End of Copy BAG ###
####-------------------------------------------------###

echo Start Sync back >> $logsc
### Syncronize from S4 to AWS S3 ####

export LFTP_PASSWORD=$(cat /opt/mt940/sftp_s4hprd.pw)
lftp --env-password sftp://$user@$host << EOF
ls
cd ../../..
mirror -n $remoteDir/BCA/SUCCESS $localDir/BCA/SUCCESS
cd ../../..
mirror -n $remoteDir/BCA/FAILED $localDir/BCA/FAILED
cd ../../..
mirror -n $remoteDir/MDR/SUCCESS $localDir/MDR/SUCCESS
cd ../../..
mirror -n $remoteDir/MDR/FAILED $localDir/MDR/FAILED
cd ../../..
mirror -n $remoteDir/BAG/SUCCESS $localDir/BAG/SUCCESS
cd ../../..
mirror -n $remoteDir/BAG/FAILED $localDir/BAG/FAILED

EOF
#### End of Syncronize ####
echo END of Sync back >> $logsc
###------------------------------------------------------###
date >> $logsc