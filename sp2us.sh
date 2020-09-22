#!/bin/sh
#
# sp2us.sh
#   Name       : spaces to underscores
#   Description: Search all file with spaces in its name under current directory, and rename spaces by underscores
#   Usage      : sp2us.sh
#   Notes      : No arguments nor options
#   History    : 2020/Jan/04(Sat) Initial version (W.Yamamoto)
#

SP2US=$(cd $(dirname $0); pwd)/$(basename $0)
#echo ${SP2US}; exit

ls -1 | gawk 'BEGIN{FS="\t"} (/ /||/　/){ a0=gensub(/ /,"\\\\ ","G",$1); a0=gensub(/\(/,"\\\\(","G",a0); a0=gensub(/\)/,"\\\\)","G",a0); a1=gensub(/ /,"_","G",$1); a1=gensub(/　/,"_","G",a1); a1=gensub(/\(/,"_","G",a1); a1=gensub(/\)/,"_","G",a1); c="mv "a0" "a1; print(c); system(c)}'

for d in $(find . -maxdepth 1 -type d)
do 
  if [ $d = "." ]; then
    continue
  fi
  echo $d
  cd $d
  ${SP2US}
  cd ..
done

exit 0
