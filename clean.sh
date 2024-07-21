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
# FireMyPi:  clean.sh
#

#
# Clean the various aspects of the build environment.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
        echo "Wrong directory - change to build directory and retry"
        exit 1
fi

source fmp-common

PREFIX=`get-config ${SYSTEMVARS} prefix`
[[ $PREFIX ]] || abort "build prefix not found in ${SYSTEMVARS}"

case $1 in
	-n|--node)
		shift
		NODE=$((10#${1}))
		if [[ ${NODE} -lt 1 ]] || [[ ${NODE} -gt 254 ]]
		then
		abort "node must be between 1 and 254"
		fi
		if [[ ! -e "config/${PREFIX}${NODE}_vars.yml" ]]
		then
		abort "node not found in 'config'"
		fi
		rm -f deploy/${PREFIX}${NODE}/*.tgz
		rm -f deploy/${PREFIX}${NODE}/*.img
		rm -f deploy/${PREFIX}${NODE}/build-parameters*
		rm -rf deploy/${PREFIX}${NODE}/target
		rm -rf portable/${PREFIX}${NODE}
		if [[ -d deploy/${PREFIX}${NODE} ]]
		then
			rmdir deploy/${PREFIX}${NODE} 2>/dev/null
			if [[ $? == 0 ]]
			then
				echo "Node ${PREFIX}${NODE} in builddir/deploy deleted..."
			else
				echo "Could not fully delete ${PREFIX}${NODE}..."
			fi
		else
				echo "Node ${PREFIX}${NODE} in builddir/deploy deleted..."
		fi
		exit 0
		;;
	--allnodes)
		for DIR in `ls deploy`
		do
			NODE="${DIR//${PREFIX}}"
			rm -f deploy/${PREFIX}${NODE}/*.tgz
			rm -f deploy/${PREFIX}${NODE}/*.img
			rm -f deploy/${PREFIX}${NODE}/build-parameters*
			rm -rf deploy/${PREFIX}${NODE}/target
			rm -rf portable/${PREFIX}${NODE}
			if [[ -d deploy/${PREFIX}${NODE} ]]
			then
				rmdir deploy/${PREFIX}${NODE} 2>/dev/null
				if [[ $? == 0 ]]
					then
					echo "Node ${PREFIX}${NODE} in builddir/deploy deleted..."
				else
					echo "Could not fully delete ${PREFIX}${NODE}..."
				fi
			else
					echo "Node ${PREFIX}${NODE} in builddir/deploy deleted..."
			fi
		done
		echo "All nodes in builddir/deploy deleted..."
		exit 0
		;;
	--coreimage)
		rm -f image/ipfire*
		rm -f core-image-to-use.yml
		echo "Core image in builddir/image and core-image-to-use.yml deleted..."
		exit 0
		;;
	--SECRETS)
		echo -e "\n${RED}Are you sure that you want to delete your SECRETS?${NC}\n"
		read -p "Type 'yes' to delete secrets: " YES
		if [[ ${YES} != "yes" ]]
		then
			echo -e "\nCancelled.\n"
			exit 1
		fi
		rm -f secrets/*.yml
		echo "Secrets in builddir/secrets deleted..."
		exit 0
		;;
	--ALL)
		echo -e "\n${RED}Are you sure that you want to delete ALL?${NC}\n"
		read -p "Type 'yes' to delete all nodes, secrets and the core image: " YES
		if [[ ${YES} != "yes" ]]
		then
			echo -e "\nCancelled.\n"
			exit 1
		fi
		for DIR in `ls deploy`
		do
			NODE="${DIR//${PREFIX}}"
			rm -f deploy/${PREFIX}${NODE}/*.tgz
			rm -f deploy/${PREFIX}${NODE}/*.img
			rm -f deploy/${PREFIX}${NODE}/build-parameters*
			rm -rf deploy/${PREFIX}${NODE}/target
			rm -rf portable/${PREFIX}${NODE}
			rmdir deploy/${PREFIX}${NODE} 2>/dev/null
			if [[ $? == 0 ]]
			then
				echo "Node ${PREFIX}${NODE} in builddir/deploy deleted..."
			else
				echo "Could not fully delete ${PREFIX}${NODE}..."
			fi
		done
		echo "All nodes in builddir/deploy deleted..."
		rm -f image/ipfire*
		rm -f core-image-to-use.yml
		echo "Core image in builddir/image and core-image-to-use.yml deleted..."
		rm -f secrets/*.yml
		echo "Secrets in builddir/secrets deleted..."
		exit 0
		;;
	*)
		cat << HERE
Usage:  clean [ --node|-n NODE | --allnodes | --coreimage | --SECRETS |
                --ALL ]

              --node|-n     remove build products for the specified node
              --allnodes    remove build products for all nodes
              --coreimage   remove core image and core-image-to-use.yml
              --SECRETS     remove all secrets
              --ALL         all of the above

HERE
		exit 0
		;;
esac
