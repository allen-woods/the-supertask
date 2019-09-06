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
echo "!index.html" >> .gitignore
echo "!/src/**" >> .gitignore

# Add the deploy and configure it
git remote add deploy "deploy@$VPS_IP:/var/www/thesupertask.com/.git"
git config user.name "Travis CI"
git config user.email "allen@thesupertask.com"

# Stage, commit, and push
git add .
git commit -m "Deploy"
git push --set-upstream deploy master

echo "the deploy step has ended"