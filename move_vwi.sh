#!/bin/bash
# Assign options 
while getopts ":f:e:n:h:" opt; do
  case $opt in
    f)
      folder=$OPTARG # path to folder containing coded session ids
      ;;
    e)
      epoch=$OPTARG # epoch number
      ;;
    n)
      num=$OPTARG # measurement number (1 or 2; 0 if moving resliced dcms)
      ;;
    h)
      hash=$OPTARG # sess_map file
  esac
done

# Check if the argument is a hash_list or a list of sessions
if [[ -h $argument ]]; then
  echo "Input is a hashlist" ;
  hash_list=$argument
else
  echo "Input is not a hashlist"
  echo "$PWD"
  # Generate a sub list from the main epoch hashlist using the sessions provided
  main_list=$(find /fs0/repos/tools/hash_lists/ -maxdepth 1 -type f -iname "*"MAP"*ScansAcquired*.csv")
  head -n 1 "$main_list" > subset.csv
  for i in $argument
    do
    cat $main_list | grep -e "$i" >> subset.csv #grepping for session id
    done
    hash_list=./subset.csv
fi

cd "$folder"
if [ "$num" -eq 1 ]; then
  var=FIRSTCODING
elif [ "$num" -eq 2 ]; then
  var=SECONDCODING
elif [ "$num" -eq 0 ]; then
  var=RESLICED
fi

cat "$hash_list" | while read line; do
 sess=`echo "$line" | awk -F ',' '{print $1}'`
 map=`echo "$line" | awk -F ',' '{print $2}'`
 path=/fs0/MAP/PROCESSED/"$map"/Brain/EPOCH"$epoch"/VESSELWALL/"$sess"/"$var"
 mkdir -p "$path"
 if [ "$num" -eq 0 ]; then
  cp -p "$folder"/"$sess"/* "$path"
  chmod -R 775 "$path"
 elif [ "$num" -ne 0 ]; then
  # copy session_date text files
  cp -p temp/"$sess"_*.txt "$path"
  # copy vwi_session_date text files
  cp -p temp/vwi_"$sess"_*.txt "$path"
  # copy dicoms
  cp -rp "$folder"/"$sess" "$path"
  # update permissions
  chmod -R 775 "$path"/*
 fi
done
