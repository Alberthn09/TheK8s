#!/bin/bash
cat <<EoF > run-streamlit.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: streamlit
  namespace: streamlit
spec:
  selector:
    matchLabels:
      run: streamlit
  replicas: 2
  template:
    metadata:
      labels:
        run: streamlit
    spec:
      containers:
      - name: streamlit
        image: alberthn/streamlit-kubernetes
        ports:
        - containerPort: 80
EoF

echo "Exposed port 80"

echo "Create streamlit namespace"
kubectl create ns streamlit

echo "Deploy streamlit deployment.yaml"
kubectl -n streamlit apply -f run-streamlit.yaml
rm run-streamlit.yaml

echo "Create nginx service"
kubectl -n streamlit expose deployment/streamlit

echo "Set LoadBalancer for external traffic"
kubectl -n streamlit patch svc streamlit -p '{"spec": {"type": "LoadBalancer"}}'












