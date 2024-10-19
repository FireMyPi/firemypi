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
# Version:   v1.5
# Date:      Sat Oct 12 12:48:47 2024 -0600
#

#
# FireMyPi:  get-fixleases.sh
#

#
# Get /var/ipfire/dhcp/fixleases from a running firewall and store it
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
	echo "Usage:  get-fixleases.sh {-n|--node NODE} [--ip IP]"
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
FIXLEASES="config/${PREFIX}${NODE}.fixleases"

if [[ -z ${IP} ]]
then
        IP="192.168.${NODE}.254"
fi

clear
header Get Fixleases

echo -e "Get 'fixleases' file from a running node and copy it"
echo -e "to the config directory.\n"

if [[ -e ${FIXLEASES} ]]
then
	echo -e "${RED}*** WARNING ***${NC}\n"
	echo -e "${RED}    ${FIXLEASES} already exists${NC}\n"
	echo -e "Do you want to overwrite ${FIXLEASES}?\n"
	read -p "Type 'yes' to overwrite the fixleases file: " YES
	if [[ ${YES} != "yes" ]]
	then
		abort Cancelled.
	else
		cp "${FIXLEASES}" "${FIXLEASES}.save${DATE}${TIME}"
		echo -e "\nBacked up current file to:  ${PREFIX}${NODE}.fixleases.save${DATE}${TIME}\n"
	fi
fi

echo -e "Getting fixed leases from firewall at ${IP}...\n"
echo "scp root@${IP}:/var/ipfire/dhcp/fixleases ${FIXLEASES}"

scp root@${IP}:/var/ipfire/dhcp/fixleases ${FIXLEASES}

echo -e "\nDone."
