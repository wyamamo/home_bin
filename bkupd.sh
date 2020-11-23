#!/bin/bash

#
# Backup the current directory in the predefiend destination
#
#   Usage: ./bkupd.sh
#
#   Notes:
#	o The destination root ($DST_RT) must exist.
#	o The destination for the current directory also must exist.
#	o Subdirectories of the destination will be created automatically.
#	o Copy files which are newer in the source directory, or do not exist in the destination.
#	o Files only in the destination are not deleted.
#	o Symbolic link to file is copied as it is, i.e. "cp -r" is used.
#	o Symbolic link to directory is not traversed, but copied as it is.
#	o Timestamp is perserved, i.e. "cp -p" is used.
#
#   History:
#	2014/10/18(Sat)	Initial version
#	2014/10/19(Sun)	Bug fix ... Lacking double quate around directory variables
#	2018/01/08(Mon)	Small fixes
#	2018/01/20(Sat)	cd `readlink -f .`
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
#XDBGMSG="echo XDEBUG:"	# Exhaustive Debug Message: ON

#CPCMD="echo TEST: cp -pr"	# Copy command: OFF
#CPCMD="cp -pr"	# Copy command: ON
CPCMD="cp -r"	# Copy command: ON

CALLLIMIT=32	# Call counter Limit (For unexpected error case)

# Source paths ... all alias/link paths must be listed up
SRC_RT=(\
        /home/vatarushka \
        /home1/vatarushka \
        /home/vatarushka/vatarushka \
)

# Destination path
DST_RT=/media/vatarushka/VOLWIN10/DATA_NTFS/vatarushka

#
# Move the symbolic path to its absolute path
#
cd `readlink -f .`

#
# run-time parameter check
#
if [ $# -gt 0 ];then
	CALLCNT=$1
else
	CALLCNT=0
fi
${DBGMSG} "call cnt(${CALLCNT}) : limit(${CALLLIMIT})"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE:-$0}")"; pwd)"
script_file=${0##*/}
script_fp=${script_dir}/${script_file}
${DBGMSG} "script="${script_fp}
${DBGMSG} "PWD   ="`pwd`

SRC=`pwd`
${DBGMSG} "source ... $SRC"

DST=""
for (( I = 0; I < ${#SRC_RT[@]}; ++I )); do
        ${XDBGMSG} ${SRC_RT[I]}
        cnd="${DST_RT}/${SRC#${SRC_RT[I]}/}"
        ${XDBGMSG} "$cnd"
        if [ -e "$cnd" ];then
                DST="$cnd"
                break
        fi
done
if [ "$DST" = "" ];then
        echo "error ... no destination for $SRC"
        exit 1
fi
${DBGMSG} "destination ... $DST"


#
# Traverse ${PWD} - cp files & mkdir into the destination
#
for f in .* *; do
	${XDBGMSG} "$f"
	CPFLAG=0
	if [ "$f" = ".." ]; then
		:
	elif [ "$f" = "." ]; then
		:
	elif [ "$f" = "*" ]; then
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
			echo "stop ... exceed call limit $CALLLIMIT"
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
		${INFOMSG} "warning ... Ignore an unknown type file ... ""$f"
	fi
	
	if [ $CPFLAG -eq 1 ]; then
		if [ ! -e "${DST}/$f" ];then
			${VRBMSG} "copy `pwd`/$f (not exists)"
			${CPCMD} "$f" "${DST}"
		elif [ "${DST}/$f" -ot "$f" ];then
			${VRBMSG} "copy `pwd`/$f (newer)"
			${CPCMD} "$f" "${DST}"
		else
			${DBGMSG} "warning ... ignore $f because it is not newer."
		fi
	fi
done

exit 0
