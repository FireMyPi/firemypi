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
# FireMyPi:  get-fwrules.sh
#

#
# Get firewall rules from a running firewall and store in the 'config'
# directory.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common

ZONE=0

if [[ $# -eq 0 ]]
then
	echo "Usage:  get-fwrules.sh {-n|--node NODE} [--ip IP]"
	exit 0
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
			echo "Usage:  get-fwrules.sh (-n|--node) NODE [--ip IP]"
			exit 0
			;;
	esac
	shift
done

PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ ${PREFIX} ]] || abort "build prefix not found in ${SYSTEMVARS}"
RULES="config/${PREFIX}${NODE}.fwrules"

if [[ -z ${IP} ]]
then
	IP="192.168.${NODE}.254"
fi

clear
echo -e "${RED}FireMyPi Get Firewall Rules${NC}\n"

echo -e "Get firewall rules from a running IPFire firewall and copy"
echo -e "them to the config directory.\n"

if [[ -e ${RULES} ]]
then
	echo -e "${RED}*** WARNING ***${NC}\n"
	echo -e "${RED}    ${RULES} already exists${NC}\n"
	echo -e "Do you want to overwrite ${RULES}?\n"
	read -p "Type 'yes' to overwrite the firewall rules file: " YES
	if [[ ${YES} != "yes" ]]
	then
		echo -e "\nCancelled.\n"
		exit 1
	else
		cp "${RULES}" "${RULES}.save${DATE}${TIME}"
		echo -e "\nBacked up current file to:  ${PREFIX}${NODE}.rules.save${DATE}${TIME}\n"
	fi
fi

echo -e "Getting firewall rules from firewall at ${IP}...\n"
echo "scp root@${IP}:/var/ipfire/firewall/config ${RULES}"

scp root@${IP}:/var/ipfire/firewall/config ${RULES}

echo -e "\nDone."
