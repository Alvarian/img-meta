#! /usr/bin/bash

function get_value() {
  LINES="$#"

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
  ENCODED=$(exiftool -a -r -G1 -s $1 | awk '/Certificate/ {print $4}')
  echo $ENCODED | base64 -d > meta.json
}

IFS=$'\n'
PROFILE=$(cat "/etc/lsb-release")
TARGET="DISTRIB_DESCRIPTION"
OS=$(get_value "${PROFILE[@]}" "$TARGET")
if [[ "$OS" == "Manjaro" || "$OS" == "Arch" ]]
then
  {
    exiftool -ver && {
      echo 'continue'

      create_json $1
    }
  } || {
    echo 'download exiftool'
    pacman -S "perl-image-exiftool"

    create_json $1
  }
fi
