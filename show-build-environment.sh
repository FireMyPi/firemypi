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
# FireMyPi: 	show-build-environment.sh
#

#
# Show the current status of the build environment.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common

SHOW="no"
CORENUM=0
PREFIX="NONE"
NODE=0
DDNS="NONE"
OVPN="NONE"
VPN="NONE"
FWRULES="NONE"
MISSING=0
SHOWFEATURES="false"


function show-packages()
{
	ALLOK="yes"
	printf "%-32s" "Required packages:"
	while read -r FEATURE FUNCTION
	do
		if ! ${FUNCTION}
		then
			if [[ ${ALLOK} == yes ]]
			then
				printf "\n"
			fi
			printf "%-32s" ${FEATURE}
			printf "${RED}%-20s${NC}\n" missing
			((MISSING+=1))
			ALLOK="no"
		fi
	done <<HERE
ansible		ansible-check
apache2-utils	apache2-utils-check
openssl		openssl-check
pwgen		pwgen-check
u-boot-tools	u-boot-tools-check
HERE
	if [[ ${ALLOK} == yes ]]
	then
		printf "${GRN}%-20s${NC}" installed
	fi
	echo -e "\n"
}

function show-config-files()
{

	echo "Build configuration files:"
	while read -r FILE FEATURE
	do
		printf "%-32s" `basename ${FILE}`
		if [[ -e ${DNAME}/${FILE} ]]
		then
			printf "${GRN}%-20s${NC}\n" exists
		elif [[ ${FEATURE} ]]
		then
			STATE=`get-config ${SYSTEMVARS} ${FEATURE}`
			[[ ${STATE} ]] || abort "feature not found, is ${SYSTEMVARS} missing?"
			if [[ ${STATE} == "true" ]]
			then
				printf "${RED}%-20s${NC}\n" missing
		                ((MISSING+=1))
			else
				printf "${YLW}%-20s${NC}\n" "missing - optional"
			fi
		else
			printf "${RED}%-20s${NC}\n" missing
			((MISSING+=1))
		fi
	done <<HERE
core-image-to-use.yml
secrets/root-secret.yml
secrets/webadmin-secret.yml
secrets/ddns-secret.yml		include_ddns
secrets/ovpn-p12-secret.yml	include_ovpn
secrets/vpnpsk-secret.yml	include_vpn
HERE
	echo ""
}

function show-system-features()
{
	echo "Default features configured in system_vars.yml:"
	while read -r FEATURE
	do
		printf "%-32s" ${FEATURE}
		STATE=`get-config ${SYSTEMVARS} ${FEATURE}`
		[[ ${STATE} ]] || abort "feature not found, is ${SYSTEMVARS} missing?"
		if [[ ${STATE} == "true" ]]
		then
			printf "${GRN}%-20s${NC}\n" "true"
		else
			printf "${RED}%-20s${NC}\n" "false"
		fi
	done <<HERE
include_dhcp
include_httpd
include_ssh
HERE
	echo ""
	echo "Optional features configured in system_vars.yml:"
	while read -r FEATURE
	do
		printf "%-32s" ${FEATURE}
		STATE=`get-config ${SYSTEMVARS} ${FEATURE}`
		[[ ${STATE} ]] || abort "feature not found, is ${SYSTEMVARS} missing?"
		if [[ ${STATE} == "true" ]]
		then
			printf "${GRN}%-20s${NC}\n" "true"
		else
			printf "${RED}%-20s${NC}\n" "false"
		fi
	done <<HERE
include_ddns
include_dnsaddservers
include_fireinfo
include_fwrules
include_ipblocklist
include_locationblock
include_monitor_red0
include_ovpn
include_vpn
HERE
	echo ""
}

function show-core-number()
{
	printf "%-32s" "The core image number is:"
	if [[ ${CORENUM} == missing ]]
	then
		if [[ ${NODE} -ne 0 ]]
		then
			printf "${RED}%-20s${NC}\n" missing
			((MISSING+=1))
		else
			printf "${RED}%-20s${NC}\n" 0
		fi
	else
		printf "${GRN}%-20s${NC}\n" ${CORENUM}
	fi
	echo ""
}

function show-node-prefix()
{
	printf "%-32s" "The node prefix is:"
	printf "${GRN}%-20s${NC}\n" ${PREFIX}
	echo ""
}

function show-host-numbers()
{
	printf "%-32s" "The test firewall IP is:"
	printf "${GRN}%-20s${NC}\n" 192.168.${NODE}.${TESTHOST}
	printf "%-32s" "The firewall IP is:"
	printf "${GRN}%-20s${NC}\n" 192.168.${NODE}.${HOST}
	echo ""
}

function show-built-nodes()
{
	echo "The node(s) listed below have been built:"
	COUNT=`ls ${DEPLOY}/${PREFIX}* 2>/dev/null | wc -l`
	if [[ ${COUNT} == 0 ]]
	then
		echo -e "None found"
	else
		NODES=`ls ${DEPLOY}`
		for ITEM in ${NODES}
		do
			COUNT1=`mount | grep ${DEPLOY}/${ITEM} | wc -l`
			if [[ ${COUNT1} == 0 ]]
			then
				printf "${GRN}%s${NC} " ${ITEM}
			else
				printf "${RED}%s${NC} " ${ITEM}
			fi
		done
		echo ""
	fi
	echo ""
}

function show-node-config()
{
	echo "Node configuration files:"
	printf "%-32s" ${PREFIX}${NODE}_vars.yml
	if [[ -e ${CONFIG}/${PREFIX}${NODE}_vars.yml ]]
	then
		printf "${GRN}%-20s${NC}\n" exists
	else
		printf "${RED}%-20s${NC}\n" missing
		((MISSING+=1))
	fi
	printf "%-32s" ${PREFIX}${NODE}.fixleases
	if [[ -e ${CONFIG}/${PREFIX}${NODE}.fixleases ]]
	then
		printf "${GRN}%-20s${NC}\n" exists
	else
		printf "${YLW}%-20s${NC}\n" "missing - optional"
	fi
	printf "%-32s" ${PREFIX}${NODE}.fwrules
	if [[ -e ${CONFIG}/${PREFIX}${NODE}.fwrules ]]
	then
		printf "${GRN}%-20s${NC}\n" exists
	elif [[ ${FWRULES} == "true" ]]
	then
		printf "${RED}%-20s${NC}\n" "missing"
		((MISSING+=1))
	else
		printf "${YLW}%-20s${NC}\n" "missing - optional"
	fi
	echo ""
}

function show-node-deploy()
{
	echo "Configurations in deploy/${PREFIX}${NODE}:"
	COUNT=`ls ${DEPLOY}/${PREFIX}${NODE}/firemypi*.tgz 2>/dev/null | wc -l`
	if [[ ${COUNT} == 0 ]]
	then
		echo -e "None found"
	else
		find ${DEPLOY}/${PREFIX}${NODE} -maxdepth 1 -name "firemypi*.tgz" -printf "${GRN}%f${NC}\n"
	fi
	echo ""
	echo "Images in deploy/${PREFIX}${NODE}:"
	COUNT=`ls ${DEPLOY}/${PREFIX}${NODE}/firemypi*.img 2>/dev/null | wc -l`
	if [[ ${COUNT} == 0 ]]
	then
		echo -e "None found"
	else
		find ${DEPLOY}/${PREFIX}${NODE} -maxdepth 1 -name "firemypi*.img" -printf "${GRN}%f${NC}\n"
	fi
	echo ""
}

function show-node-portable()
{
	echo "Portable builds in portable/${PREFIX}${NODE}:"
	COUNT=`ls ${DNAME}/portable/${PREFIX}${NODE}/firemypi*.tgz 2>/dev/null | wc -l`
	if [[ ${COUNT} == 0 ]]
	then
		echo -e "None found"
	else
		find ${DNAME}/portable/${PREFIX}${NODE} -maxdepth 1 -name "firemypi*.tgz" -printf "${GRN}%f${NC}\n"
	fi
	echo ""
}

function show-node-features()
{
	echo "Default features configured for ${PREFIX}${NODE}:"
	while read -r FEATURE
	do
		printf "%-32s" ${FEATURE}
		STATE=`get-config ${CONFIG}/${PREFIX}${NODE}_vars.yml ${FEATURE}`
		[[ -z ${STATE} ]] && STATE=`get-config ${SYSTEMVARS} ${FEATURE}`
		[[ ${STATE} ]] || abort "feature not found, is ${SYSTEMVARS} missing?"
		if [[ ${STATE} == "true" ]]
		then
			printf "${GRN}%-20s${NC}\n" "true"
		else
			printf "${RED}%-20s${NC}\n" "false"
		fi
	done <<HERE
include_dhcp
include_httpd
include_ssh
HERE
	echo ""
	echo "Optional features configured for ${PREFIX}${NODE}:"
	while read -r FEATURE
	do
		printf "%-32s" ${FEATURE}
		STATE=`get-config ${CONFIG}/${PREFIX}${NODE}_vars.yml ${FEATURE}`
		[[ -z ${STATE} ]] && STATE=`get-config ${SYSTEMVARS} ${FEATURE}`
		[[ ${STATE} ]] || abort "feature not found, is ${SYSTEMVARS} missing?"
		if [[ ${STATE} == "true" ]]
		then
			printf "${GRN}%-20s${NC}\n" "true"
		else
			printf "${RED}%-20s${NC}\n" "false"
		fi
	done <<HERE
include_ddns
include_dnsaddservers
include_fireinfo
include_fwrules
include_ipblocklist
include_locationblock
include_monitor_red0
include_ovpn
include_vpn
HERE
	echo ""
}

function show-missing-count()
{
	if [[ ${MISSING} == 0 ]]
	then
		printf "%-32s" "Number of missing items:"
		printf "${GRN}%-20s${NC}\n\n" ${MISSING}
	else
		printf "%-32s" "Number of missing items:"
		printf "${RED}%-20s${NC}\n\n" ${MISSING}
	fi
}

function check-mounts()
{
	COUNT=`mount | grep ${DEPLOY}/${PREFIX}${NODE} | wc -l`
	if [[ ${COUNT} != 0 ]]
	then
		echo -e "${RED}WARNING - unexpected mounts found in build directory:${NC}\n"
		MOUNTS=`mount | grep ${DEPLOY}/${PREFIX}${NODE} | cut -d\  -f3`
		for ITEM in ${MOUNTS}
		do
			echo -e "${RED}${ITEM}${NC}"
		done
		echo ""
	fi
}

function show-time-zone()
{
	TIMEZONE=`get-config ${CONFIG}/${PREFIX}${NODE}_vars.yml timezone`
	if [[ ${TIMEZONE} ]]
	then
		printf "%-32s" "Time zone for ${PREFIX}${NODE} is"
		printf "${GRN}%-20s${NC}\n" "${TIMEZONE}"
		echo ""
	fi
}

function show()
{
	# Show the build environment.  If node is set, show the node also.
	clear
	if [[ ${NODE} -eq 0 ]]
	then
		header Build Environment:
		if [[ ${SHOWFEATURES} == "true" ]]
		then
			show-system-features
		else
			show-packages
			show-config-files
			show-core-number
			show-node-prefix
			show-missing-count
			show-built-nodes
		fi
	else
		header Build Environment:
		if [[ ${SHOWFEATURES} == "true" ]]
		then
			show-node-features
		else
			show-node-config
			show-time-zone
			show-host-numbers
			show-missing-count
			show-node-deploy
			show-node-portable
			check-mounts
		fi
	fi
	exit ${MISSING}
}

#### Parse args
while [[ $# -gt 0 ]]
do
	case $1 in
		-n|--node)
			shift
			NODE=$((10#${1}))
			if [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
			then
				abort "node must be between 1 and 254"
			fi
			;;
		--features)
			SHOWFEATURES="true"
			;;
		*)
			abort "invalid option '$1'"
			;;
	esac
	shift
done

#### MAIN

PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ ${PREFIX} ]] || abort "build prefix not found, is ${SYSTEMVARS}/system_vars.yml missing?"

CORENUM=`get-config ${DNAME}/core-image-to-use.yml core_number`
[[ -z ${CORENUM} ]] && CORENUM="missing"

DDNS=`get-config ${SYSTEMVARS} include_ddns`
[[ ${DDNS} ]] || abort "include_ddns not found, is ${SYSTEMVARS} missing?"

OVPN=`get-config ${SYSTEMVARS} include_ovpn`
[[ ${OVPN} ]] || abort "include_ovpn not found, is ${SYSTEMVARS} missing?"

VPN=`get-config ${SYSTEMVARS} include_vpn`
[[ ${VPN} ]] || abort "include_vpn not found, is ${SYSTEMVARS} missing?"

HOST=`get-config ${SYSTEMVARS} green_host`
[[ ${HOST} ]] || abort "include_vpn not found, is ${SYSTEMVARS} missing?"

TESTHOST=`get-config ${SYSTEMVARS} green_testhost`
[[ ${TESTHOST} ]] || abort "include_vpn not found, is ${SYSTEMVARS} missing?"

if [[ ${NODE} -ne 0 ]]
then
	FWRULES=`get-config ${CONFIG}/${PREFIX}${NODE}_vars.yml include_fwrules`
	[[ -z ${FWRULES} ]] && FWRULES=`get-config ${SYSTEMVARS} include_fwrules`
	[[ ${FWRULES} ]] || abort "include_fwrules not found, is ${SYSTEMVARS} missing?"
fi

show ${NODE}

exit 0
