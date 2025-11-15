#!/bin/sh

set -e

PROFILE=$1

if [ -z "${PROFILE}" ]; then
	echo "usage: gettoken.sh PROFILE"
	exit 1
fi

# Read MFA ID
MFAID=$(cat data/mfaid)

# Get the token code
read -p "Please enter MFA code: " TOKENCODE

# Get a session token
aws --profile "${PROFILE}" sts get-session-token --serial-number "${MFAID}" --token-code "${TOKENCODE}" > work/session.json

# Generate shell snippet
echo -n "export AWS_ACCESS_KEY_ID="
jq -r '.Credentials.AccessKeyId' < work/session.json
echo -n "export AWS_SECRET_ACCESS_KEY="
jq -r '.Credentials.SecretAccessKey' < work/session.json
echo -n "export AWS_SESSION_TOKEN="
jq -r '.Credentials.SessionToken' < work/session.json
echo -n "export AWS_DEFAULT_REGION="
aws --profile "${PROFILE}" configure get region

# Clean up
rm work/session.json
