#!/bin/bash

CA_CERT_PATH="/etc/ssl/CA/cacert.pem"
CA_KEY_PATH="/etc/ssl/CA/private/cakey.pem"
PASSPHRASE="captone"

# renew localhost.crt
openssl genrsa -out localhost.key 2048
expect <<EOD
    spawn openssl req -new -newkey localhost.key -out localhost.csr -subj "/C=US/ST=Massachusetts/L=Boston/O=Northeastern Univeristy/CN=localhost"

    spawn openssl ca -config /etc/ssl/CA/openssl.cnf -extensions v3_ca -days 365 -notext -md sha256 -in localhost.csr -out localhost.crt
    expect "Enter pass phrase for"
    send "$PASSPHRASE\r"
    expect "Sign the certificate? \[y/n\]:"
    send "y\r"
    expect "1 out of 1 certificate requests certified, commit? \[y/n\]"
    send "y\r"
    expect eof
EOD
rm localhost.csr
mv localhost.key /etc/ssl/private/localhost.key
mv localhost.crt /etc/ssl/certs/localhost.crt

# renew rabbitMQ.crt
openssl genrsa -out rabbitMQ.key 2048
expect <<EOD
    spawn openssl req -new -newkey rabbitMQ.key -out rabbitMQ.csr -subj "/C=US/ST=Massachusetts/L=Boston/O=Northeastern Univeristy/CN=rabbitMQ"

    spawn openssl ca -config /etc/ssl/CA/openssl.cnf -extensions v3_ca -days 365 -notext -md sha256 -in rabbitMQ.csr -out rabbitMQ.crt
    expect "Enter pass phrase for"
    send "$PASSPHRASE\r"
    expect "Sign the certificate? \[y/n\]:"
    send "y\r"
    expect "1 out of 1 certificate requests certified, commit? \[y/n\]"
    send "y\r"
    expect eof
EOD
rm rabbitMQ.csr
mv rabbitMQ.key /etc/ssl/CA/rabbitMQ.key
mv rabbitMQ.crt /etc/ssl/CA/rabbitMQ.crt

# renew platform.crt
openssl genrsa -out  platform.key 2048
expect <<EOD
    spawn openssl req -new -newkey platform.key -out platform.csr -subj "/C=US/ST=Massachusetts/L=Boston/O=Northeastern Univeristy/CN=OpenCTI"

    spawn openssl ca -config /etc/ssl/CA/openssl.cnf -extensions v3_ca -days 365 -notext -md sha256 -in platform.csr -out platform.crt
    expect "Enter pass phrase for"
    send "$PASSPHRASE\r"
    expect "Sign the certificate? \[y/n\]:"
    send "y\r"
    expect "1 out of 1 certificate requests certified, commit? \[y/n\]"
    send "y\r"
    expect eof
EOD
rm platform.csr
mv platform.key /etc/ssl/CA/platform.key
mv platform.crt /etc/ssl/CA/platform.crt

# renew worker.crt
openssl genrsa -out  worker1.key 2048
expect <<EOD
    spawn openssl req -new -newkey worker1.key -out worker1.csr -subj "/C=US/ST=Massachusetts/L=Boston/O=Northeastern Univeristy/CN=worker1"

    spawn openssl ca -config /etc/ssl/CA/openssl.cnf -extensions v3_ca -days 365 -notext -md sha256 -in worker1.csr -out worker1.crt
    expect "Enter pass phrase for"
    send "$PASSPHRASE\r"
    expect "Sign the certificate? \[y/n\]:"
    send "y\r"
    expect "1 out of 1 certificate requests certified, commit? \[y/n\]"
    send "y\r"
    expect eof
EOD
rm worker1.csr
mv worker1.key /etc/ssl/CA/worker1.key
mv worker1.crt /etc/ssl/CA/worker1.crt


#openssl genrsa -out test.key 2048
#expect <<EOD
#    spawn openssl req -new -newkey test.key -out test.csr -subj "/C=US/ST=Massachusetts/L=Boston/O=Northeastern Univeristy/CN=test"

#    spawn openssl ca -config /etc/ssl/CA/openssl.cnf -extensions v3_ca -days 365 -notext -md sha256 -in test.csr -out test.crt
#    expect "Enter pass phrase for"
#    send "$PASSPHRASE\r"
#    expect "Sign the certificate? \[y/n\]:"
#    send "y\r"
#    expect "1 out of 1 certificate requests certified, commit? \[y/n\]"
#    send "y\r"
#    expect eof
#EOD

# restart services
docker restart $(docker ps -a -q)
sudo systemctl reload nginx
