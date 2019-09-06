#!/bin/bash
set -x # show output of commands

# The following commands run inside the Docker container
# used by Travis:

# Decrypt SSH key
openssl aes-256-cbc -K $encrypted_a9f5e5e6d65e_key -iv $encrypted_a9f5e5e6d65e_iv -in ./travis_ci_deploy_thesupertask_key.enc -out ./deploy_key -d
# Delete encrypted SSH key
rm ./travis_ci_deploy_thesupertask_key.enc
eval "$(ssh-agent -s)" # Use SSH commands
chmod 600 ./deploy_key # Access restrictions
# Allow user "deploy" to login without prompt
echo -e "Host $VPS_IP\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
# Use deploy_key as preferred SSH
ssh-add ./deploy_key