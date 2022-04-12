#!/usr/bin/env bash

(
################################################
# SETTINGS                                     #
################################################
# If you do not set these variables, you will be
# prompted during script execution.

# Specify if this is a Production or Sandbox environment.
# Production = p, Sandbox = s
PROD_SAND=""

# Vault Access Credentials Username and Password
UNAME=""
PASSWORD=""

# The secret passphrase to use for the new PKCS12 keystore
KEYSTORE_PASSPHRASE=""

MERCHANT_ID=""
################################################

# Enforce that this script is being run with bash.
if [ -z $BASH_VERSION ]; then
    echo "BASH_VERSION not set. Please run this script using Bash"
    return
fi

# Error handling
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap '[ $? = "0" ] || echo "ERROR: \"${last_command}\" command failed with exit code $?."' EXIT

get_param () {
    local MESSAGE=$1
    local PARAM=$2
    if [ -z $PARAM ]; then
       read -p "$MESSAGE " PARAM
    fi;
    echo $PARAM;
}

cat <<-EOF

This script will perform the following operations:

1. Generate a PKCS12 keystore
2. Store the PKCS12 keystore, passphrase, and public key in your vault.
3. Create a yaml file with the populated values

Before running this script, ensure you have met the requirements below:

1. You have run the ./generate-keys.sh and uploaded the keys to your Apple account.
2. You have downloaded the applepay.cer file from the Apple dashboard and placed it here: ./keys/applepay.cer
3. You know your ApplePay Merchant ID
4. You have Access Credentials (username/password) for your vault. If not, these credentials can be generated from the VGS Dashboard.
5. You have chosen a secret passphrase for the new keystore

Do you want to continue? [y/N]
EOF
read CONT 
CONT=${CONT:-N}

if [ $CONT != "y" ]; then
    echo "Exiting."
    return
fi

MERCHANT_ID=$(get_param "What is your Apple Merchant ID?" $MERCHANT_ID)

PROD_SAND=$(get_param "Is your vault ID for [s]andbox or [p]roduction? [s/p]" $PROD_SAND)
if [ $PROD_SAND = "p" ]; then
    URL=https://api.prod.verygoodvault.com/aliases
elif [ $PROD_SAND = "s" ]; then
    URL=https://api.sandbox.verygoodvault.com/aliases
else
    echo "Invalid entry. Exiting."
    return
fi

UNAME=$(get_param "What is your vault's Access Credentials Username?" $UNAME)
PASSWORD=$(get_param "What is your vault's Access Credentials Password?" $PASSWORD)
KEYSTORE_PASSPHRASE=$(get_param "Enter a secret passphrase for the new PKCS12 keystore" $KEYSTORE_PASSPHRASE)

echo ">>> 1. Generate a PKCS12 keystore"
echo "Converting applepay.cer to applepay.pem"
openssl x509 -in ./keys/applepay.cer -text -inform DER -outform PEM -out ./keys/applepay.pem
echo "Creating keystore in ./keys/applepay.p12"
openssl pkcs12 -export -out ./keys/applepay.p12 -inkey ./keys/applepay.key -in ./keys/applepay.pem -passout pass:$KEYSTORE_PASSPHRASE

KEYSTORE=$(cat ./keys/applepay.p12 | base64)

echo ""
echo ">>> 2. Store the PKCS12 keystore, passphrase, and public key in your vault."

echo "Storing Keystore"
PAYLOAD="{ \
    \"data\": [{\"value\":\"${KEYSTORE}\",\"format\":\"UUID\"}]
}"
RESPONSE=$(curl -s $URL -X POST -u $UNAME:$PASSWORD \
              -H 'Content-Type: application/json' \
              -d "${PAYLOAD}")
echo "RESPONSE:"
echo $RESPONSE | jq
KEYSTORE_TOKEN=$(echo $RESPONSE | jq -r '.data[].aliases[].alias')
echo "Keystore Token:" $KEYSTORE_TOKEN
unset RESPONSE

echo ""
echo "Storing Keystore Passphrase"
PAYLOAD="{ \
    \"data\": [{\"value\":\"${KEYSTORE_PASSPHRASE}\",\"format\":\"UUID\"}]
}"
RESPONSE=$(curl -s $URL -X POST -u $UNAME:$PASSWORD \
              -H 'Content-Type: application/json' \
              -d "${PAYLOAD}")
echo "RESPONSE:"
echo $RESPONSE | jq
KEY_PASS_TOKEN=$(echo $RESPONSE | jq -r '.data[].aliases[].alias')
echo "Keystore Passphrase Token:" $KEY_PASS_TOKEN
unset RESPONSE

echo ""
echo "Storing Public Key"
PUBKEY=$(sed -n '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' keys/applepay.pem | sed '1d;$d' | tr -d '\n')
PAYLOAD="{ \
    \"data\": [{\"value\":\"${PUBKEY}\",\"format\":\"UUID\"}]
}"
RESPONSE=$(curl -s $URL -X POST -u $UNAME:$PASSWORD \
              -H 'Content-Type: application/json' \
              -d "${PAYLOAD}")
echo "RESPONSE:"
echo $RESPONSE | jq
PUBKEY_TOKEN=$(echo $RESPONSE | jq -r '.data[].aliases[].alias')
echo "Public Key Token:" $PUBKEY_TOKEN

echo ""
echo "Preparing ./applepay.yaml for import into VGS"
cp ./resources/template-applepay.yaml ./applepay.yaml

sed -i -e "s/~KEYSTORE_TOKEN~/${KEYSTORE_TOKEN}/" ./applepay.yaml
sed -i -e "s/~KEY_PASS_TOKEN~/${KEY_PASS_TOKEN}/" ./applepay.yaml
sed -i -e "s/~PUBKEY_TOKEN~/${PUBKEY_TOKEN}/" ./applepay.yaml
sed -i -e "s/~MERCHANT_ID~/${MERCHANT_ID}/" ./applepay.yaml
rm ./applepay.yaml-e

echo "Success! ./applepay.yaml has been popualted with the tokenized values."
echo "You can now upload the generated yaml to your vault."
)
