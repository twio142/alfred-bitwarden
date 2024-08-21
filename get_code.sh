#!/bin/bash

# shellcheck disable=2154

. lib/env.sh

[ "${twoStepMethod}" == "" ] && exit

log "2FA ${twoStepMethod}"

if [ "${twoStepMethod}" == "1" ]; then
    log "Trigger email authentication"

    bw --nointeraction login "${bwuser}" --method "${twoStepMethod}" --passwordenv PASS
fi

# CODE=$(./get_code.applescript "${twoStepMethod}")
SECRET=$(security find-generic-password -a "${bwuser}" -l "Bitwarden TOTP Secret" -s "${serverUrl}" -w)
CODE=$(oathtool --totp --base32 "${SECRET}")

echo "--method ${twoStepMethod} --code ${CODE}"
