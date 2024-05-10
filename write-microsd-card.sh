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
# FireMyPi:	write-microsd-card.sh
#

#
# Show instruction for writing micro sd card from command line.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
        echo "Wrong directory - change to build directory and retry"
        exit 1
fi

source fmp-common

clear
header Write Micro SD Card

echo -e "How to write your image to a micro sd card:\n"
echo -e "${GRN}    Use rpi-imager!${NC}\n"
echo -e "Seriously, use rpi-imager.  It just works.\n"
echo -e "If for some reason rpi-imager is not available, you can write the"
echo -e "image from the command line with 'dd':\n"
echo -e "${RED}    sudo dd if={image} of={device} bs=4M conv=fsync status=progress\n${NC}"
echo -e "If you decide to use 'dd' be sure that you're writing to the correct"
echo -e "device for the micro sd card and that the card has nothing mounted"
echo -e "or in use.  After writing, eject the card before removing it.\n"

echo -e "Done."
exit 0
