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
# FireMyPi:  mk-webadmin-secret.sh
#

#
# Create the 'webadmin-secret.yml' file with a password entered on
# the command line.  Once created, the same admin password
# will be used for all nodes.
#
# By default, mk-webadmin-secret.sh will write to file
# secrets/webadmin-secret.yml and create a backup of the current
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

function write-secretfile()
{
	# Write the secret file.
	USER=`whoami`
	DATE=`date`
	echo -e "---" >> ${1}
	echo -e "" >> ${1}
	echo -e "#" >> ${1}
	echo -e "# FireMyPi IPFire Web GUI admin password" >> ${1}
       	echo -e "# created with mk-webadmin-secret.sh by:" >> ${1}
	echo -e "#" >> ${1}
	echo -e "#   user: ${USER}" >> ${1}
	echo -e "#   date: ${DATE}" >> ${1}
	echo -e "#\n" >> ${1}
	echo -e "    webadminsecret: \"${2}\"" >> ${1}
	echo -e "" >> ${1}
	echo -e "..." >> ${1}
}

SECRET="NONE"
SECRETFILE="secrets/webadmin-secret.yml"

# Check if htpasswd missing.
if ! apache2-utils-check
then
	echo "htpasswd not found - install using 'sudo apt install apache2-utils'"
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
			echo "Usage:  mk-webadmin-secret.sh (--secretfile OUTPUT_FILE)"
                        exit 0
                        ;;
        esac
        shift
done


clear
header IPFire Web GUI admin User Secret

echo -e "Create IPFire Web GUI admin password in:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"
echo -e "The same admin password will be used for all nodes.\n"

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
                echo -e "\nBacked up current file to:  webadmin-secret.yml.save${DATE}${TIME}\n"
        fi
fi

# Prompt for password and verify before creating the hash.
while [[ ${SECRET} == "NONE" ]]
do
        read -sp "Enter the IPFire Web GUI admin password: " SECRET
        echo ""
        read -sp "Re-enter password: " SECRET1
        if [[ "${SECRET}" != "${SECRET1}" ]]
        then
                echo -e "\n\n${RED}ERROR: Passwords don't match.${NC}\n"
                SECRET="NONE"
        fi
        if [[ -z ${SECRET} ]]
        then
                echo -e "\n\n${RED}ERROR: Blank password not allowed for IPFire Web GUI admin.${NC}\n"
                SECRET="NONE"
        fi
done

SECRET=`echo ${SECRET} | htpasswd -B -n -i admin`
RC=$?
if [[ ${RC} != 0 ]]
then
	echo -e "\n\n${RED}ERROR: htpasswd returned error code ${RC}.\n${NC}"
	exit 1
fi

SECRET=`echo ${SECRET} | cut -d: -f2`
if [[ -z ${SECRET} ]]
then
	echo -e "\nERROR: ${SECRETFILE} not written."
	exit 1
fi

create-secretfile ${SECRETFILE}

write-secretfile ${SECRETFILE} ${SECRET}

echo -e "\n\nIPFire Web GUI admin password written to:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"

echo -e "Done."
exit 0
