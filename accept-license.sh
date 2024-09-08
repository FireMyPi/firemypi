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
# FireMyPi:  accept-license.sh
#

#
# Prompt for acceptance of License for FireMyPi.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common

LICENSEFILE="$DNAME/LICENSE"
ACCEPTFILE="$DNAME/license.accepted"
YES=""
YES1=""

clear
header License Acceptance

echo -e "${CYA}"
echo -e "Copyright © 2020-2024 David Čuka and Stephen Čuka All Rights Reserved.\n"
echo -e "FireMyPi is licensed under the Creative Commons Attribution-NonCommercial-"
echo -e "NoDerivatives 4.0 International License (CC BY-NC-ND 4.0).\n"
echo -e "The full text of the license can be found in the included LICENSE file "
echo -e "or at https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode.en.\n"
echo -e "For the avoidance of doubt, FireMyPi is for personal use only and may not "
echo -e "be used by or for any business in any way.\n"
echo -e "${NC}"

echo -e "In order to use FireMyPi to build IPFire nodes, you must accept"
echo -e "the License.\n"

echo -e "Press <Enter> to view the license, 'q' when done viewing:\n"
read -s
less ${LICENSEFILE}

while [[ -z ${YES} ]]
do
	read -p "Type 'yes' to accept the license: " YES
done

if [[ ${YES} = "yes" ]]
then
	echo -e "${CYA}"
	echo -e "For the avoidance of doubt, FireMyPi is for personal use only and may not "
	echo -e "be used by or for any business in any way."
	echo -e "${NC}"
    else
        echo -e "\n${RED}License not accepted. You must accept the license to use FireMyPi.${NC}"
	echo -e "\nDone.\n"
	exit 1
fi

while [[ -z ${YES1} ]]
do
	read -p "Type 'yes' to indicate your understanding: " YES1
done

if [[ ${YES} = "yes" && ${YES1} = "yes" ]]
    then
        USER=`whoami`
        DATE=`date`
	HOST=`hostname`
	MAC=`ip --brief link | grep -v "lo " | grep -v DOWN | awk '{print $3}'`
        echo -e "FireMyPi is licensed under the Creative Commons Attribution-NonCommercial-\nNoDerivatives 4.0 International License (CC BY-NC-ND 4.0).\n\nThe full text of the license can be found in the included LICENSE file \nor at https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode.en.\n\nFor the avoidance of doubt, FireMyPi is for personal use only and may not \nbe used by or for any business in any way.\n" > $ACCEPTFILE
        echo -e "FireMyPi license accepted by:\n" >> $ACCEPTFILE
        echo -e "        User:  $USER" >> $ACCEPTFILE
        echo -e "        Date:  $DATE" >> $ACCEPTFILE
        echo -e "        Host:  $HOST" >> $ACCEPTFILE
        echo -e "        MAC:   $MAC\n" >> $ACCEPTFILE
#        echo -e "\nFireMyPi is licensed under the Creative Commons Attribution-NonCommercial-\nNoDerivatives 4.0 International License (CC BY-NC-ND 4.0).\n\nFor the avoidance of doubt, FireMyPi is for personal use only and may not \nbe used by or for any business in any way.\n"
        echo -e "\nFireMyPi license accepted by:\n"
        echo -e "        User:  ${GRN}$USER${NC}"
        echo -e "        Date:  ${GRN}$DATE${NC}"
        echo -e "        Host:  ${GRN}$HOST${NC}"
        echo -e "        MAC:   ${GRN}$MAC${NC}"
    else
        echo -e "\n${RED}License not accepted. You must accept the license to use FireMyPi.${NC}"
	echo -e "\nDone.\n"
	exit 1
fi


echo -e "\nDone.\n"
exit 0
