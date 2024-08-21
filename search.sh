#!/bin/bash

# shellcheck disable=2068

. lib/env.sh
. lib/status.sh || { STATE="unauthenticated"; }
. lib/utils.sh

echo '{ "items": ['

if [[ "${STATE}" == "unauthenticated" ]]; then
    ./login.sh >&2
    . lib/status.sh
fi

if [ "${STATE}" == "locked" ]; then
    ./unlock.sh >&2
    . lib/status.sh
fi

if [ "${STATE}" == "unauthenticated" ]; then
    log "Unauthenticated"

    # Unauthenticated
    echo "$(item "Login to Bitwarden" "login" "Default ${1:-${bwuser}}"),"
    echo "$(item "Configure Workflow" "workflow" "Opens in Alfred Preferences"),"

elif [ "${BW_SERVER}" == "null" ]; then
    log "Server not running"

    # Server not running
    echo "$(item "Login to Bitwarden" "login" "Default ${1:-${bwuser}}"),"
    echo "$(item "Configure Workflow" "workflow" "Opens in Alfred Preferences"),"

elif [ "${STATE}" == "locked" ]; then
    log "Vault locked"

    # Locked
    echo "$(item "Unlock Vault" "unlock" "Logged in as ${bwuser}"),"
    echo "$(item "Logout of Bitwarden" "logout"),"
    echo "$(item "Configure Workflow" "workflow" "Opens in Alfred Preferences"),"

elif [ "${STATE}" != "unlocked" ]; then
    log "Unknown state: ${STATE}"

    # Unknown
    echo "$(item "Bitwarden Error" "" "Unknown state: ${STATE}"),"

else
    # Unlocked
    items=$(./list_items.sh $@) &&
        echo "${items}" | sed '1d;$d' ||
        {
            ./login.sh >&2
            ./unlock.sh >&2
            . lib/status.sh
            sleep 1
            ~/.local/bin/alfred bw\ 
        }
fi

echo ' ]}'
