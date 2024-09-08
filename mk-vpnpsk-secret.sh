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
# Version:   v1.4
# Date:      Sat Sep 7 19:54:36 2024 -0600
#

#
# FireMyPi:  mk-vpnpsk-secret.sh
#

#
# Create vpn pre-shared key for ipsec vpn tunnels with pwgen.
# Once created, the same vpn psk will be used for all nodes.
#
# By default, mk-vpnpsk-secret.sh will write to file
# secrets/vpnpsk-secret.yml and create a backup of the current
# file if it exists.  A different file may be specified on the
# command line if desired.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
        echo "Wrong directory - change to build directory and retry"
        exit 1
fi

source fmp-common

SECRET="NONE"
SECRETFILE="secrets/vpnpsk-secret.yml"

# Check if pwgen missing.
if ! pwgen-check
then
	echo "pwgen not found - install using 'sudo apt install pwgen'"
	exit 1
fi

#### Parse args
while [[ $# -gt 0 ]]
do
        case $1 in
                --secretfile)
                        shift
                        SECRETFILE=$1
                        ;;
                *)
			echo "Usage:  mk-vpnpsk-secret.sh (--secretfile OUTPUT_FILE)"
                        exit 0
                        ;;
        esac
        shift
done


clear
echo -e "${RED}FireMyPi VPN Pre-Shared Key Secret${NC}\n"
echo -e "Create Ipsec VPN pre-shared key in:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"
echo -e "The same Ipsec VPN pre-shared key will be used for all nodes.\n"

if [[ -e ${SECRETFILE} ]]
then
	echo -e "${RED}*** WARNING ***${NC}\n"
	echo -e "${RED}    ${SECRETFILE} already exists${NC}\n"
	echo -e "Do you want to overwrite ${SECRETFILE}?\n"
	read -p "Type 'yes' to overwrite the secret file: " YES
        if [[ ${YES} != "yes" ]]
        then
                echo -e "\nCancelled.\n"
                exit 1
        else
                cp ${SECRETFILE} "${SECRETFILE}.save${DATE}${TIME}"
                echo -e "\nBacked up current file to:  vpnpsk-secret.yml.save${DATE}${TIME}\n"
        fi
fi

# Use pwgen to create the psk.
SECRET=`pwgen -s 64 1`
if [[ -z ${SECRET} ]]
then
	echo -e "\nERROR: ${SECRETFILE} not written."
	exit 1
fi

create-secretfile ${SECRETFILE}

# Write the secret file.
USER=`whoami`
DATE=`date`
cat << HERE >> ${SECRETFILE}
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
# Version:   v1.4
# Date:      Sat Sep 7 19:54:36 2024 -0600
#

#
# FireMyPi:  vpnpsk-secret.yml
#

#
# FireMyPi Ipsec VPN pre-shared key file
# created with mk-vpnpsk-secret.sh by:
#
#   user: ${USER}
#   date: ${DATE}
#

    vpn_psk: "${SECRET}"

...
HERE

echo -e "\nIpsec VPN pre-shared key written to:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"

echo -e "Done."
exit 0
