#!/bin/bash

#
# Mobile device my directory (predefiend source) Backup
#
#   Usage: ./mbkupd.sh
#
#   Notes:
#       o The source directory is assumed MTP device such as Android smartphone.
#	o The destination root ($DST_RT) is assumed a directory in the Linux file system.
#	o Subdirectories of the destination will be created automatically.
#	o Copy files which are newer in the source directory, or do not exist in the destination.
#	o Files only in the destination are not deleted.
#	o Symbolic link to file is copied as it is, i.e. "cp -r" is used.
#	o Symbolic link to directory is not traversed, but copied as it is.
#	o Timestamp is perserved, i.e. "cp -p" is used.
#
#   History:
#	2014/10/18(Sat)	Initial version (bkupd.sh)
#	2014/10/19(Sun)	Bug fix ... Lacking double quate around directory variables (bkupd.sh)
#	2018/01/08(Mon)	Initial version (mbkupd.sh)
#

#
# parameter settings
#

INFOMSG="true"	# INFO Message: OFF
#INFOMSG="echo"	# INFO Message: ON

#VRBMSG="true"	# Verbose Message: OFF
VRBMSG="echo"	# Verbose Message: ON

DBGMSG="true"	# Debug Message: OFF
#DBGMSG="echo DEBUG:"	# Debug Message: ON

XDBGMSG="true"	# Exhaustive Debug Message: OFF
#XDBGMSG="echo XDEBUG:"	# Exhasutive Debug Message: ON

#CPCMD="echo TEST: cp -pr"	# Copy command: OFF
CPCMD="cp -pr"	# Copy command: ON

CALLLIMIT=32	# Call counter Limit (For unexpected error case)

#
# Directory path
#
# MTP mount point
MTP_MP=/home/vatarushka/mtp
#MTP_MP=/run/user/1000/gvfs/mtp\:host\=OPPO_SDM665-IDP__SN%3A518F0D5C_518f0d5c


# Source paths ... all alias/link paths must be listed up
SRC_RT=${MTP_MP}/内部共有ストレージ/wyamamo
# SRC_RT=${MTP_MP}/内部ストレージ/wyamamo

# Destination path
DST_RT=/home1/vatarushka/MyDocs/mobile_strage/wyamamo

#
# run-time parameter check
#
if [ $# -gt 0 ];then
	CALLCNT=$1
else
	CALLCNT=0
fi
${DBGMSG} "call cnt(${CALLCNT}) : limit(${CALLLIMIT})	${PWD}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE:-$0}")"; pwd)"
script_file=${0##*/}
script_fp=${script_dir}/${script_file}
${DBGMSG} "script="${script_fp}

#
# Mount the MTP device
#
if [ ! -d ${MTP_MP} ]; then
	mkdir ${MTP_MP}
fi
if [ ! -d ${SRC_RT} ]; then
	# ps auxw | grep -e 'gvfs.*mtp' | grep -v grep | awk '{cmd="kill "$2; system(cmd)}'
	jmtpfs ~/mtp
	if [ "$?" -ne 0 ]; then
		echo "MTP device mount error."
		exit -1
	fi
fi

#
# Check source and destination directories
#
${DBGMSG} "SRC   ="${SRC_RT}
SRC=${SRC_RT}
${DBGMSG} "DST   ="${DST_RT}
DST=${DST_RT}

#
# Traverse ${PWD} - cp files & mkdir into the destination
#
if [ ${CALLCNT} -eq 0 ]; then
	cd ${SRC_RT}
else
	SUBDIR=`echo ${PWD} | sed "s:${SRC_RT}::" | sed 's:^/::'`
	DST=${DST}/${SUBDIR}
fi
for f in .* *; do
	${XDBGMSG} "$f"
	CPFLAG=0
	if [ "$f" = ".." ] || [ "$f" = "." ] || [ "$f" = "*" ] || [ "${f:0:7}" = ".~lock." ]; then
		:
	elif [ -L "$f" ]; then
		${DBGMSG} "symbolic link file $f found"
		${XDBGMSG} ls -l "`pwd`/$f"
		CPFLAG=1
	elif [ -f "$f" ]; then
		${DBGMSG} "Regular file $f found"
		${XDBGMSG} ls -l "`pwd`/$f"
		CPFLAG=1
	elif [ -d "$f" ]; then
		${INFOMSG} "Backup a direcotry ... $f"
		if [ $CALLCNT -gt $CALLLIMIT ];then
			echo "ERROR: Exceeded call limit $CALLLIMIT"
			exit 1
		else
			if [ ! -d "${DST}/$f" ]; then
				mkdir "${DST}/$f"
			fi
			cd "$f"
			${script_fp} $((CALLCNT + 1))
		fi
		cd ..
	else
		${INFOMSG} "WARNING: Ignore an unknown type file ... ""$f"
	fi
	
	if [ $CPFLAG -eq 1 ]; then
		if [ ! -e "${DST}/$f" ];then
			${VRBMSG} "INFO: $f ... Copied (not exists)"
			${CPCMD} "$f" "${DST}"
		elif [ "${DST}/$f" -ot "$f" ];then
			${VRBMSG} "INFO: $f ... Overwritten (newer)"
			${CPCMD} "$f" "${DST}"
		else
			${DBGMSG} "WARNING: Ignore $f because it is not newer."
		fi
	fi
done

#
# Unmount MTP device
#
if [ ${CALLCNT} -eq 0 ]; then
	cd ${MTP_MP}/..
	fusermount -u ${MTP_MP}
	/usr/lib/gvfs/gvfs-mtp-volume-monitor &
fi

exit 0
