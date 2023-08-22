#!/bin/bash
while getopts ":d:i:n:" opt; do
  case $opt in
    d) 
      copy_dir=$OPTARG
      cd "$copy_dir"
      echo "$PWD"
      ;;
    i) 
      argument=$OPTARG # list of session ids that need moved
      ;;
    n)
      num=$OPTARG # measurement number (1 or 2; 0 if moving resliced dcms)
      ;;
  esac
done

if [ "$num" -eq 1 ]; then
  var=FIRSTCODING
elif [ "$num" -eq 2 ]; then
  var=SECONDCODING
elif [ "$num" -eq 0 ]; then
  var=RESLICED
fi

if [[ -f $argument ]]; then
  echo "Input is a hashlist" ;
  hashlist="$argument"
else
  echo "Input is not a hashlist" 
  # Generate a sub list from the main Scans acquired hashlist using the sessions provided
  main_list=$(find /fs0/repos/tools/hash_lists/ -maxdepth 1 -type f -iname "*"MAP"*ScansAcquired*.csv")
  head -n 1 "$main_list"  > subset.csv
  for i in $argument
    do
    cat $main_list | grep -e "$i" >> subset.csv # Grepping for session id 
    done
    hashlist=./subset.csv
fi
# Find out column numbers for sessions, map_ids and epoch 
sess_col=$(awk -v RS=',' '/session_id/{print NR; exit}' $hashlist)
epoch_col=$(awk -v RS=',' '/epoch/{print NR; exit}' $hashlist)
id_col=$(awk -v RS=',' '/map_id/{print NR; exit}' $hashlist)

echo "$id_col"
tail -n +2 "$hashlist" | while read line
do
id=$(echo $line | awk -v m="$id_col" -F ',' '{print $m}')
session=$(echo "$line" | awk -v s="$sess_col" -F ',' '{print $s}')
epoch=$(echo "$line" | awk -v e="$epoch_col" -F ',' '{print $e}')

path=/fs0/MAP/PROCESSED/"$id"/Brain/EPOCH"$epoch"/VESSELWALL/"$session"/"$var"
mkdir -p "$path"
if [ "$num" -eq 0 ]; then
  echo "copying resliced images for "$id""
  cp -p "$copy_dir"/"$session"/* "$path"
  chmod -R 775 "$path"
elif [ "$num" -ne 0 ]; then
  # copy session_date text files
  echo "copying measurement session_date text file for "$id""
  cp -p temp/"$session"_*.txt "$path"
  # copy vwi_session_date text files
  echo "copying measurement vwi_session_date text file for "$id""
  cp -p temp/vwi_"$session"_*.txt "$path"
  # copy dicoms
  echo "copying dicom measurements for "$id""
  cp -rp "$copy_dir"/"$session" "$path"
  # update permissions
  chmod -R 775 "$path"/*
fi
done
