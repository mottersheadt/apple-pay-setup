(
# exit when any command fails
set -e

echo "Generating keys for ApplePay"
if [ -d ./keys ]; then
    echo "WARNING: There is already a ./keys directory."
    echo "Do you want to archive the current directory and continue? [y/N]"
    read CONT > /dev/null 2>&1
    CONT=${CONT:-N}

    if [ $CONT != "y" ]; then
	echo "Exiting."
	return
    fi

    ARCHIVE_DIR=./keys-archive-$(date '+%Y%m%d%H%M%S')
    echo "Archiving current ./keys directory as ${ARCHIVE_DIR}"
    mv ./keys ./$ARCHIVE_DIR
fi

mkdir -p keys

openssl ecparam -out keys/applepay.key -name prime256v1 -genkey
openssl req -newkey rsa:2048 -new -sha256 -key keys/applepay.key -nodes -nodes -out keys/applepay.csr -subj '/O=Company/C=US'

cat <<-EOF

SUCCESS!

Keys have been generated in ./keys directory. Follow the steps below to complete ApplePay integration setup:

1. Upload the generated applepay.csr file to your Apple dashboard to create a new Payment Processing Certificate.
   (https://help.apple.com/developer-account/#/devb2e62b839)

2. Download your Payment Processing Certificate from the Apple website and place it here: ./keys/apple_pay.cer

3. Run the ./prepare-yaml.sh script to populate your route configuration with the correct values.

EOF

)
