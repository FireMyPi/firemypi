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
# FireMyPi:  mk-wireless-secret.sh
#

#
# Create a 'secrets/nodeN-wireless-secret.yml' file for a node that will
# use the Raspberry Pi wireless nic as the red0 interface.
#
# The script takes a node number as an argument and will prompt for
# the SSID and passphrase of the wireless network for red0 to connect.
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
SSID="NONE"
PASSPHRASE="NONE"
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
header Wireless Configuration File Creation

while [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
do
	read -p "Enter a node number between '1' and '254': " NODE
	if [[ ${NODE} -ge 1 ]] || [[ ${NODE} -le 254 ]]
	then
		echo ""
	fi
done

NODE=$((10#${NODE}))
NODEFILE="${PREFIX}${NODE}_wireless-secret.yml"

echo -e "Create wireless configuration file in 'secrets' directory:\n"
echo -e "\t${GRN}${NODEFILE}${NC}\n"

if [[ -e ${SECRETS}/${NODEFILE} ]]
then
	echo -e "${RED}*** WARNING ***${NC}\n"
	echo -e "\t${RED}secrets/${NODEFILE} already exists${NC}\n"
	echo -e "Do you want to overwrite ${NODEFILE}?\n"
	read -p "Type 'yes' to overwrite the node configuration file: " YES
	if [[ ${YES} != "yes" ]]
	then
		echo -e "\nCancelled.\n"
		exit 1
	else
		cp ${SECRETS}/${NODEFILE} "${SECRETS}/${NODEFILE}.save${DATE}${TIME}"
		echo -e "\nBacked up current file to:  ${PREFIX}${NODE}_vars.yml.save${DATE}${TIME}\n"
	fi
fi

# Prompt for SSID and verify before writing to file.
while [[ ${SSID} == "NONE" ]]
do
        read -p "Enter SSID for wireless configuration file: " SSID
        read -p "Re-enter SSID: " SSID1
        if [[ "${SSID}" != "${SSID1}" ]]
        then
                echo -e "\n${RED}ERROR: SSID's don't match.${NC}\n"
                SSID="NONE"
        fi
        if [[ -z ${SSID} ]]
        then
                echo -e "\n\n${RED}ERROR: Blank SSID not allowed for wireless configuration file.${NC}\n"
                SSID="NONE"
        fi
done

echo -e ""
# Prompt for PASSPHRASE and verify before writing to file.
while [[ ${PASSPHRASE} == "NONE" ]]
do
        read -sp "Enter WPA2 passphrase for wireless configuration file: " PASSPHRASE
        echo ""
        read -sp "Re-enter WPA2 passphrase: " PASSPHRASE1
        if [[ "${PASSPHRASE}" != "${PASSPHRASE1}" ]]
        then
                echo -e "\n\n${RED}ERROR: Passphrases don't match.${NC}\n"
                PASSPHRASE="NONE"
        fi
        if [[ -z ${PASSPHRASE} ]]
        then
                echo -e "\n\n${RED}ERROR: Blank WPA2 passphrase not allowed for wireless configuration file.${NC}\n"
                PASSPHRASE="NONE"
        fi
done

echo -e ""

create-secretfile ${SECRETS}/${NODEFILE}

cat << HERE >> ${SECRETS}/${NODEFILE}
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
# Version:   v1.5
# Date:      Sat Oct 12 12:48:47 2024 -0600
#

#
# FireMyPi:  ${NODEFILE}
#

#
# Wireless configuration for red0 for ${PREFIX}${NODE}.
#

    # The SSID of the wireless network to which red0 will connect.
    wireless_ssid: "${SSID}"

    # The WPA2 passphrase of the wireless network to which red0 will connect.
    wireless_passphrase: "${PASSPHRASE}"

...
HERE

echo -e "\nWireless configuration written to:\n"
echo -e "\t${GRN}${NODEFILE}${NC}\n"

echo -e "Done."
exit 0
