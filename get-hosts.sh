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
# Version:   v1.2
# Date:      Sun Jul 21 10:43:35 2024 -0600
#

#
# FireMyPi:  get-hosts.sh
#

#
# Get /var/ipfire/main/hosts from a running firewall and store it
# in the config directory.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common

function usage()
{
	echo "Usage:  get-hosts.sh {-n|--node NODE} [--ip IP]"
	exit 1
}

ZONE=0

if [[ $# -eq 0 ]]
then
	usage
fi

#### Parse args
while [[ $# -gt 0 ]]
do
	case $1 in
		-n|--node)
			shift
			NODE=$((10#${1}))
			;;
		--ip)
			shift
			IP=$1
			;;
		*)
			usage
			;;
	esac
	shift
done

PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ ${PREFIX} ]] || abort "build prefix not found in ${SYSTEMVARS}"
HOSTS="config/${PREFIX}${NODE}.hosts"

if [[ -z ${IP} ]]
then
        IP="192.168.${NODE}.254"
fi

clear
header Get Fixleases

echo -e "Get 'hosts' file from a running node and copy it"
echo -e "to the config directory.\n"

if [[ -e ${HOSTS} ]]
then
	echo -e "${RED}*** WARNING ***${NC}\n"
	echo -e "${RED}    ${HOSTS} already exists${NC}\n"
	echo -e "Do you want to overwrite ${HOSTS}?\n"
	read -p "Type 'yes' to overwrite the hosts file: " YES
	if [[ ${YES} != "yes" ]]
	then
		abort Cancelled.
	else
		cp "${HOSTS}" "${HOSTS}.save${DATE}${TIME}"
		echo -e "\nBacked up current file to:  ${PREFIX}${NODE}.hosts.save${DATE}${TIME}\n"
	fi
fi

echo -e "Getting host names from firewall at ${IP}...\n"
echo "scp root@${IP}:/var/ipfire/main/hosts ${HOSTS}"

scp root@${IP}:/var/ipfire/main/hosts ${HOSTS}

echo -e "\nDone."
