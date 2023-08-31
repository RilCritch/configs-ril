#!/usr/bin/env bash


cal | tail -n +2 | while IFS= read -r line; do
  centered="\${alignc}${line}"
  echo ${centered}
  
  # day=$(date +%d)
  # for word in $centered; do
  #   if [ "$day" -eq "$word" ]; then
  #     echo "\${color7}${word}"
  #   else
  #     echo "\${color2}${word}"
  #   fi
  # done
done
