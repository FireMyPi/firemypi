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
# FireMyPi: 	build-firemypi.sh
#

#
# Build a FireMyPi firewall node.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
	echo "Wrong directory - change to build directory and retry"
	exit 1
fi

source fmp-common

ANSIBLE=ansible-playbook
TEST_PROD=none
NODE=none
BUILD_IPFIRE=yes
CREATE_IMAGE=no
FORCE_BUILD=no
HAVEARGS=no
SHOW=no
BUILD_PORTABLE=false

function usage()
{
	echo "${PNAME} {-n|--node #}"
	exit 1
}

function add-option()
{
	OPTIONS="${OPTIONS} $*"
}

function add-var()
{
	VARS="${VARS} ${1}"
	[[ ${2} ]] && VARS="${VARS}=${2}"
}


check-license  || exit 1

#### Parse args
if [[ $# -gt 0 ]]
then
	HAVEARGS=yes
fi

while [[ $# -gt 0 ]]
do
	case $1 in
		--show)
			SHOW=yes
			;;

		-n|--node)
			shift
			NODE=$((10#${1}))
			if [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
			then
				abort "node must be between 1 and 254"
			fi
			;;

		--test)
			if [[ ${TEST_PROD} == none ]]
				then
					TEST_PROD=test
				else
					abort "Only one of --test --prod allowed."
			fi
			;;

		--prod)
			if [[ ${TEST_PROD} == none ]]
				then
					TEST_PROD=prod
				else
					abort "Only one of --test --prod allowed."
			fi
			;;

		--image)
			CREATE_IMAGE=yes
			;;

		-f|--force)
			FORCE_BUILD=yes
			;;

		--portable)
			BUILD_PORTABLE=true
			;;

		--debug)
			add-option "--check"
			add-option "--diff"
			add-option "-vvvvv"
			;;

		*)
			abort "invalid option '$1'"
			;;
	esac
	shift
done

if [[ ${HAVEARGS} == "no" ]]
then
	cat << HERE
build-firemypi.sh - Build a FireMyPi IPFire Firewall Node

    --show            Show the status of the build environment
    --node|-n {NODE}  Specify the node to build
    --test            Build test configuration
    --prod            Build production configuration
    --image           Build an image to write to a micro sd card
    --portable        Build a portable image for a remote location
    --force|-f        Force a build if config/image already exists

HERE
	exit 0
fi

# Get the build prefix
PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ ${PREFIX} ]] || abort "build prefix not found in ${SYSTEMVARS}"

if [[ ${SHOW} == yes ]]
then
	if [[ ${NODE} == none ]]
	then
		${DNAME}/show-build-environment.sh
	else
		${DNAME}/show-build-environment.sh --node ${NODE}
	fi
	exit 0
fi

#### Program checks.

[[ ${NODE} == none ]] && abort "must set node using -n|--node {NODE}"

[[ ${TEST_PROD} == none ]] && abort "must set --test or --prod"

if [[ ${BUILD_PORTABLE} == true ]] && [[ ${CREATE_IMAGE} == no ]]
	then
		abort "must build image if --portable selected"
fi

${DNAME}/show-build-environment.sh &>/dev/null
MISSINGSYS=$?
${DNAME}/show-build-environment.sh --node ${NODE} &>/dev/null
MISSINGNODE=$?
if [[ ${MISSINGSYS} -ne 0 || ${MISSINGNODE} -ne 0 ]]
then
	if [[ ${MISSINGSYS} -ne 0 ]]
	then
		echo "Something is missing in the system configuration."
		echo -e "Run 'show-build-environment.sh' to find out what is missing.\n"
	fi
	if [[ ${MISSINGNODE} -ne 0 ]]
	then
		echo "Something is missing in the node configuration."
		echo -e "Run 'show-build-environment.sh --node ${NODE}' to find out what is missing.\n"
	fi
	abort "something is missing in the configuration"
fi

#### Check for existing archive and image

CORENUMBER=`get-config ${DNAME}/core-image-to-use.yml core_number`
ARCHIVE="${DEPLOY}/${PREFIX}${NODE}/firemypi-core${CORENUMBER}-${PREFIX}${NODE}-config-${TEST_PROD}-${DATE}.tgz"
ARCHIVEBASE=`basename ${ARCHIVE}`
IMAGE="${DEPLOY}/${PREFIX}${NODE}/firemypi-core${CORENUMBER}-${PREFIX}${NODE}-image-${TEST_PROD}-${DATE}.img"
IMAGEBASE=`basename ${IMAGE}`
PORTBUILD="${PORTABLE}/${PREFIX}${NODE}/firemypi-core${CORENUMBER}-${PREFIX}${NODE}-portable-${TEST_PROD}-${DATE}.img"
PORTBASE=`basename ${PORTBUILD}`
PARAMS=${DEPLOY}/${PREFIX}${NODE}/build-parameters-${TEST_PROD}

if [[ -r ${ARCHIVE} ]]
then
	message "Config '${ARCHIVE}' already exists."
	if [[ ${FORCE_BUILD} == yes ]]
	then
		message "Build forced."
		BUILD_IPFIRE="yes"
	else
		BUILD_IPFIRE="no"
		message "Skipping build. Use '--force' to force the build."
		echo -e "\nCurrent ${GRN}${TEST_PROD^^}${NC} config was built with the following parameters:"
		cat ${PARAMS}
		echo ""
		if [[ ${CREATE_IMAGE} == yes ]]
		then
			if [[ -r ${IMAGE} ]]
			then
				abort "Image already exists.  Clean the node or use '--force' to force the build."
			else
				echo -e "Do you want to create an image with these parameters?\n"
				read -p "Press <Enter> to continue or <Ctrl C> to exit: "
			fi
		fi
	fi
fi

#### Run build

add-var "archive" "${ARCHIVE}"
add-var "user" "${USER}"
add-var "node" "${NODE}"
add-var "builddir" "${DNAME}"
add-var "date" "${DATE}"
add-var "time" "${TIME}"
add-var "test_prod" "${TEST_PROD}"
add-var "include_portable" "${BUILD_PORTABLE}"

if [[ ${BUILD_IPFIRE} == yes ]]
then
	message "Running build with parameters:"
	message "options: ${OPTIONS}"
	message "variables: ${VARS}"

	# clean up any previous build
	rm -f ${ARCHIVE}
	rm -f ${IMAGE}
	rm -f ${PORTBUILD}
	rm -rf ${DEPLOY}/${PREFIX}${NODE}/target

	# save build parameters
	mkdir -p `dirname ${PARAMS}`
	echo "options: ${OPTIONS}" > ${PARAMS}
	echo "variables: ${VARS}" >> ${PARAMS}

	PLAYBOOK="build-firemypi.yml"

	ansible-playbook ${RESOURCE}/${PLAYBOOK} ${OPTIONS} --extra-vars "${VARS}" 
	PLAYOK=$?

	if [ ${PLAYOK} -ne 0 ]
	then
		echo "Create config with the above parameters failed." >> ${PARAMS}
		message "Build parameters saved in deploy/${PREFIX}${NODE}."
		abort "Create config failed."
	fi

#### Create tar archive.

	# Set group:user to 99:99 which is nobody:nobody on ipfire.
	# This prevents file permission problems when the config is
	# installed.
	tar -C "${DEPLOY}/${PREFIX}${NODE}/target" --numeric-owner --owner=99 --group=99 -cpzf "${ARCHIVE}" ./ 
	message "Config created."
	echo ""
else
	message "Skipping ${TEST_PROD^^} build of ${PREFIX}${NODE} config."
fi

#### Create image

if [[ ${CREATE_IMAGE} == yes ]]
then
	add-option "--ask-become-pass"

	PLAYBOOK="create-image.yml"
	[[ -r ${ARCHIVE} ]] || abort "Archive '${ARCHIVE}' not found or not readable. "

	add-var "archive" "${ARCHIVE}"
	add-var "image" "${IMAGE}"
	message "Creating image from config '${ARCHIVE}'..."

	message "Creating image with parameters:"
	message "options: ${OPTIONS}"
	message "variables: ${VARS}"

	echo -e "\nNeed to become root to create the image."
	echo -e "\nEnter sudo password or <Ctrl-C> to exit:"
	
	ansible-playbook ${RESOURCE}/${PLAYBOOK} ${OPTIONS} --extra-vars "${VARS}" 
	PLAYOK=$?

	if [[ ${PLAYOK} -ne 0 ]]
	then
		abort "Create image failed."
	else
		message "Image created."
		echo ""
		if [[ ${BUILD_PORTABLE} == true ]]
		then
			message "Portable build created."
			echo ""
		fi
	fi

        if [[ ${TEST_PROD} == test ]]
		then
			echo -e "Image was built with test IP."
			echo -e "Use build-firemypi.sh with --prod to build a production image.\n"
		else
			echo -e "Image was built with production IP.\n"
	fi	
	echo -e "Use rpi-imager to write image from deploy/${PREFIX}${NODE} to a micro sd card.\n"
	echo -e "Image file:  ${GRN}${IMAGEBASE}${NC}\n"
	if [[ ${BUILD_PORTABLE} == true ]]
	then
		echo -e "Use 'portable-util.sh' to apply the portable build to an IPFire core image.\n"
		echo -e "Portable build:  ${GRN}${PORTBASE}${NC}\n"
	fi
else
	message "Image not created, run with --image to an create image."
	echo ""
fi

echo -e "Done."
exit 0
