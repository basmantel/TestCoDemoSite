#!/bin/bash

#  instance-o-mizer.bash
#  
#
#  Created by Jim Leitch on 3/17/14.
#
###FLAVOR=db2fc608-e6cf-4f59-a397-ba1c5043761d

. ~/keystonerc_dennis

IMAGE=0c4b64c2-16a0-4bb4-bc40-bf3d0cba7ccd
###IMAGE=4636ea02-5779-4e27-8265-8de679d09c28
COLOR=$1
SERVERTYPE=$2
INSTANCENAME=${COLOR}-${SERVERTYPE}

FLOATINGIP=$(nova list| grep $INSTANCENAME| awk '{print$13}')  
if [[ $FLOATINGIP == "|" ]] 
then
   FLOATINGIP=""
fi

VALID_COLORS="red|orange|yellow|green|blue|indigo|violet|testing|ci|acceptance|production"

if [[ ${SERVERTYPE} != "jboss" ]];
then
   FLAVOR=90da44cb-b4dc-4cb6-a2d7-6888dfd524ee
else
   FLAVOR=a200a61e-cf01-48a6-bbd3-91fddfba256c
fi

echo +++Checking for duplicate instances
if [[ `nova list | grep $INSTANCENAME` != "" ]];
then
   echo +++Instance name $INSTANCENAME already exists, KILL IT !!!
   echo +++Delete Floating IP
   if [[ $FLOATINGIP != "" ]] 
   then
      nova floating-ip-delete $FLOATINGIP
   fi
   
   echo +++Delete instance
   nova delete $INSTANCENAME
   sleep 10
   echo +++It is an ex $INSTANCENAME it has ceased to be
fi

echo +++Starting Instance ${COLOR}-${SERVERTYPE}
echo +++"nova boot --key-name denniskp2 --nic net-id=000f5738-97f5-418c-9331-fcae0b39c9bd --flavor $FLAVOR --image $IMAGE ${COLOR}-${SERVERTYPE}"


INSTANCEID=`nova boot --key-name denniskp2 --nic net-id=000f5738-97f5-418c-9331-fcae0b39c9bd --flavor $FLAVOR --image $IMAGE ${COLOR}-${SERVERTYPE} | grep " id " | awk '{print $4}'`

FLOATINGIP=$(nova floating-ip-create ext-net | grep ext-net | cut -f2 -d" ")

echo +++Add floating-ip to instance

nova add-floating-ip $INSTANCEID $FLOATINGIP


TIMEOUTCOUNTER=120
while [[ `nova list | grep ACTIVE | grep $INSTANCEID` = "" ]];
do
sleep 1
TIMEOUTCOUNTER=$TIMEOUTCOUNTER-1
if [[ $TIMEOUTCOUNTER -ge 120 ]];
then
echo +++Instance startup timeout reached, bombing out
exit 1
fi
done

sleep 10

INSTANCEFLOATINGIP=`nova show $INSTANCEID | grep network | awk '{print $6}'`

echo +++INSTANCEID=$INSTANCEID
echo +++INSTANCEFLOATINGIP=$INSTANCEFLOATINGIP

# Create Local DNS
echo +++Refreshing DNS and HOSTS
sudo sh -c "grep STATIC /etc/hosts > /etc/hosts.tmp"
#sudo -E sh -c "nova list | grep ACTIVE | awk '{print \$9,\$4}' >> /etc/hosts.tmp"
#sudo -E sh -c "nova list | grep ACTIVE | awk '{print $8,\" \",$4}' | tr -d \"novanetwork=\" >> /etc/hosts.tmp"
#sudo -E sh -c "nova list | grep ACTIVE | awk '{print \$12,\$13}'|cut -d= -f2,3 |cut -d '|' -f1 | cut -f2 -d"," | tr -d \" \" >> /etc/hosts.tmp"
sudo -E sh -c "nova list | grep ACTIVE | awk '{print \$13,\$4}' >> /etc/hosts.tmp"

sudo mv -f /etc/hosts.tmp /etc/hosts
sudo /etc/init.d/dnsmasq reload

sleep 10

###echo +++Updating hosts on master
###sudo scp /etc/hosts root@10.10.10.10:/etc/hosts

###echo +++Restarting nginx reverse proxy
###sudo /etc/init.d/nginx restart

# Refresh ansible hosts
echo +++Refreshing Ansible hosts
# Create ansible Hosts File
HOST_LIST=`nova list | grep -E $VALID_COLORS | awk '{print $4}'`
COLOR_LIST=`nova list | grep -E $VALID_COLORS | awk '{print $4}' | cut -d"-" -f1 | sort | uniq`
SERVERTYPES_LIST=`nova list | grep -E $VALID_COLORS | awk '{print $4}' | cut -d"-" -f2 | sort | uniq`
#echo HOST_LIST=$HOST_LIST
#echo COLOR_LIST=$COLOR_LIST
#echo SERVERTYPES_LIST=$SERVERTYPES_LIST

sudo sh -c "echo \# Ansible hosts file autogenerated on `date` >> /etc/ansible/hosts.tmp"
sudo sh -c "echo \# Do not edit >> /etc/ansible/hosts.tmp"

for HOST in $HOST_LIST;
do
   sudo sh -c "echo $HOST >> /etc/ansible/hosts.tmp"
done

sudo sh -c "echo >> /etc/ansible/hosts.tmp"

for SERVERTYPE in $SERVERTYPES_LIST;
do
   sudo sh -c "echo; echo [$SERVERTYPE] >> /etc/ansible/hosts.tmp"
   for HOST in $HOST_LIST;
   do
      sudo sh -c "echo $HOST | grep $SERVERTYPE  >> /etc/ansible/hosts.tmp"
   done
   sudo sh -c "echo >> /etc/ansible/hosts.tmp"
done

for COLOR in $COLOR_LIST;
do
   sudo sh -c "echo; echo [$COLOR] >> /etc/ansible/hosts.tmp"
   for HOST in $HOST_LIST;
   do
      sudo sh -c "echo $HOST | grep $COLOR  >> /etc/ansible/hosts.tmp"
   done
   sudo sh -c "echo >> /etc/ansible/hosts.tmp"
done

sudo mv /etc/ansible/hosts.tmp /etc/ansible/hosts
