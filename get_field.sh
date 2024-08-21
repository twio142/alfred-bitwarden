#!/bin/bash

# shellcheck disable=1090,2154

. lib/env.sh
. lib/utils.sh

# Save item
saveSelection

log "${API}/object/${field}/${id}"

if [ "${field}" == "TOTP" ]; then
    OBJ=$(curl -s "${API}"/list/object/items?search="${id}")

    if [ "$(jq -r .success <<< "${OBJ}")" == "true" ]; then
        secret=$(jq -r '.data.data[0].fields[] | select(.name == "TOTP") | .value' <<< "${OBJ}")
        [ -n "${secret}" ] && oathtool --totp --base32 "${secret}" || echo "No TOTP secret found" >&2
    else
        jq -r .message <<< "${OBJ}" >&2
        exit 1
    fi
else
    OBJ=$(curl -s "${API}"/object/"${field}"/"${id}")

    if [ "$(jq -r .success <<< "${OBJ}")" == "true" ]; then
        jq -r .data.data <<< "${OBJ}"
    else
        jq -r .message <<< "${OBJ}" >&2
        exit 1
    fi
fi
