#!/bin/bash

# shellcheck disable=2154

. lib/env.sh
. lib/status.sh
. lib/utils.sh

echo '{ "items": ['

if [ "${STATE}" == "unauthenticated" ]; then
    log "Unauthenticated"

    echo "$(item "Login to Bitwarden" "login" "Default ${1:-${bwuser}}"),"

elif [ "${BW_SERVER}" == "null" ]; then
    log "Server not running"

    echo "$(item "Login to Bitwarden" "login" "Default ${1:-${bwuser}}"),"

elif [ "${STATE}" == "locked" ]; then
    log "Vault locked"

    echo "$(item "Unlock vault" "unlock" "Logged in as ${bwuser}"),"
    echo "$(item "Logout of Bitwarden" "logout"),"

elif [ "${STATE}" != "unlocked" ]; then
    log "Unknown state: ${STATE}"

    echo "$(item "Bitwarden Error" "" "Unknown state: ${STATE}"),"

else
    organization=${ORGANIZATION_NAME:-"All Vaults"}
    collection=${COLLECTION_NAME:-"All Collections"}

    AUTO=( "" " (auto sync $((SyncTime)) minutes)" )

    # echo "$(item "Search Vault" "search"),"
    # echo "$(item "Search Folders" "folder"),"
    echo "$(item "Sync Vault" "sync" "${SYNC}${AUTO[${autoSync}]}"),"
    echo "$(item "Lock Vault" "lock" "Logged in as ${bwuser}"),"
    echo "$(item "Log Out" "logout" "${serverUrl}"),"
    echo "$(item "Set Default Vault" "organization" "${organization}"),"
    echo "$(item "Set Default Collection" "collection" "${collection}"),"
fi

# Actions available regardless of state
echo "$(item "Configure Workflow" "workflow" "${alfred_workflow_version}"),"

echo '] }'
