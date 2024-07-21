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
# FireMyPi:  portable-util.sh
#

#
# Use a portable FireMyPi build and downloaded IPFire core image to
# to create a bootable FireMyPi image.
#

TEST_PROD="NONE"

while [[ $# -gt 0 ]]
do
        case $1 in
		--test)
			if [[ ${TEST_PROD} == "NONE" ]]
			then
				TEST_PROD=test
			else
				echo "Only one of --test --prod allowed."
				echo "Aborting."
				exit 1
			fi
			;;
		--prod)
			if [[ ${TEST_PROD} == "NONE" ]]
			then
				TEST_PROD=prod
			else
				echo "Only one of --test --prod allowed."
				echo "Aborting."
				exit 1
			fi
			;;
                -h|--help)
			echo "Copy FireMyPi portable build and IPFire image to the same directory"
			echo "then run 'portable-util.sh (--test|--prod)'."
			exit 0
                        ;;

		*)
                        echo "invalid option '$1'"
			exit 1
                        ;;
        esac
        shift
done

if [[ ${TEST_PROD} == "NONE" ]]
then
	echo "Must set --test or --prod"
	echo "Aborting."
	exit 1
fi

PORTABLE=`ls firemypi-core*-portable-${TEST_PROD}-*.tgz 2>/dev/null`

if [[ -z ${PORTABLE}  ]]
then
	echo "No FireMyPi portable ${TEST_PROD^^} build file found in current directory."
	echo "This script must be run in a directory that has both a"
	echo "FireMyPi portable build file and an IPFire aarch64 flash"
	echo "image with the same core number."
	echo "Aborting."
	exit 1
else
	echo "Found FireMyPi portable build file:  ${PORTABLE}"
fi

CORENUM=`ls ${PORTABLE} | cut -d- -f2 | cut -de -f2`

NODEID=`ls ${PORTABLE} | cut -d- -f3`

TESTPROD=`ls ${PORTABLE} | cut -d- -f5`

DATE=`ls ${PORTABLE} | cut -d- -f6 | cut -d. -f1`

COREIMAGEZ=`ls ipfire-*-core${CORENUM}-aarch64.img.xz 2>/dev/null`

if [[ -z ${COREIMAGEZ} ]]
then
	echo "No matching image for core number ${CORENUM} found in current directory."
	echo "This script must be run in a directory that has both a"
	echo "FireMyPi portable build file and an IPFire aarch64 flash"
	echo "image with the same core number."
	echo "Aborting."
	exit 1
else
	echo "Found matching core image file:  ${COREIMAGEZ}"
fi

echo "Extracting core image..."
unxz -kf ${COREIMAGEZ}

COREIMAGE=`ls ipfire-*-core${CORENUM}-aarch64.img 2>/dev/null`

echo "Setting up loop device..."
LOOP=`sudo losetup --partscan --find --show ${COREIMAGE}`

sudo mkdir p1 p3

echo "Mounting p1..."
sudo mount ${LOOP}p1 p1

echo "Mounting p3..."
sudo mount ${LOOP}p3 p3

echo "Applying FireMyPi portable build to image..."
sudo tar -xvf ${PORTABLE} &>/dev/null

echo "Unmounting p1 and p3..."
sudo umount p1 p3

sudo rmdir p1 p3

echo "Destroying loop device..."
sudo losetup -d ${LOOP}

echo "Finalizing..."
mv ${COREIMAGE} firemypi-core${CORENUM}-${NODEID}-image-${TESTPROD}-${DATE}.img

echo -e "\nfiremypi-core${CORENUM}-${NODEID}-image-${TESTPROD}-${DATE}.img created...\n"
echo -e "Use rpi-imager to write the FireMyPi/IPFire image to a micro SD card.\n"

echo "Done."
