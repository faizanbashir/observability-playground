reg_name='kind-registry'
reg_port='5000'

echo "Create kind cluster"
./start-local.sh

echo "Installing Latest Version of Kubectl (on Mac)"
curl -LO "https://dl.k8s.io/release/v1.23.6/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv kubectl /usr/local/bin/kubectl
sudo chown root: /usr/local/bin/kubectl

#Installing Nginx Ingress
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/1.23/deploy.yaml"

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