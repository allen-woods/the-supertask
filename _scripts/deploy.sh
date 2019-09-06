#!/bin/bash
set -x
echo "the deploy step has started..."
if [ $TRAVIS_BRANCH == 'master' ] ; then

  # Initialize a new git repo in _site, and push it to our server.
  cd _site
  git init

  git remote add deploy "deploy@$VPS_IP:/var/www/thesupertask.com"
  git config user.name "Travis CI"
  git config user.email "allen@thesupertask.com"

  git add .
  git commit -m "Deploy"
  git push --force deploy master
else
  echo "Not Deployed: branch must be master"
fi
echo "the deploy step has ended"