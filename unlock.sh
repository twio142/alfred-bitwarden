#!/bin/bash

# shellcheck disable=2154

. lib/env.sh

log "unlock"

p=$(security find-generic-password -a "${bwuser}" -s "${serverUrl}" -l "Bitwarden Master Password" -w)
[ -z "$p" ] && p=$(./get_password.applescript "${bwuser}")

[ "${p}" == "" ] ||
    curl -s -d "password=${p}" "${API}"/unlock | jq -r '.message // .data.title'
