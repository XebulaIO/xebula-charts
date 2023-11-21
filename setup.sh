#!/bin/bash

RSA="xebula-rsa"
NAME="xebula"

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
microk8s.enable dns rbac storage ingress
microk8s.config view > $HOME/.kube/config

#buralar düzeltilecek 
kubectl create -f /home/latif/temp/sendgrid-secret.yaml
kubectl create -f /home/latif/temp/jwt-secret.yaml


# Create keycloak secret
echo "Generating keycloak secret" 
keycloak=$(openssl rand -hex 16)
kubectl create secret generic keycloak --from-literal=secret="$keycloak"

echo "Creating RSA keys"
openssl genrsa -out rsa.private 2048
openssl rsa -in rsa.private -out rsa.public -pubout -outform PEM
kubectl create secret generic ${RSA} --from-file=privatekey=rsa.private --from-file=publickey=rsa.public
rm rsa.private rsa.public

echo "Installing charts"
cd /home/latif
echo oldu
echo ${NAME}
helm install ${NAME} . -f values.yaml