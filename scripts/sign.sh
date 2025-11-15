#! /bin/sh

KEYID=$(cat data/keyid)
. work/awscreds

read -t 2 sum
[ -z "$sum" ] && exit 1
echo TYPE
echo rsa
echo SIGNATURE
aws kms sign --message-type RAW --message "$sum" --signing-algorithm RSASSA_PKCS1_V1_5_SHA_256 --key-id $KEYID --output text | awk '{print $2}' | base64 -d
echo
echo CERT
cat data/repo.pub
echo END
