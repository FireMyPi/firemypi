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
# Version:   v1.3
# Date:      Thu Aug 1 21:20:37 2024 -0600
#

#
# FireMyPi:  firemypi-walkthrough.sh
#

#
# Perform a walkthrough of the FireMyPi build process.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common

function walkthrough()
{
	header Walkthrough $*
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


NODE=0
COUNT=0
FILE="NONE"
PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ ${PREFIX} ]] || abort "build prefix not found in ${SYSTEMVARS}"
TESTHOST=`get-config ${SYSTEMVARS} green_testhost`


clear
walkthrough - Introduction

cat <<- HERE
	This script is a walkthrough of the necessary steps to configure and build
	a FireMyPi/IPFire firewall.  Each step is described before running it and
	the end result will be the creation of an image file that can be written
	to a micro sd card and booted on your Raspberry Pi.

	This script is not a replacement for reading the full documentation, but
	if you would like to get a quick start and see what FireMyPi does, this
	script will do that.

	This script assumes that your system has 'apt' installed as the package
	manager and that the IPFire core image file has already been downloaded.
	If your system does not use 'apt' as a package manager, you will need to
	install the required packages before running this walkthrough.

	You can use <Ctrl-C> to exit this script.  If you exit and restart the 
	walkthrough, you will not have to redo steps that you've already completed.

	If you would like to start over from scratch, you can run './clean.sh --ALL'
	to reset the build environment.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough - show-build-environment.sh

cat <<- HERE
	Let's start by running the './show-build-environment.sh' script to take a
	look at the current status of the build environment.

	The command that will be run for this step is:
HERE

echo -e "\n${GRN}\t./show-build-environment.sh${NC}\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

./show-build-environment.sh

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough - show-build-environment.sh

cat <<- HERE
	The previous './show-build-environment.sh' command gives you a dashboard of
	the current status of the build environment.  The './show-build-environment.sh'
	command is a good way to keep track of where you are in the build process.

	Items that are listed as 'missing' are required in order to run a build.
	Items that are listed as 'missing - optional' are for optional FireMyPi
	features that are not enabled by default.  Refer to the FireMyPi
	Administrator's Guide 'doc/fmp-admin-guide.html' for more information
	on optional features.

	If run without any arguments, './show-build-environment.sh' will give the 
	global status of the build environment.  If you include the '--node'
	argument, as in './show-build-environment --node 1', the status of the node
	specified will be displayed.

	Let's continue on with the first step of the build process.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough Step 1 - Install Required Packages

cat << HERE
The first step in building a FireMyPi/IPFire firewall is to install the
packages necessary for the build.  These are:

	ansible		used as the build engine
	apache2-utils	for creating the IPFire Web GUI admin password
	openssl		for creating the root password and OpenVPN certificates
	pwgen		for creating the Ipsec VPN pre-shared key
	u-boot-tools	for modifying u-boot for the Raspberry Pi 4B

The command that will be run for this step is:
HERE

echo -e "\n${GRN}\tsudo apt install --yes ansible apache2-utils openssl pwgen u-boot-tools${NC}\n"

cat << HERE
This command will install the packages listed above if they are not already
installed.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough Step 1 - Install Required Packages

if ansible-check && apache2-utils-check && openssl-check && pwgen-check && u-boot-tools-check
then
	cat << HERE
The required packages are already installed.

So we can skip this step.

HERE
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
else
	echo "sudo apt install --yes ansible apache2-utils openssl pwgen u-boot-tools"
	sudo apt install --yes ansible apache2-utils openssl pwgen u-boot-tools
	if [ $? -eq 0 ]
	then
		echo ""
		read -p "Previous step complete, press <Enter> to continue: "
	else
		echo -e "\nPrevious step failed."
		abort Failed to install required packages.
	fi
fi

clear
walkthrough Step 2 - Prepare Image

cat << HERE
Now that the packages necessary for the build are installed, the build
environment needs to be prepared to build FireMyPi/IPFire firewalls.  To 
do this, the IPFire core image file that will be used for the builds needs
to be moved into the build environment.

If you have not already downloaded an aarch64 Flash Image from the IPFire
website, use <Ctrl-C> to exit this script and do that first.

The command that will be run for this step is:
HERE

echo -e "\n${GRN}\t./get-image-from-Downloads.sh${NC}\n"

cat << HERE
Note that this command expects to find the IPFire Flash Image in the 
'~/Downloads' directory.  If the image file that you have downloaded is
not in this directory, you will need to enter the correct directory when
the script runs.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

COUNT=`ls image/ipfire*-aarch64.img 2>/dev/null | wc -l`
if [[ ${COUNT} != 0 ]] && [[ -e "core-image-to-use.yml" ]]
then
	clear
	walkthrough Step 2 - Prepare Image
	echo -e "You already have a core image in the 'image' directory:\n"
	FILE=`ls image/ipfire*-aarch64.img`
	FILE=`basename ${FILE}`
	echo -e "\t${GRN}${FILE}${NC}\n"
	cat << HERE
So we can skip this step.

If you want to replace the core image in the future, just
run './get-image-from-Downloads.sh' from the command line.

HERE
	read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
else
	./get-image-from-Downloads.sh
	if [ $? -eq 0 ]
	then
		echo ""
		read -p "Previous step complete, press <Enter> to continue: "
	else
		echo -e "\nPrevious step failed."
		abort Failed to copy image file from download directory.
	fi
fi

clear
walkthrough - show-build-environment.sh

cat << HERE
Now that we have the required packages installed and a core image moved
into the build environment, let's run './show-build-environment.sh' again.

On the './show-build-environment.sh' dashboard, you will see that the
required packages and core image related items are now green.

You may see that there are some 'missing' items in red that we need
to attend to.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

./show-build-environment.sh

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough Step 3 - Configure Root Password

cat << HERE
Next we need to create a root password that will allow you to log on to
the firewall either locally at the console or through SSH.

This step will prompt you for the root password and store it as a password
hash in the 'secrets' directory where it will be used for the build.

The same root password will be used for all nodes built by FireMyPi.  If
you are in a single node configuration, this probably doesn't matter, but
in a multiple node configuration, you will be able to access all of the 
firewalls that you build with the same password.

The command that will be run for this step is:
HERE

echo -e "\n${GRN}\t./mk-root-secret.sh${NC}\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

if [[ -e "secrets/root-secret.yml" ]]
then
	clear
	walkthrough Step 3 - Configure Root Password
	echo -e "You already have a root password in the 'secrets' directory:\n"
	FILE=`ls secrets/root-secret.yml`
	FILE=`basename ${FILE}`
	#FILE=`ls secrets/root-secret.yml | head -n 1 | rev | cut -d / -f 1 | rev`
	echo -e "\t${GRN}${FILE}${NC}\n"
	cat << HERE
So we can skip this step.

If you want to change the root password in the future,
just run './mk-root-secret.yml' from the command line.

HERE
	read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
else
	./mk-root-secret.sh
	if [ $? -eq 0 ]
	then
		echo ""
		read -p "Previous step complete, press <Enter> to continue: "
	else
		echo -e "\nPrevious step failed."
		abort Failed to create root password file.
	fi
fi

clear
walkthrough Step 4 - Create Admin Password

cat << HERE
Now we need to create a password for the 'admin' user that will be used
to log on to the IPFire Web GUI.

This step will prompt you for the IPFire Web GUI admin password and store
it as a password hash in the 'secrets' directory where it will be used
for the build.

The same IPFire Web GUI admin password will be used for all nodes built by 
FireMyPi.  If you are in a single node configuration, this probably doesn't
matter, but in a multiple node configuration, you will be able to access all
of the firewalls that you build with the same password.

The command that will be run for this step is:
HERE

echo -e "\n${GRN}\t./mk-webadmin-secret.sh${NC}\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

if [[ -e "secrets/webadmin-secret.yml" ]]
then
	clear
	walkthrough Step 4 - Create Admin Password
	echo -e "You already have an IPFire Web GUI admin password in the 'secrets' directory:\n"
	FILE=`ls secrets/webadmin-secret.yml`
	FILE=`basename ${FILE}`
	#FILE=`ls secrets/webadmin-secret.yml | head -n 1 | rev | cut -d / -f 1 | rev`
	echo -e "\t${GRN}${FILE}${NC}\n"
	cat << HERE
So we can skip this step.

If you want to change the IPFire Web GUI admin password in the future,
just run './mk-webadmin-secret.yml' from the command line.

HERE
	read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
else
	./mk-webadmin-secret.sh
	if [ $? -eq 0 ]
	then
		echo ""
		read -p "Previous step complete, press <Enter> to continue: "
	else
		echo -e "\nPrevious step failed."
		abort Failed to create admin password file.
	fi
fi

clear
walkthrough Step 5 - Create Node Configuration

cat << HERE
We're almost ready to go!

The last thing that we need to do is to create a node configuration file
for the node that we're going to build.  To do this we need to select a
node number.

FireMyPi uses the node number to determine which '192.168.0.0/24' subnet
to build.  For example, if you choose node number '123' in this walkthrough,
FireMyPi will build a test firewall for subnet '192.168.123.0/24' with
IP address '192.168.123.${TESTHOST}'.  If needed, the default test host number
can be changed by editing the 'green_testhost:' variable in
'config/system_vars.yml'.

For this walkthrough, enter the node number that matches your home subnet so
that you can access the test firewall directly from your home subnet.

HERE

while [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
do
        read -p "Enter a node number between '1' and '254': " NODE
done

echo ""
echo -e "You've entered node number ${CYA}${NODE}${NC}.  This will build a test firewall with IP"
echo -e "address ${CYA}'192.168.${NODE}.${TESTHOST}'${NC} for subnet ${CYA}'192.168.${NODE}.0/24'${NC}."
echo ""

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough Step 5 - Create Node Configuration

if [[ -e "${CONFIG}/${PREFIX}${NODE}_vars.yml" ]]
then
	echo -e "You already have a node configuration file for node ${CYA}${NODE}${NC} in the"
	echo -e "'config' directory:\n"
	FILE=`ls ${CONFIG}/${PREFIX}${NODE}_vars.yml`
	FILE=`basename ${FILE}`
	#FILE=`ls ${CONFIG}/${PREFIX}${NODE}_vars.yml | head -n 1 | rev | cut -d / -f 1 | rev`
	echo -e "\t${GRN}${FILE}${NC}\n"
	cat << HERE
So we can skip this step.

If you want to start with a fresh copy of the node configuration file,
just run './mk-node-config.sh' to make a new node configuration file.

HERE
	read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
else
echo -e "Let's go ahead and create the node configuration file for node ${CYA}${NODE}${NC}."
cat << HERE

The node configuration file will be created in the 'config' directory 
HERE
echo -e "and will be named ${CYA}'${PREFIX}${NODE}_vars.yml'${NC}.  The '${PREFIX}${NODE}' part of the"
cat << HERE
filename is a combination of the 'prefix: ${PREFIX}' from 
'config/system_vars.yml' and the node number that you entered.

When creating a node configuration file with './mk-node-config.sh' you will
have the option to change the time zone for the firewall.

The command that will be run for this step is:
HERE

echo -e "\n${GRN}\t./mk-node-config.sh --node ${NODE}${NC}\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

	./mk-node-config.sh --node ${NODE}
	if [ $? -eq 0 ]
	then
		echo ""
		read -p "Previous step complete, press <Enter> to continue: "
	else
		echo -e "\nPrevious step failed."
		abort Failed to create node configuration file.
	fi

#### Show node config file
clear
walkthrough - Your Node Configuration

echo -e "Now that we have created the ${CYA}'config/${PREFIX}${NODE}_vars.yml'${NC} node"
cat << HERE
configuration file, let's take a look at the file.

When the file is displayed, you will see that the time zone has been set.
Since the node number is part of the filename, we do not need to specify it
in the node configuration file.

HERE
echo -e "All of the other configuration information needed to build the ${PREFIX}${NODE}"
cat << HERE
node is contained the 'config/system_vars.yml' file and the 'secrets'
files that you have created.

Also notice that the node configuration file contains templates that you
can use to specify fixed leases for the DHCP server and/or local hostnames
for the DNS server.  Refer to 'doc/fmp-admin-guide.html' for more information
on these features.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

walkthrough - Your Node Configuration
more "${CONFIG}/${PREFIX}${NODE}_vars.yml"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
####
fi

COUNT=`ls ${DEPLOY}/${PREFIX}${NODE}/* 2>/dev/null | wc -l`
if [[ ${COUNT} != 0 ]]
then
	clear
	walkthrough - Prior Build Detected
echo -e "If looks like you have already completed a build for the ${CYA}'${PREFIX}${NODE}'${NC} node.\n"

	show-node-deploy
	cat << HERE
FireMyPi will not build a config or image where one already exists.  In
order to run the build, we will need to clean the 'deploy' directory first.

To do this, we will use the './clean.sh' script and specify the node to clean.

The command that we will run is:
HERE
	echo -e "\n${GRN}\t./clean.sh --node ${NODE}${NC}\n"
	read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
	clear
	walkthrough - Cleaning Prior Build
	echo "./clean.sh --node ${NODE}"
	./clean.sh --node ${NODE}
	if [ $? -eq 0 ]
	then
		echo ""
		read -p "Previous step complete, press <Enter> to continue: "
	else
		echo -e "\nPrevious step failed."
		abort Failed to clean environment.
	fi
fi

clear
walkthrough - Prerequisites Completed

cat << HERE
Ok, we have the required packages installed, we have a core image in the 
build environment, we have the secrets that we need and we have a node
configuration file.

We're ready to build!

Before doing that, let's take a look at the build environment again.

HERE

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

./show-build-environment.sh

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough Step 6 - Build

cat << HERE
From the previous './show-build-environment.sh' command you can see that the
dashboard is now green.  So, let's do a build!

The command that we use to build is './build-firemypi.sh'.  Since we're 
HERE
echo -e "building node ${CYA}${NODE}${NC} we'll need to specify that on the command line."
cat << HERE

We're also going to specify '--test' and '--image' for 'build-firemypi.sh'.

The '--test' argument tells './build-firemypi.sh' to build the configuration
HERE
echo -e "with the test IP address of ${CYA}'192.168.${NODE}.${TESTHOST}'${NC}.  The host number of '${TESTHOST}' "
cat << HERE
is set by the 'green_testhost:' variable in 'config/system_vars.yml'.  The 
subnet of '192.168.${NODE}.0/24' is set by the node number.

Also, since this is a test firewall, the hostname will have 'test' appended
HERE
echo -e "to it, so the hostname will be ${CYA}'${PREFIX}${NODE}test'${NC}."
cat << HERE

The command that will be run for this step is:
HERE

echo -e "\n${GRN}\t./build-firemypi.sh --node ${NODE} --test --image${NC}\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
echo "./build-firemypi.sh --node ${NODE} --test --image"
./build-firemypi.sh --node ${NODE} --test --image
if [ $? -eq 0 ]
then
	echo ""
	read -p "Press <Enter> to continue or <Ctrl-C> to exit: "
else
	echo -e "\nPrevious step failed."
	abort Failed to build image.
fi

clear
walkthrough - Build Complete

cat << HERE
Congratulations!

You've just built an IPFire firewall with FireMyPi!

Let's take a look at the results of the build by running:
HERE

echo -e "\n${GRN}\t./show-build-environment.sh --node ${NODE}${NC}\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

./show-build-environment.sh -n ${NODE}

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough - Write to SD Card
echo -e "From the './show-build-environment.sh --node ${NODE}' you can see that node"
echo -e "${CYA}'${PREFIX}${NODE}'${NC} has been built.  The config and image produced by the"
echo -e "build are in the ${CYA}'deploy/${PREFIX}${NODE}'${NC} directory."
cat << HERE

Use 'rpi-imager' to write the test image to a micro sd card and you will
be able to boot it on your Raspberry Pi.

This walkthrough has built a test firewall that you can access on the
'192.168.${NODE}.0/24' subnet.  Refer to 'doc/NetworkDiagramTest.pdf' to
attach the test firewall to your home network.

If your home subnet is not '192.168.${NODE}.0/24', you can build a firewall
for your subnet by re-running this walkthrough with a different node number
or creating a node configuration file that matches your subnet and running
'./build-firemypi.sh' to build the new node.

Since you've already completed this walkthrough, you won't need to install
packages, move an image into the build environment or create secrets again.

HERE

echo -e "Use ${GRN}'ssh root@192.168.${NODE}.${TESTHOST}'${NC} or browse to ${GRN}'https://192.168.${NODE}.${TESTHOST}:444'${NC} to\naccess the test firewall.\n"
read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

clear
walkthrough - Build a Production Firewall
cat << HERE
When you have familiarized yourself with the IPFire Web GUI and are ready
to move your FireMyPi/IPFire firewall into production, build a production
FireMyPi/IPFire image by running:

HERE

echo -e "${GRN}\t./build-firemypi.sh --node ${NODE} --prod --image${NC}"

cat << HERE

As before, use 'rpi-imager' to write the production image to a micro sd card
and you will be able to boot it on your Raspberry Pi.

Refer to 'doc/NetworkDiagram.pdf' to attach the production firewall to your
home network.

HERE

read -p "Press <Enter> to exit the walkthrough: "
echo -e "\nDone."

exit 0
