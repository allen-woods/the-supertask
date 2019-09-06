#!/bin/bash
set -x
echo "the deploy step has started..."

# Initialize a new git repo in _site, and push it to our server.
cd _site
git init

git remote add deploy "deploy@thesupertask.com:/var/www/thesupertask.com"
git config user.name "Travis CI"
git config user.email "allen@thesupertask.com"

git add .
git commit -m "Deploy"
git push --force deploy master

echo "the deploy step has ended"