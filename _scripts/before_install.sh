#!/bin/bash
set -x # show output of commands

# The following commands run inside the Docker container
# used by Travis:

# Decrypt SSH key
openssl aes-256-cbc -K $encrypted_a9f5e5e6d65e_key -iv $encrypted_a9f5e5e6d65e_iv -in travis_ci_deploy_thesupertask_key.enc -out ./deploy_key -d
# Delete encrypted SSH key
rm travis_ci_deploy_thesupertask_key.enc