#!/bin/bash
echo "Cluster name"
CLUSTER_NAME=myekscluster
echo $CLUSTER_NAME

echo "Creating cluster "
eksctl create cluster --name $CLUSTER_NAME --region us-east-1 --zones us-east-1a,us-east-1b --managed --nodegroup-name mynodegroup

echo "Checking if kubectl is configured"
aws eks --region us-east-1 update-kubeconfig --name $CLUSTER_NAME
# Check if kubectl is able to get services
# kubectl config get-contexts
# kubectl config unset contexts.arn:aws:eks:us-east-1:667259643039:cluster/myekscluster
kubectl get svc

echo "Getting VPC ID"
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo $VPC_ID

echo "Creating security group"
aws ec2 create-security-group --region us-east-1 --group-name efs-mount-sg --description "Amazon EFS for EKS, SG for mount target" --vpc-id $VPC_ID
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filter Name=group-name,Values=efs-mount-sg | jq --raw-output '.SecurityGroups[].GroupId')
echo $SECURITY_GROUP_ID 

echo "Authorize security group"
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --region us-east-1 --protocol tcp --port 2049 --cidr 192.168.0.0/16

echo "Create EFS file system"
aws efs create-file-system --creation-token creation-token --performance-mode generalPurpose --throughput-mode bursting --region us-east-1 --tags Key=Name,Value=MyEFSFileSystem --encrypted
FILE_SYSTEM_ID=$(aws efs describe-file-systems --creation-token creation-token | jq --raw-output '.FileSystems[].FileSystemId')
echo $FILE_SYSTEM_ID

echo "Getting subnet information"
TAG1=tag:kubernetes.io/cluster/$CLUSTER_NAME
TAG2=tag:kubernetes.io/role/elb
subnets=($(aws ec2 describe-subnets --filters "Name=$TAG1,Values=shared" "Name=$TAG2,Values=1" | jq --raw-output '.Subnets[].SubnetId'))
echo "Creating a mount target for each subnet"
for subnet in ${subnets[@]}
do
    echo "Creating mount target in " $subnet
    aws efs create-mount-target --file-system-id $FILE_SYSTEM_ID --subnet-id $subnet --security-group $SECURITY_GROUP_ID --region us-east-1
done

echo "Getting access point information"
aws efs create-access-point --file-system-id $FILE_SYSTEM_ID --posix-user Uid=1000,Gid=1000 --root-directory "Path=/jenkins,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=777}"
ACCESS_POINT_ID=$(aws efs describe-access-points --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.AccessPoints[].AccessPointId')
echo $ACCESS_POINT_ID
FILE_SYSTEM_AND_ACCESS_POINT="${FILE_SYSTEM_ID}::${ACCESS_POINT_ID}"
echo $FILE_SYSTEM_AND_ACCESS_POINT

echo "Gettng EFS CSI driver repo"
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

#echo "Gettng EFS CSI driver repo"
#helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/

#echo "Installing EFS CSI drivers. Wait 10 min for pods to run"
#sleep 300
#helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver
sleep 300

echo "Creating EFS persistent volume YAML file"

cat <<EOF > efs-pvc.yaml
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: EFS_VOLUME_ID

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
EOF

echo "Updating EFS persistent volume YAML file"
sed -i "s/EFS_VOLUME_ID/$FILE_SYSTEM_AND_ACCESS_POINT/g" efs-pvc.yaml
#sed -i "" "s/EFS_VOLUME_ID/$FILE_SYSTEM_AND_ACCESS_POINT/g" efs-pvc.yaml
cat efs-pvc.yaml

echo "Applying EFS persistent volume YAML file. Wait 1 min for settings"
kubectl apply -f efs-pvc.yaml
sleep 60

echo "Delete efs-pvc.yaml file"
rm efs-pvc.yaml

echo "Checking services created"
kubectl get sc,pv,pvc

echo "Getting Helm and Bitnami Repos"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://kubernetes-charts.storage.googleapis.com/

echo "Installing Jenkins"
helm install jenkins stable/jenkins --set rbac.create=true,master.servicePort=80,master.serviceType=LoadBalancer,persistence.existingClaim=efs-claim
sleep 300

echo "Get load balancer details"
printf $(kubectl get service jenkins -o jsonpath="{.status.loadBalancer.ingress[].hostname}");echo

echo "Get Jenkins password"
printf $(kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

echo "EKS deployment completed"

