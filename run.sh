#! /usr/bin/bash

ARG_QN=$#


function get_value() {
  for LINE in $1; do
    IFS='=' read -ra PARTS <<< "$LINE"

    if [[ "${PARTS[0]}" == "$2" ]]
    then
      NAME="${PARTS[1]%\"}"
      NAME="${NAME#\"}"
      IFS=' ' read -ra NAMES <<< "$NAME"

      echo "${NAMES[0]}"
    fi
  done
}

# IFS=$'\n'
PROFILE=$(cat "/etc/lsb-release")
TARGET="DISTRIB_DESCRIPTION"
OS=$(get_value "${PROFILE[@]}" "$TARGET")

if ! [[ "$OS" == "Manjaro" || "$OS" == "Arch" ]]; then
  echo 'OS must be Arch linux or Manjaro'
fi

function extract() {
  function extract_into_json() {
    ENCODED=$(exiftool -a -r -G1 -s $1 | awk '/Certificate/ {print $4}' | base64 -d)

    echo $ENCODED 

    echo $ENCODED > meta_extract.txt
  }

  if [ $# -gt 1 ]; then
    echo "Only one argument is required. $ARG_QN was given."

    exit 2
  fi

  if [ -z $1 ]; then
    echo 'Missing location of image as argument.'
    
    exit 2
  fi

  if pacman -Qi "perl-image-exiftool" > /dev/null; then
    extract_into_json $1
  else
    echo 'downloading exiftool...'
    pacman -S "perl-image-exiftool" && extract_into_json $1  
  fi
}

function inject() {
  echo "Input data indicating location of file containing content to inject into selected image:"
  IFS= read -r -p "> " data

  if [ -z "$data" ]; then
    echo "Data given was empty. Exiting program."

    exit 2
  fi

  if cat "$data" 2>/dev/null; then
    FILE_TYPE="`file -b "$data"`"

    exiftool -Certificate=$(cat $data > /dev/null | base64 | tr -d '\n') $1 
    echo "$FILE_TYPE content injected into $1"
  else
    exiftool -Certificate=$(echo "$data" | base64) $1

    echo "text injected into $1"
  fi
}

function start() {
  reset

  echo "Would you like to extract(1), inject(2), or read all meta(3) data from an image?"
  read -r -p "> " choice

  if [ $choice == "1" ]; then
    reset
    extract $1
  elif [ $choice == "2" ]; then
    reset
    inject $1
  elif [ $choice == "3" ]; then
    reset
    exiftool $1
  else
    echo "No match for input: $choice"
    reset
    start
  fi
}

if [ $# -gt 1 ]; then
  echo "Must have one argument of location of image. $# args was given."

  exit 2
fi

start $1
