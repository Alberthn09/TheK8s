cd /Users/albertnguyen/Desktop/Alpha/Cloud/03_Project/

docker stop $(docker ps -aq)
docker rmi $(docker images -q)
docker system prune -af
docker network prune -f
docker volume prune -f

docker network create jenkins
docker network ls

docker volume create jenkins-docker-certs
docker volume create jenkins-data
docker volume ls

docker build -t my_image/jenkins -f $(pwd)/Jenkins/Dockerfile .

docker container run \
  --name jenkins-docker \
  --rm \
  --detach \
  --privileged \
  --network jenkins \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind

docker container run \
  --name jenkins-blueocean \
  --rm \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --mount type=bind,source="$(pwd)/scripts/",target="/root/scripts/" \
  my_image/jenkins

docker exec jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword


echo "Access Jenkins Docker Container"
docker exec -it jenkins-blueocean bin/bash

echo "Test configurations within Jenkins Docker Container"
aws configure list
aws-iam-authenticator help
helm version
python3 --version
pip3 list
kubectl version --short --client
kubectl config get-contexts
eksctl version
docker --version

echo "Compile NGINX Docker image and push to Docker Hub"
cd /root/scripts/NGINX
docker build -t alberthn/nginx-kubernetes .
docker push alberthn/nginx-kubernetes

echo "Compile Streamlit image and push to Docker Hub"
cd /root/scripts/Streamlit
docker build -t alberthn/streamlit-kubernetes .
docker push alberthn/streamlit-kubernetes


#docker build -t streamlit/test .
#docker container run \
#  --name streamlit-kubernetes \
#  -p 8501:8501 \
#  streamlit/test
#docker exec -it streamlit-kubernetes bin/bash


aws sts get-caller-identity
aws eks --region us-east-1 update-kubeconfig --name myekscluster
kubectl config get-contexts
kubectl config unset contexts.arn:aws:eks:us-east-1:667259643039:cluster/myekscluster

https://webage-account10.signin.aws.amazon.com/console
studentadmin
667259643039
anguyen
un3KBb4*7_BvWL_EX