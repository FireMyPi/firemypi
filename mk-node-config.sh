#!/bin/bash

##
## Copyright © 2020-2024 David Čuka and Stephen Čuka All Rights Reserved.
##
## FireMyPi is licensed under the Creative Commons Attribution-NonCommercial-
## NoDerivatives 4.0 International License (CC BY-NC-ND 4.0).
##
## The full text of the license can be found in the included LICENSE file 
## or at https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode.en.
##
## For the avoidance of doubt, FireMyPi is for personal use only and may not 
## be used by or for any business in any way.
##

#
# FireMyPi:	mk-node-config.sh
#

#
# Create a node configuration file.
#
# The script takes a node number as an argument and will prompt for a timezone.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common


NODE=0
NODEFILE="NONE"
ZONEINFO="/usr/share/zoneinfo"
TIMEZONE=`timedatectl show -p Timezone | cut -d= -f2`
PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ ${PREFIX} ]] || abort "build prefix not found in ${SYSTEMVARS}"


#### Parse args
while [[ $# -gt 0 ]]
do
	case $1 in
		--node|-n )
			shift
			NODE=$1
			if [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
			then
				abort "node must be between 1 and 254"
			fi
			;;
		*)
			echo "Usage:  mk-node-config.sh [--node|-n {NODE}]"
			exit 0
			;;
	esac
	shift
done


clear
header Node Configuration File Creation

while [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
do
	read -p "Enter a node number between '1' and '254': " NODE
	if [[ ${NODE} -ge 1 ]] || [[ ${NODE} -le 254 ]]
	then
		echo ""
	fi
done

NODE=$((10#${NODE}))
NODEFILE="${PREFIX}${NODE}_vars.yml"

echo -e "Create node configuration file in 'config' directory:\n"
echo -e "\t${GRN}${NODEFILE}${NC}\n"

if [[ -e ${CONFIG}/${NODEFILE} ]]
then
	echo -e "${RED}*** WARNING ***${NC}\n"
	echo -e "\t${RED}config/${NODEFILE} already exists${NC}\n"
	echo -e "Do you want to overwrite ${NODEFILE}?\n"
	read -p "Type 'yes' to overwrite the node configuration file: " YES
	if [[ ${YES} != "yes" ]]
	then
		echo -e "\nCancelled.\n"
		exit 1
	else
		cp ${CONFIG}/${NODEFILE} "${CONFIG}/${NODEFILE}.save${DATE}${TIME}"
		echo -e "\nBacked up current file to:  ${PREFIX}${NODE}_vars.yml.save${DATE}${TIME}\n"
	fi
fi

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
echo -e "${RED}FireMyPi Node Configuration File Creation${NC}\n"

echo -e "Your system's timezone is: ${GRN}${TIMEZONE}${NC}\n"

echo -e "Do want you to set a different time zone for node ${NODE}?\n"

read -p "Type 'yes' to change the time zone or <Enter> to continue: " YES

if [[ ${YES} == "yes" ]]
then
	TIMEZONE="NONE"
	while [[ ${TIMEZONE} == "NONE" ]]
	do
		echo ""
		read -p "Enter the new time zone: " TIMEZONE
		if [[ -f "${ZONEINFO}/${TIMEZONE}" ]]
		then
			echo -e "\nTime zone set to: ${GRN}${TIMEZONE}${NC}\n"
		else
			echo -e "${RED}ERROR - Time zone not found in ${ZONEINFO}.${NC}"
			TIMEZONE="NONE"
		fi
	done
fi

#echo -e "\nCreating node configuration file:\n"
#echo -e "\t${GRN}${NODEFILE}${NC}\n"

cat << HERE > ${CONFIG}/${NODEFILE}
---

##
## Copyright © 2020-2024 David Čuka and Stephen Čuka All Rights Reserved.
##
## FireMyPi is licensed under the Creative Commons Attribution-NonCommercial-
## NoDerivatives 4.0 International License (CC BY-NC-ND 4.0).
##
## The full text of the license can be found in the included LICENSE file 
## or at https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode.en.
##
## For the avoidance of doubt, FireMyPi is for personal use only and may not 
## be used by or for any business in any way.
##

#
# FireMyPi Node Configuration
#

# Node: ${NODE}

    timezone: "${TIMEZONE}"

    wireless_red0: false

    dhcp_static_enabled: false
    dhcp_static:

    - host: "Sample Host 1"
      macid: "00:00:00:00:00:00"
      ip: "192.168.${NODE}.0"

    - host: "Sample Host 2"
      macid: "00:00:00:00:00:00"
      ip: "192.168.${NODE}.0"

...
HERE

echo -e "\nNode configuration written to:\n"
echo -e "\t${GRN}${NODEFILE}${NC}\n"

echo -e "Done."
exit 0
