#!/bin/bash
set -e

echo "Installing hugo..."
go get -u -v github.com/spf13/hugo

echo "Cloning themes..."
git clone https://github.com/jpescador/hugo-future-imperfect ./themes/hugo-future-imperfect

echo "Building static site..."
hugo

echo "Deploying to github page branch..."

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
REPO=$(git config remote.origin.url)
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=$(git rev-parse --verify HEAD)

echo "REPO: ${REPO}"
echo "SSH_REPO: ${SSH_REPO}"
echo "SHA: ${SHA}"

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
if [ ! -d "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR ($SOURCE_DIR) does not exist, build the source directory before deploying"
  exit 1
fi

cd public

# If there are no changes to the compiled output
if [ -z `git diff --exit-code`  ]; then
	echo "No changes to the output on this push; exiting."
	exit 0
fi

git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

# Commit generated static site
git status
git add -A .
git commit -m "Deploy to GitHub pages: ${SHA}"

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
echo "Adding deploy key to ssh-agent..."
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

echo "Pushing changes to ${REPO} ${TARGET_BRANCH}"
git push $REPO $TARGET_BRANCH
