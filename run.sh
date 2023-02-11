#! /usr/bin/bash

ARG_QN=$#
GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'


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
  echo -e "${RED}OS must be Arch linux or Manjaro"${NC}
fi

function extract() {
  if [ ! -f $1 ]; then
    echo -e "${RED}Wrong location of image as argument.${NC}"
    
    exit 2
  fi

  ENCODED=$(exiftool -a -r -G1 -s $1 | awk '/Certificate/ {print $4}' | base64 -d)

  echo -e "${GREEN} $ENCODED ${NC}" 

  echo $ENCODED > meta_extract.txt
}

function inject() {
  echo "Input data indicating location of file containing content to inject into selected image:"
  IFS= read -r -p "> " data

  if [ -z "$data" ]; then
    reset
    echo -e "${ORANGE}Data given was empty. Exiting program.${NC}"

    exit 2
  fi

  if cat "$data" 2>/dev/null; then
    FILE_TYPE="`file -b "$data"`"

    exiftool -Certificate=$(cat $data 2>/dev/null | base64 | tr -d '\n') $1 
    echo -e "${GREEN}$FILE_TYPE content injected into $1${NC}"
  else
    exiftool -Certificate=$(echo "$data" | base64) $1

    echo -e "${GREEN}text injected into $1${NC}"
  fi
}

function start() {
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
    echo -e "${RED}No match for input: $choice${NC}"
  fi
}

if [ ! $# -eq 1 ]; then
  echo -e "${RED}Must have one argument of location of image. $# args was given.${NC}"

  exit 2
fi

if ! pacman -Qi "perl-image-exiftool" > /dev/null; then
  echo -e "${GREEN}downloading exiftool...${NC}"
  pacman -S "perl-image-exiftool" 
fi

reset
start $1
