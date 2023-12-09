#!/bin/bash

RSA="xebula-rsa"
NAME="xebula"
HOSTNAME="xebula.online"
CRT="xebula-crt"

#kubectl
echo "Installling kubectl..."
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
mv kubectl /usr/local/bin
chmod 755 /usr/local/bin/kubectl

#helm
echo "Installling helm..."
wget https://get.helm.sh/helm-v${HELM}-linux-amd64.tar.gz
tar xvzf helm-v${HELM}-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin
chmod 755 /usr/local/bin/helm
rm -rf linux-amd64
rm -rf helm-v${HELM}-linux-amd64.tar.gz

#microk8s
echo "Installing microk8s"
snap remove microk8s
snap install microk8s --classic
microk8s.enable dns
microk8s.enable rbac
microk8s.enable storage
microk8s.enable ingress
microk8s.config view > $HOME/.kube/config

kubectl annotate ingressclass nginx meta.helm.sh/release-name=${NAME}
kubectl annotate ingressclass nginx meta.helm.sh/release-namespace=default
kubectl label ingressclass nginx app.kubernetes.io/managed-by=Helm


echo "Installing cert-manager"
#kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.2/cert-manager.crds.yaml
#kubectl label namespace default certmanager.k8s.io/disable-validation="true"

# echo "Creating self-signed cert"
echo "[req]" > crt.config
echo "distinguished_name=req" >> crt.config
echo "[san]" >> crt.config
echo "subjectAltName=DNS:${HOSTNAME}" >> crt.config
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes -keyout rpa.pem -out rpa.crt -subj "/CN=${HOSTNAME}" -extensions san -config crt.config
rm crt.config

# echo "Installing TLS certificate"
kubectl create secret tls ${CRT} --cert=./rpa.crt --key=./rpa.pem
rm rpa.crt rpa.pem


#buralar düzeltilecek 
kubectl create -f /home/latif/temp/sendgrid-secret.yaml


# Create keycloak secret
# echo "Generating keycloak secret" 
# keycloak=$(openssl rand -hex 16)
# kubectl create secret generic keycloak --from-literal=secret="$keycloak"

echo "Creating RSA keys"
openssl genrsa -out rsa.private 2048
openssl rsa -in rsa.private -out rsa.public -pubout -outform PEM
kubectl create secret generic ${RSA} --from-file=privatekey=rsa.private --from-file=publickey=rsa.public
rm rsa.private rsa.public

echo "Installing charts"
helm install ${NAME} . -f values.yaml