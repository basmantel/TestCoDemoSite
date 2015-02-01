#!/bin/bash
# Run ansible playbooks
COLOR=$1

echo +++Sleeping 50 seconds to ensure server startup
sleep 50
 # echo +++Wait until all instances operational
# ALLHOSTSLIVE=0
# DINK="."
# while [[ $ALLHOSTSLIVE -eq 0 ]];
# do
# ALLHOSTSLIVE=0
# for HOST in $HOST_LIST;
#    do
#    	  echo $DINK
#    	  DINK=$DINK"."
#    	  sleep 2
#    	  /usr/bin/nc -w 1 -z $HOST 22
#       if [[ $? = "0" ]];
#       then 
#       	ALLHOSTSLIVE=1
#       else
#       	ALLHOSTSLIVE=0
#       	break
#       fi
#    done
# done
# echo +++All instances operational
 echo +++All instances operational


sudo ansible-playbook --limit=$COLOR -i /etc/ansible/hosts playbooks/homegrown/testco_init.yaml
sudo ansible-playbook --limit=$COLOR -i /etc/ansible/hosts playbooks/examples/lamp_simple/site.yml 
sudo ansible-playbook --limit=$COLOR -i /etc/ansible/hosts playbooks/examples/jboss-standalone/site.yml 

echo +++Rebooting all $COLOR servers
sudo ansible $COLOR -m command -a "/sbin/reboot"







