#!/bin/bash

#  instance-o-mizer.bash
#  
#
#  Created by Jim Leitch on 3/17/14.
#
FLAVOR=db2fc608-e6cf-4f59-a397-ba1c5043761d
IMAGE=af5ff05d-5b31-40d0-b240-0c4b6742c633
COLOR=$1
SERVERTYPE=$2
INSTANCENAME=${COLOR}-${SERVERTYPE}

. ~/keystonerc_admin


echo For Dennis, checking for duplicate instances
if [[ `nova list | grep $INSTANCENAME` != "" ]];
then
	echo Instance name $INSTANCENAME already exists, bombing out !
	exit 1
fi

echo Starting Instance ${COLOR}-${SERVERTYPE}
#####INSTANCEID=`nova boot --key-name master  --flavor  $FLAVOR --image $IMAGE ${COLOR}-${SERVERTYPE} | grep " id " | awk '{print $4}'`
#####sleep 5
INSTANCEFLOATINGIP=`nova show $INSTANCEID | grep novanetwork | awk '{print $6}'`

echo INSTANCEID=$INSTANCEID
echo INSTANCEFLOATINGIP=$INSTANCEFLOATINGIP

#DNS

echo Refreshing DNS
sudo cp /etc/hosts /etc/hosts.tmp
sudo grep STATIC /etc/hosts.tmp > /etc/hosts
sudo rm /etc/hosts.tmp
sudo -E "nova list | grep ACTIVE | awk \'{print \$9,\$4}\' >> /etc/hosts"
sudo /etc/init.d/dnsmasq reload

#for INSTANCE in `nova list | grep ACTIVE | awk '{print $2}'`;
#do
#
#	DNSNAME=`nova show $INSTANCE | grep name | awk '{print $4}'`
#	DNSIP=`nova show $INSTANCE | grep novanetwork | awk '{print $6}'`
#   #echo $DNSIP $DNSNAME >> /etc/hosts
#done






