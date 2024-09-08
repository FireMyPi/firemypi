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
# FireMyPi:  mk-root-secret.sh
#

#
# Create root secret file with a password entered on
# the command line.  Once created, the same root password
# will be used for all nodes.
#
# By default, mk-root-secret.sh will write to file
# secrets/root-secret.yml and create a backup of the current
# file if it exists.  A different file may be specified on
# the command line if desired.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
        echo "Wrong directory - change to build directory and retry"
        exit 1
fi

source fmp-common

SECRET="NONE"
SECRETFILE="secrets/root-secret.yml"

# Check if openssl missing.
if ! openssl-check
then
	echo "openssl not found - install using 'sudo apt install openssl'"
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
			echo "Usage:  mk-root-secret.sh (--secretfile OUTPUT_FILE)"
                        exit 0
                        ;;
        esac
        shift
done


clear
header Root Secret

echo -e "Create root password in:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"
echo -e "The same root password will be used for all nodes.\n"

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
                echo -e "\nBacked up current file to:  root-secret.yml.save${DATE}${TIME}\n"
        fi
fi

# Use openssl to prompt for password and create the hash.
while [[ ${SECRET} == "NONE" ]]
do
	echo -e "Enter root password:\n"
	SECRET=`openssl passwd -6`
	if [[ -z ${SECRET} ]]
	then
		echo -e "\n${RED}ERROR: Passwords don't match.${NC}\n"
		SECRET="NONE"
	fi
	if [[ ${SECRET} == "<NULL>" ]]
	then
		echo -e "\n${RED}ERROR: Blank password not allowed for root.${NC}\n"
		SECRET="NONE"
	fi
done

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
# FireMyPi:  root-secret.yml
#

#
# FireMyPi root password file
# created with mk-root-secret.sh by:
#
#   user: ${USER}
#   date: ${DATE}
#

    rootsecret: "${SECRET}"

...
HERE

echo -e "\nRoot password written to:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"

echo -e "Done."
exit 0
