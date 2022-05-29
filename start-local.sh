#!/bin/sh
#
# https://kind.sigs.k8s.io/docs/user/local-registry/
set -o errexit

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5000'
k8s_full_version='v1.23.6'
k8s_version='v1.23'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
# also add a port mapping for the ingress https://kind.sigs.k8s.io/docs/user/ingress/
cat <<EOF | kind create cluster --image kindest/node:${k8s_full_version} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:5000"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

###
### Setup Ingress

K8S_VERSION=$(kubectl version --short | grep "Server Version" | grep -Eo "v[0-9]\.[0-9]{1,2}" | grep -Eo "[0-9]\.[0-9]{1,2}")

echo "Installing Latest Version of Kubectl (on Mac)"
curl -LO "https://dl.k8s.io/release/${k8s_full_version}/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv kubectl /usr/local/bin/kubectl
sudo chown root: /usr/local/bin/kubectl

kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/${k8s_version}/deploy.yaml"


echo "Build, Tag and Push Docker image for Backend"
docker build ./src/backend -t localhost:${reg_port}/python-guestbook-backend
docker image push localhost:${reg_port}/python-guestbook-backend
echo "Build, Tag and Push Docker image for Frontend"
docker build ./src/frontend -t localhost:${reg_port}/python-guestbook-frontend
docker image push localhost:${reg_port}/python-guestbook-frontend

echo "Applying manifests"
kubectl apply -f ./src/backend/kubernetes-manifests/
kubectl apply -f ./src/frontend/kubernetes-manifests/

echo "Check if the services are running"
curl localhost:80 -I

echo "Waiting for 15 secs before deploying the monitoring setup"

sleep 15

./deploy-monitoring.sh