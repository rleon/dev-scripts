#!/bin/sh

# Implement pushd/popd function
CURR_DIR=`pwd`
cd /home/leonro/src/linux-rdma

# Read current branch and deal with detached HEAD
BRANCH_NAME=$(git symbolic-ref -q HEAD)
BRANCH_NAME=${BRANCH_NAME##refs/heads/}
BRANCH_NAME=${BRANCH_NAME:-HEAD}

git fetch linus
LAST_TAG=`git tag| tail -n1`

# Update master
git co master
# Don't create merge commit
git merge --ff-only $LAST_TAG

# Update rdma-linus
git co rdma-linus
git merge --ff-only $LAST_TAG

# Update rdma-next
git co rdma-next
git merge --ff-only $LAST_TAG

# Restore everything
git co $BRANCH_NAME
cd $CURR_DIR
