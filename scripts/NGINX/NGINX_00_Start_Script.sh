#!/bin/bash
cat <<EoF > run-my-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
  namespace: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: alberthn/test-repo:latest
        ports:
        - containerPort: 80
EoF

echo "Exposed port 80"

echo "Create my-nginx namespace"
kubectl create ns my-nginx

echo "Deploy my-nginx deployment.yaml"
kubectl -n my-nginx apply -f run-my-nginx.yaml
rm run-my-nginx.yaml

echo "Create nginx service"
kubectl -n my-nginx expose deployment/my-nginx

echo "Set LoadBalancer for external traffic"
kubectl -n my-nginx patch svc my-nginx -p '{"spec": {"type": "LoadBalancer"}}'












