# Apple Pay VGS Integration Setup

Clone this repo to your local machine.

## 1. Generate Keys
Apple Pay requires ECC keys to be generated and uploaded to the Apple Dashboard.

To generate the keys, run the `./generate-keys.sh` script. The new keys will be put into the `./keys` directory.

Upload your new keys to your Apple account, download your applepay.cer file and put it in the ./keys directory.

## 2. Prepare VGS Route Configuration
Run the `./prepare-yaml.sh` script. This script will prompt you for the following information:
- Apple Merchant ID
- Vault Access Credentials Username and Password
- Whether or not is is for Production or Sandbox

Running this script successfully will create a file named `applepay.yaml` in the root of the repository.

Upload the generated yaml file to your VGS vault via the Dashboard or the VGS CLI.

