#! /usr/bin/bash

{
  cat $1 && exiftool -Certificate=$(cat $1 | base64 | tr -d '\n') $2
} || {
  exiftool -Certificate=$(echo $1 | base64) $2
}
