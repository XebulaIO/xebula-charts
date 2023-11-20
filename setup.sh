/+RSA="xebula-rsa"
NAME="xebula"

echo "Installing microk8s"
snap remove microk8s
snap install microk8s --classic
microk8s.enable dns rbac storage ingress
microk8s.config view > $HOME/.kube/config

# Create keycloak secret
keycloak=$(openssl rand -hex 16)
kubectl create secret generic keycloak --from-literal=secret="$keycloak"

# echo "Creating RSA keys"
openssl genrsa -out rsa.private 2048
openssl rsa -in rsa.private -out rsa.public -pubout -outform PEM
kubectl create secret generic ${RSA} --from-file=privatekey=rsa.private --from-file=publickey=rsa.public
rm rsa.private rsa.public

helm install ${NAME} . -f values.yaml