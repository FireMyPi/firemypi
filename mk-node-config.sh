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
# Version:   v1.1
# Date:      Wed Jun 26 23:17:45 2024 -0600
#

#
# FireMyPi:  mk-node-config.sh
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
# Version:   v1.1
# Date:      Wed Jun 26 23:17:45 2024 -0600
#

#
# FireMyPi:  ${NODEFILE}
#

#
# FireMyPi Node Configuration
#

# Node: ${NODE}

    timezone: "${TIMEZONE}"

    wireless_red0: false

    # DHCP Fixed Leases
    #
    # The 'fixleases_mode' tells FireMyPi where to get the information for
    # DHCP fixed leases to write to the 'fixleases' file in the config.
    #
    # The options are:
    #
    #     off             - Turns off fixed leases for the node.  No
    #                       'fixleases' file is created for the config.
    #
    #     fixleases_var   - Reads fixed leases from the 'fixleases'
    #                       variable below to create the 'fixleases' file.
    #
    #     fixleases_file  - Reads fixed leases from the 'config/
    #                       nodeN.fixleases' file for the node to create
    #                       the 'fixleases' file.
    #
    #     combined        - Reads fixed leases from both the 'fixleases'
    #                       variable and the 'config/nodeN.fixleases' file.
    #                       The records are then combined and deduplicated
    #                       to create the 'fixleases' file.
    #
    # Select one of the modes listed below:
    fixleases_mode: "off"
    #fixleases_mode: "fixleases_var"
    #fixleases_mode: "fixleases_file"
    #fixleases_mode: "combined"

    fixleases:

    - mac: "00:00:00:00:00:00"
      ip: "192.168.${NODE}.0"
      remark: "Sample Host 1"

    - mac: "00:00:00:00:00:00"
      ip: "192.168.${NODE}.0"
      remark: "Sample Host 2"

    # Local DNS Hostnames
    #
    # The 'hosts_mode' tells FireMyPi where to get the information for
    # local DNS hostnames to write to the 'hosts' file in the config.
    #
    # The options are:
    #
    #     off             - Turns off hostnames for the node.  No 'hosts'
    #                       file is created for the config.
    #
    #     hosts_var       - Reads hostnames from the 'hosts' variable
    #                       below to create the 'hosts' file.
    #
    #     hosts_file      - Reads hostnames from the 'config/nodeN.hosts'
    #                       file for the node to create the 'hosts' file.
    #
    #     combined        - Reads hostnames from both the 'hosts' variable
    #                       and the 'config/nodeN.hosts' file. The records
    #                       are then combined and deduplicated to create
    #                       the 'hosts' file for the config.
    #
    # Select one of the modes listed below:
    hosts_mode: "off"
    #hosts_mode: "hosts_var"
    #hosts_mode: "hosts_file"
    #hosts_mode: "combined"

    hosts:

    - hostname: "Sample Host 1"
      ip: "192.168.${NODE}.0"
      domain: "localdomain"
      generate_ptr: "on"
      enabled: "on"

    - hostname: "Sample Host 2"
      ip: "192.168.${NODE}.0"
      domain: "localdomain"
      generate_ptr: "on"
      enabled: "on"

...
HERE

echo -e "\nNode configuration written to:\n"
echo -e "\t${GRN}${NODEFILE}${NC}\n"

echo -e "Done."
exit 0
