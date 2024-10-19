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
# FireMyPi:  mk-ddns-secret.sh
#

#
# Create secret file with Dynamic DNS credentials.
# Check config/system_vars.yml for the auth method and prompt accordingly.
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
	echo -e "# FireMyPi Dynamic DNS configuration secret file" >> ${1}
	echo -e "# created with mk-ddns-secret.sh by:" >> ${1}
	echo -e "#" >> ${1}
	echo -e "#   user: ${USER}" >> ${1}
	echo -e "#   date: ${DATE}" >> ${1}
	echo -e "#\n" >> ${1}
	echo -e "    ddns_provider: \"${2}\"" >> ${1}
	echo -e "    ddns_token: \"${3}\"" >> ${1}
	echo -e "    ddns_username: \"${4}\"" >> ${1}
	echo -e "    ddns_password: \"${5}\"" >> ${1}
	echo -e "    ddns_keyid: \"${6}\"" >> ${1}
	echo -e "" >> ${1}
	echo -e "..." >> ${1}
}

SECRETFILE="secrets/ddns-secret.yml"
PROVIDER="PROVIDER.COM"
TOKEN="TOKEN"
USER="USERNAME"
PASS="PASSWORD"
KEYID="99999"

#### Parse args
while [[ $# -gt 0 ]]
do
        case $1 in
                --secretfile)
                        shift
                        SECRETFILE=$1
                        ;;
                *)
			echo "Usage:  mk-ddns-secret.sh (--secretfile OUTPUT_FILE)"
                        exit 0
                        ;;
        esac
        shift
done

clear
header Dynamic DNS Secret

echo -e "Create Dynamic DNS secret file in:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"
echo -e "The same Dynamic DNS secret file will be used for all nodes.\n"

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
		echo -e "\nBacked up current file to:  ddns-secret.yml.save${DATE}${TIME}\n"
	fi
fi

# Check ddns_auth_method

AUTH=`get-config ${SYSTEMVARS} ddns_auth_method`

case "${AUTH}" in
        token)
		echo -e "Configuring for ${AUTH} authentication method.\n"
		# Prompt for provider and verify.
		PR="NONE"
		PR1="None"
		while [[ "${PR}" != "${PR1}" ]]
		do
			read -p "Enter Dynamic DNS provider:   " PR
			#printf "\n"
			read -p "Verify Dynamic DNS provider:  " PR1
			if [[ "${PR}" != "${PR1}" ]]
			then
				echo "Verification failed."
			fi
		done
		PROVIDER=${PR}
		echo ""

		# Prompt for token and verify.
		TK="NONE"
		TK1="None"
		while [[ "${TK}" != "${TK1}" ]]
		do
			read -p "Enter Dynamic DNS token:      " TK
			read -p "Verify token:                 " TK1
			if [[ "${TK}" != "${TK1}" ]]
			then
				echo -e "Verification failed."
			fi
		done
		TOKEN=${TK}
		echo ""
                ;;

        userpass)
		echo -e "Configuring for ${AUTH} authentication method.\n"
		# Prompt for provider and verify.
		PR="NONE"
		PR1="None"
		while [[ "${PR}" != "${PR1}" ]]
		do
			read -p "Enter Dynamic DNS provider:   " PR
			#printf "\n"
			read -p "Verify Dynamic DNS provider:  " PR1
			if [[ "${PR}" != "${PR1}" ]]
			then
				echo "Verification failed."
			fi
		done
		PROVIDER=${PR}
		echo ""

		# Prompt for username and verify.
		UN="NONE"
		UN1="None"
		while [[ "${UN}" != "${UN1}" ]]
		do
			read -p "Enter Dynamic DNS username:   " UN
			read -p "Verify username:              " UN1
			if [[ "${UN}" != "${UN1}" ]]
			then
				echo -e "Verification failed."
			fi
		done
		USER=${UN}
		echo ""

		# Prompt for password and verify.
		PW="NONE"
		PW1="None"
		while [[ "${PW}" != "${PW1}" ]]
		do
			read -ps "Enter Dynamic DNS password:   " PW
			read -ps "Verify password:              " PW1
			if [[ "${PW}" != "${PW1}" ]]
			then
				echo -e "Verification failed."
			fi
		done
		PASS=${PW}
		echo ""
                ;;

        keypair)
		echo -e "Configuring for ${AUTH} authentication method.\n"
		COUNT=`ls secrets/K*+157+* 2>/dev/null | wc -l`
		if [[ ${COUNT} == 0 ]]
		then
cat << HERE
No HMAC-MD5 keys found in 'secrets'.  Copy your HMAC-MD5 'key' and 'private'
files to the 'secrets' directory and re-run 'mk-ddns-secret.sh'.

HERE
			abort "No HMAC-MD5 key files found in 'secrets'."
		elif [[ ${COUNT} == 2 ]]
		then
			echo -e "HMAC-MD5 key files found in 'secrets':\n"
			ls -1 ${SECRETS}/K*+157+*
			KEYID=`ls -1 ${SECRETS}/K*+157+* | head -n 1`
			KEYID=`basename ${KEYID} | cut -d+ -f3 | cut -d. -f1`
			echo -e "\nThe keyid will be set to: ${KEYID}"
		else
			echo -e "HMAC-MD5 key files found in 'secrets':\n"
			ls -1 ${SECRETS}/K*+157+*
cat << HERE
Expecting 2 HMAC-MD5 key files in 'secrets' but found ${COUNT}.  Make sure
that there is one HMAC-MD5 'key' file and one HMAC-MD5 'private' file in
the 'secrets' directory and re-run 'mk-ddns-secret.sh'.

HERE
			abort "Too many HMAC-MD5 key files in 'secrets'."
		fi
		echo ""
                ;;

        *)
		abort "no auth method has been chosen"
                ;;
esac

create-secretfile ${SECRETFILE}

write-secretfile ${SECRETFILE} ${PROVIDER} ${TOKEN} ${USER} ${PASS} ${KEYID}

echo -e "Dynamic DNS secret file written to:\n"
echo -e "${GRN}    ${SECRETFILE}${NC}\n"

echo -e "Done."
exit 0
