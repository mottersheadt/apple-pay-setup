# Apple Pay VGS Integration Setup

Clone this repo to your local machine.

## 1. Generate Key and CSR
Apple Pay requires a certificate signing request (CSR file) to be uploaded to the Apple Dashboard to create a Payment Processing Certificate. (See https://help.apple.com/developer-account/#/devb2e62b839)

To generate the key and corresponding CSR, run the `./generate-keys.sh` script. The key and CSR will be put into the `./keys` directory.

Upload the generated applepay.csr file to your Apple account to create the Payment Processing Certificate. 

Download the apple_pay.cer file for the new Payment Processing Certificate and put it in the ./keys directory.

## 2. Prepare VGS Route Configuration
Run the `./prepare-yaml.sh` script. This script will prompt you for the following information:
- Whether or not this is for Production or Sandbox
- ApplePay Merchant ID (as specified in the Apple Dashboard)
- Vault Access Credentials Username and Password (Generated from VGS Dashboard)
- A secret passphrase for the new keystore

This script will create a file named `applepay.yaml` in the root of the repository.

Upload the generated yaml file to your VGS vault via the Dashboard or the VGS CLI.

