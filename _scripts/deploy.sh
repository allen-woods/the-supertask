#!/bin/bash
set -x
echo "the deploy step has started..."

eval "$(ssh-agent -s)" # Use SSH commands
chmod 600 ./deploy_key # Remove access restrictions
# Allow user "deploy" to login without prompt
echo -e "Host $VPS_IP\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
# Use deploy_key as preferred SSH identity
ssh-add ./deploy_key

# Initilize the repo
git init

# Whitelist only the items we want to push
echo "!/assets/**" >> .gitignore
echo "!/css/**" >> .gitignore
echo "!/js/**" >> .gitignore
echo "!/textures/**" >> .gitignore
echo "!index.html" >> .gitignore

# Add the deploy and configure it
git remote add deploy "$VPS_USER@$VPS_IP:$VSP_UPSTREAM"
git config user.name "Travis CI"
git config user.email "$VPS_EMAIL"

# Stage, commit, and push
git add .
git commit -m "Deploy"
git push --set-upstream deploy master

echo "the deploy step has ended"