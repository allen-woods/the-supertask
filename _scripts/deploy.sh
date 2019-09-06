#!/bin/bash
set -x
echo "the deploy step has started..."

# Initialize a new git repo in _site, and push it to our server.
# mkdir _site && cd _site

git init
echo "!index.html" >> .gitignore
echo "!/src/**" >> .gitignore

git remote add deploy "ssh://deploy@$VPS_IP:/var/www/thesupertask.com.git"
# git config user.name "Travis CI"
# git config user.email "allen@thesupertask.com"

git add .
git commit -m "Deploy"
git push --set-upstream deploy master

echo "the deploy step has ended"