#!/bin/bash
set -e

### Variable definitions
if [[ -z $SOURCE_BRANCH ]]; then
	SOURCE_BRANCH="master"
fi
if [[ -z $TARGET_BRANCH ]]; then
	TARGET_BRANCH="gh-pages"
fi
if [[ -z $ENCRYPTION_LABEL ]]; then
	ENCRYPTION_LABEL="1e2d135be8b5"
fi
if [[ -z $SOURCE_DIR ]]; then
	SOURCE_DIR="public"
fi
if [[ -z $GIT_NAME ]]; then
	GIT_NAME="Kidon Chu"
fi
if [[ -z $GIT_EMAIL ]]; then
	GIT_EMAIL="kidonchu@gmail.com"
fi
SHA=$(git rev-parse --verify HEAD)

### Validations
# Pull requests and commits to other branches shouldn't try to deploy
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
	echo "No deploy is needed for pull request; exiting."
	exit 0
fi
if [[ "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]]; then
	echo "Travis branch doesn't match with source branch; exiting."
	exit 0
fi
# if [ ! -d "$SOURCE_DIR" ]; then
#   echo "SOURCE_DIR ($SOURCE_DIR) does not exist, build the source directory before deploying"
#   exit 1
# fi

echo "Adding deploy key to ssh-agent..."
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Create public folder to put generated static site
mkdir public
cd public
git clone https://github.com/kidonchu/somethingnew .
git checkout $TARGET_BRANCH

cd ..
echo "Building static site..."
hugo

cd public
echo "$(pwd)"
git status

# If there are no changes to the compiled output
if [ -z "$(git diff --exit-code)"  ]; then
	echo "No changes to the output on this push; exiting."
	exit 0
fi

git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

REPO=$(git config remote.origin.url)
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

echo "REPO: $REPO"
echo "SSH_REPO: $SSH_REPO"

# Commit generated static site
git add -A .
git commit -m "Deploy to GitHub pages: ${SHA}"

echo "Pushing changes to ${SSH_REPO} ${TARGET_BRANCH}"
git push $SSH_REPO $TARGET_BRANCH
