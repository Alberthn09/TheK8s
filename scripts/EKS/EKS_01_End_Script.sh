#!/bin/bash
echo "Cluster name"
CLUSTER_NAME=myekscluster
echo $CLUSTER_NAME

echo "Getting VPC ID"
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo $VPC_ID

echo "Deleting cluster"
eksctl delete cluster --name $CLUSTER_NAME

echo "Get file system id"
FILE_SYSTEM_ID=$(aws efs describe-file-systems --creation-token creation-token | jq --raw-output '.FileSystems[].FileSystemId')
echo $FILE_SYSTEM_ID

echo "Get mount targets"
mount_targets=($(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.MountTargets[].MountTargetId'))

echo "Delete mount targets for each subnet"
for mount_target in ${mount_targets[@]}
do
    echo "Delete mount target in " $mount_target
    aws efs delete-mount-target --mount-target-id $mount_target
done

echo "Get access point id"
ACCESS_POINT_ID=($(aws efs describe-access-points --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.AccessPoints[].AccessPointId'))
echo $ACCESS_POINT_ID

echo "Delete access point"
aws efs delete-access-point --access-point-id $ACCESS_POINT_ID

echo "Delete EFS"
aws efs delete-file-system --file-system-id $FILE_SYSTEM_ID

echo "Delete VPC"
aws ec2 delete-vpc --vpc-id VPC_ID

echo "Disconnect kubectl from EKS cluster"
kubectl config unset contexts.arn:aws:eks:us-east-1:667259643039:cluster/myekscluster
