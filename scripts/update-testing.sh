#!/bin/sh

# Implement pushd/popd function
CURR_DIR=`pwd`
cd /home/leonro/src/linux-rdma

# Read current branch and deal with detached HEAD
BRANCH_NAME=$(git symbolic-ref -q HEAD)
BRANCH_NAME=${BRANCH_NAME##refs/heads/}
BRANCH_NAME=${BRANCH_NAME:-HEAD}

LAST_TAG=`git tag| tail -n1`

# Reset HEAD
git co testing/rdma-linus
git reset --hard HEAD~1000
git merge --ff-only $LAST_TAG
# Need to add auto topic apply

# Reset HEAD
git co testing/rdma-next
git reset --hard HEAD~1000
git merge --ff-only $LAST_TAG

# Restore everything
git co $BRANCH_NAME
cd $CURR_DIR
