https://www.digitalocean.com/community/tutorials/recommended-steps-to-secure-a-digitalocean-kubernetes-cluster
From WSL:
```
openssl genrsa -out ./nate.key 4096
vim nate.csr.cnf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
[ dn ]
CN = nate
O = crandell
[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
EOF
openssl req -config ./nate.csr.cnf -new -key ./nate.key -nodes -out ./nate.csr
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: auth-nate
spec:
  groups:
  - system:authenticated
  request: $(cat nate.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
EOF
```
Then on km-1 verify, approve, and download the .crt file:
```
kubectl get csr
kubectl certificate approve auth-nate
kubectl get csr auth-nate -o jsonpath='{.status.certificate}' | base64 --decode > ~/kubernetes/certs/nate.crt
```
