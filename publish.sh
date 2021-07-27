#!/bin/bash

# Debugging
# set -x

# REQUIREMENTS:
# -  Ensure you are in ./ci folder
# -  Ensure you are logged in to AZ CLI (or logged in with a Service Principal)
# -  Environment variable set:
#       EVENTHUB_URI
#       EVENTHUB_SHARED_ACCESS_KEY


if [ -z "$1" ]
then
    echo "Please specify path to EH payload."
    echo "Sample execution: ./publish_eh.sh atlas_definitions/eh_create_entity.json"
    exit
fi

get_sas_token() {
    # https://docs.microsoft.com/en-us/rest/api/eventhub/generate-sas-token
    local EVENTHUB_URI=$1
    local SHARED_ACCESS_KEY_NAME=$2
    local SHARED_ACCESS_KEY=$3
    local EXPIRY=${EXPIRY:=$((60 * 60 * 24))} # Default token expiry is 1 day

    local ENCODED_URI=$(echo -n $EVENTHUB_URI | jq -s -R -r @uri)
    local TTL=$(($(date +%s) + $EXPIRY))
    UTF8_SIGNATURE=$(printf "%s\n%s" $ENCODED_URI $TTL | iconv -t utf8)

    local HASH=$(echo -n "$UTF8_SIGNATURE" | openssl sha256 -hmac $SHARED_ACCESS_KEY -binary | base64)
    local ENCODED_HASH=$(echo -n $HASH | jq -s -R -r @uri)

    echo -n "SharedAccessSignature sr=$ENCODED_URI&sig=$ENCODED_HASH&se=$TTL&skn=$SHARED_ACCESS_KEY_NAME"
}

# Get EH sas token
eh_sas_token=$(get_sas_token "$EVENTHUB_URI" AlternateSharedAccessKey "$EVENTHUB_SHARED_ACCESS_KEY")

# Send message to Purview EH - atlas_hook
curl --request POST --url "https://${EVENTHUB_URI}/atlas_hook/messages" \
    --header "Authorization: $eh_sas_token" \
    --header "Content-type: application/atom+xml;type=entry;charset=utf-8" \
    --header "Host: ${EVENTHUB_URI}" \
    --data-binary "@$1"

echo "Done!"