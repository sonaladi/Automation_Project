#!/bin/sh 
s3Bucket=upgrad-adityakumar
yourName=Aditya
inventoryFilePath=/var/www/html/inventory.html
cronJobPath=/etc/cron.d/automation


sudo apt update -y
sudo apt install awscli -y
sudo apt update -y
sleep 10

checkApache=$(dpkg --get-selections | grep apache2 | awk '{print $2}' | head -1)
if [ $checkApache = "install" ];
then
        echo "Apache is installed"
else
        echo "Apache is installing"
		sudo apt-get install apache2 -y
fi
sleep 10

apacheStatus=$(service apache2 status | grep -i Active | awk '{print $2}')
if [ "$apacheStatus" = "inactive" ]
then
        systemctl start apache2
        echo "Apache server started"
else 
	    echo "Apache is running"	
fi

sleep 10

serviceStatus=$(service --status-all | grep apache2 | awk '{print $2}')
if [ "$serviceStatus" = "+" ]
then
        echo "Apache service is running"
else
        service apache2 start
        echo "Apache service started"
fi
sleep 10

timestamp=$(date '+%d%m%Y-%H%M%S')

cd /var/log/apache2
sudo tar -czvf /var/tmp/$yourName-httpd-logs-$timestamp.tar access.log error.log

sleep 10

aws s3 cp /var/tmp/$yourName-httpd-logs-$timestamp.tar s3://${s3Bucket}/$yourName-$timestamp.tar

if [ -f "$inventoryFilePath" ]
then
        echo "$inventoryFilePath  File present"
else
        echo "inventory.html File Not Found,Creating the new file"
        touch $inventoryFilePath
        echo "<b>Log Type &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Time Created &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Type &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Size</b>" >> $inventoryFilePath
        echo "new file is created in $inventoryFilePath"
fi
echo "adding backup log status into inventory.html file"
fileSize=$(du -h /var/tmp/${yourName}-httpd-logs-$timestamp.tar | awk '{print $1}')
echo "Backup Size :$fileSize"
echo "<br>httpd-logs &nbsp;&nbsp;&nbsp;&nbsp; $timestamp &nbsp;&nbsp;&nbsp;&nbsp; tar &nbsp;&nbsp;&nbsp;&nbsp; $fileSize" >> $inventoryFilePath


if [ -f "$cronJobPath" ]
then
        echo "Cron job is scheduled already"
else
        touch $cronJobPath
        #this cron job will execute on every dat at 12.00
        echo "0 0 * * * root /root/Automation_Project/automation.sh" >> $cronJobPath
        echo "Cron Job is scheduled"
fi
