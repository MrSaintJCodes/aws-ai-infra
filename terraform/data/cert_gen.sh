# Create a directory to store the certs
#mkdir -p certs

# Generate private key and self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/lab.key \
  -out certs/lab.crt \
  -subj "/C=CA/ST=Quebec/L=Montreal/O=Lab/CN=lab.local"

# Generate certificate chain (self-signed so chain = cert itself)
cp certs/lab.crt certs/lab-chain.crt
