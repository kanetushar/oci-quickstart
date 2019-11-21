#!/bin/bash

echo "${API_CREDS}" > ${GITHUB_WORKSPACE}/api_creds.yaml
echo $(cat ${GITHUB_WORKSPACE}/api_creds.yaml)


apt-get update
apt install -y build-essential unzip go-dep

#Installing terraform and upgrading code to Terraform 12
wget -q https://releases.hashicorp.com/terraform/0.12.10/terraform_0.12.10_linux_amd64.zip
unzip terraform_0.12.10_linux_amd64.zip -d /usr/bin
cd ${GITHUB_WORKSPACE}/terraform
terraform init && terraform 0.12upgrade -yes

#Set up environment for running terratest in go
mkdir -p $HOME/go/src/terratest/test
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:/usr/bin:$PATH
mv /quickstart-terraform_test.go $HOME/go/src/terratest/test
cd $HOME/go/src/terratest/test

#Install terratest and dependencies
cat  << EOF > Gopkg.toml
[[constraint]]
  name = "github.com/gruntwork-io/terratest"
  version = "0.19.1"
EOF

dep ensure

#Set up environment to run the terraform code
echo "${TF_VAR_private_key}" > ${GITHUB_WORKSPACE}/oci.pem
export TF_VAR_private_key_path=${GITHUB_WORKSPACE}/oci.pem
export TF_ACTION_WORKING_DIR=${GITHUB_WORKSPACE}/terraform

go test -v $HOME/go/src/terratest/test/quickstart-terraform_test.go -timeout 20m
