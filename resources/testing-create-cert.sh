# This is only to be used for testing purposes. The actual certificate should be downloaded from the apple pay website.
openssl x509 -req -in ../keys/applepay.csr -signkey ../keys/applepay.key -out ../keys/applepay.crt
openssl x509 -outform der -in ../keys/applepay.crt -out ../keys/apple_pay.cer

