FROM jenkinsci/blueocean:latest
USER root

# Install Needed Packages
RUN apk update && apk upgrade && apk add git curl unzip less jq vim python3 py-pip ca-certificates openssl && rm -rf /var/lib/apt/lists/*
# Move certifictes over
# COPY ZscalerRootCertificate-2048-SHA256.cer /usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.cer
# RUN update-ca-certificates --fresh

# Set Up Docker
#COPY configuration/docker_credential.txt ./docker_credential.txt
#RUN cat ./docker_credential.txt | docker login --username alberthn --password-stdin
#RUN rm ./docker_credential.txt
RUN mkdir /root/.docker/
COPY configuration/docker_config.json /root/.docker/config.json

# Create Scripts Working Folder
RUN mkdir /root/scripts/

# Install AWS CLI
RUN curl -o "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && unzip awscliv2.zip && ./aws/install
RUN rm ./awscliv2.zip
RUN mkdir /root/.aws/
COPY configuration/credentials /root/.aws/credentials
COPY configuration/config /root/.aws/config

# Install AWS IAM Authenticator
RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.8/2020-09-18/bin/linux/amd64/aws-iam-authenticator && chmod +x ./aws-iam-authenticator && cp ./aws-iam-authenticator ./bin/aws-iam-authenticator
RUN rm ./aws-iam-authenticator

# Install Kubectl
RUN curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.8/2020-09-18/bin/linux/amd64/kubectl && chmod +x ./kubectl && cp ./kubectl ./bin/kubectl
RUN rm ./kubectl

# Install eksctl
RUN curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && chmod +x /tmp/eksctl && cp /tmp/eksctl ./bin/eksctl
RUN rm ./tmp/eksctl

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh
RUN rm ./get_helm.sh

# Install Boto3
RUN pip install --upgrade pip && pip install boto3

# Install Jenkins Plug Ins
RUN /usr/local/bin/install-plugins.sh docker-slaves github-branch-source:1.8

# Run as Jenkins user
#USER jenkins