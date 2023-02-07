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

function create_json() {
  if test -f "./meta.json"; then
    echo "meta.json exists"
  else
    ENCODED=$(exiftool -a -r -G1 -s $1 | awk '/Certificate/ {print $4}')
    echo $ENCODED | base64 -d > meta.json
  fi
}

IFS=$'\n'
PROFILE=$(cat "/etc/lsb-release")
TARGET="DISTRIB_DESCRIPTION"
OS=$(get_value "${PROFILE[@]}" "$TARGET")

if [ $# -gt 1 ]; then
  echo "Only one argument is required. $ARG_QN was given"

  exit 2
fi

if [ -z $1 ]; then
  echo 'Missing location of image as argument.'
  
  exit 2
fi

if [[ "$OS" == "Manjaro" || "$OS" == "Arch" ]]; then
  {
    exiftool -ver && {
      echo 'continue'

      create_json $1
    }
  } || {
    echo 'download exiftool'
    pacman -S "perl-image-exiftool" && create_json $1
  }
else
  echo 'OS must be Arch linux or Manjaro'
fi
