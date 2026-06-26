# TLS Certificates

## Problem

The Kasm installer generates a cert with **hostname only** in SAN. Users accessing via IP (`https://10.0.5.36:9443`) get cert mismatch warnings.

## Fix

Regenerate `/opt/kasm/current/certs/kasm_nginx.{crt,key}` with IP and DNS SANs, then restart Kasm.

```bash
SERVER_IP=$(hostname -I | awk '{print $1}')
HOST=$(hostname)

sudo tee /tmp/kasm-openssl.cnf >/dev/null <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = VA
O = Kontratar
CN = $HOST
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = $HOST
DNS.2 = ubuntu-base
IP.1 = $SERVER_IP
IP.2 = 127.0.0.1
EOF

sudo openssl req -x509 -nodes -days 1825 -newkey rsa:2048 \
  -keyout /opt/kasm/current/certs/kasm_nginx.key \
  -out /opt/kasm/current/certs/kasm_nginx.crt \
  -config /tmp/kasm-openssl.cnf -extensions v3_req

sudo chown kasm:kasm /opt/kasm/current/certs/kasm_nginx.key /opt/kasm/current/certs/kasm_nginx.crt
sudo chmod 600 /opt/kasm/current/certs/kasm_nginx.key /opt/kasm/current/certs/kasm_nginx.crt
sudo /opt/kasm/bin/stop && sudo /opt/kasm/bin/start
```

## When to re-run

- Server IP changes (OCI reassignment)
- Hostname changes
- Cert expiry (1825 days from generation)

## Recommendation for users

Prefer **HTTP on 8090** for daily use. Reserve 9443 for admin or users who accept self-signed HTTPS.

## Verify

```bash
openssl s_client -connect 127.0.0.1:9443 </dev/null 2>/dev/null | openssl x509 -noout -subject -ext subjectAltName
```
