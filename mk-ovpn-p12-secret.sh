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
# FireMyPi:  mk-ovpn-p12-secret.sh
#

#
# Create secret file with a password entered on the command line.
# The ovpn-p12-secret is used to password protect the pkcs12
# certificate files for road warriors.
#
# By default, mk-ovpn-p12-secret.sh will write to the 
# secrets/ovpn-p12-secret.yml file and create a backup of the current
# file if it exists.  A different file may be specified on the command
# line if desired.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
        echo "Wrong directory - change to build directory and retry"
        exit 1
fi

source fmp-common

function write-secretfile()
{
	# Write the secret file.
	USER=`whoami`
	DATE=`date`
	echo -e "---" > ${1}
	echo -e "" >> ${1}
	echo -e "#" >> ${1}
	echo -e "# FireMyPi OpenVPN p12 certificate file password" >> ${1}
	echo -e "# created with mk-ovpn-p12-secret.sh by:" >> ${1}
	echo -e "#" >> ${1}
	echo -e "#   user: ${USER}" >> ${1}
	echo -e "#   date: ${DATE}" >> ${1}
	echo -e "#\n" >> ${1}
	echo -e "    ovpn_p12_password: \"${2}\"" >> ${1}
	echo -e "" >> ${1}
	echo -e "..." >> ${1}
}


SECRET="NONE"
SECRETFILE="secrets/ovpn-p12-secret.yml"


#### Parse args
while [[ $# -gt 0 ]]
do
        case $1 in
                --secretfile)
                        shift
                        SECRETFILE=$1
                        ;;
                *)
			echo "Usage:  mk-ovpn-p12-secret.sh (--secretfile OUTPUT_FILE)"
                        exit 0
                        ;;
        esac
        shift
done

clear
header OpenVPN p12 Certificate File Secret

echo -e "Create OpenVPN p12 file password in:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"
echo -e "The same p12 file password will be used for all nodes.\n"

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
		echo -e "\nBacked up current file to:  ovpn-p12-secret.yml.save${DATE}${TIME}\n"
	fi
fi

# Prompt for password and verify before writing to file.
while [[ ${SECRET} == "NONE" ]]
do
	read -sp "Enter password for OpenVPN p12 certificate files: " SECRET
	echo ""
	read -sp "Re-enter password: " SECRET1
	if [[ "${SECRET}" != "${SECRET1}" ]]
	then
		echo -e "\n\n${RED}ERROR: Passwords don't match.${NC}\n"
		SECRET="NONE"
	fi
	if [[ -z ${SECRET} ]]
	then
		echo -e "\n\n${RED}ERROR: Blank password not allowed for ovpn p12 files.${NC}\n"
		SECRET="NONE"
	fi
done

echo -e ""

create-secretfile ${SECRETFILE}

write-secretfile ${SECRETFILE} ${SECRET}

echo -e "\nOpenVPN p12 certificate file password written to:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"

echo -e "Done."
exit 0
