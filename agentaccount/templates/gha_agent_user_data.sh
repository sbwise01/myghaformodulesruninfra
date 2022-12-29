#!/usr/bin/env bash

## Installation
mkdir /var/actions-runner && cd /var/actions-runner

curl -o actions-runner-linux-x64-2.299.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.299.1/actions-runner-linux-x64-2.299.1.tar.gz

tar xzf ./actions-runner-linux-x64-2.299.1.tar.gz

curl -o terraform_1.1.0_linux_amd64.zip  -L https://releases.hashicorp.com/terraform/1.1.0/terraform_1.1.0_linux_amd64.zip

unzip terraform_1.1.0_linux_amd64.zip

mv terraform /usr/local/bin/terraform

chown -R ec2-user.ec2-user /var/actions-runner

## Authn configuration
runuser -l ec2-user -c '/var/actions-runner/config.sh --unattended --url "${gha_agent_repo_url}" --token "${gha_agent_token}"'

## Run the agent
/var/actions-runner/svc.sh install
/var/actions-runner/svc.sh start
