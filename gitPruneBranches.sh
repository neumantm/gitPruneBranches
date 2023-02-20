#!/usr/bin/env bash

function fail() {
  echo $1
  exit $2
}

function printUsage() {
  echo "Usage:"
  echo "$0 [options]"
  echo ""
  echo 'This script is an alternative to `git branch -d --merged <defaultBranch>`,'
  echo "as that does not work when commits are squashed or rebased on the server."
  echo ""
  echo "It always prunes remote tracking branches."
  echo "It never deletes branches that are present at the default remote."
  echo "It always deletes branches, where the last local commit has been pushed."
  echo "It only deletes branches that were not pushed yet or that contain unpushed commits if --include-unpushed is specified."
  echo ""
  echo "This script relies on the infos stored by the remote tracking branches."
  echo "So do not delete/prune them, or we cannot determine which branches are safe to delete."
  echo "If you did that by accident, you can recover by using --include-unpushed."
  echo ""
  echo "Possible options:"
  echo "-h --help               Print this help"
  echo "-r --remote <remote>    Use the specified remote to check for existence of branches"
  echo "   --include-unpushed   Include unpushed branches. Warning: This WILL delete branches with local changes if they are not (yet) on the remote."
}

GIT_DIR="$(realpath "$(git rev-parse --git-dir)")"
TMP_REMOTE_TRACKING_OIDS="$GIT_DIR/.deletetOldBranches_remote_tracking_oids/"

includeUnpushed="false"
remote=""

nextArgumentIsRemote=false

if [ $# -gt 0 ] ;then
  for var in "$@" ;do
    if $nextArgumentIsRemote ;then
      remote="$var"
      nextArgumentIsRemote=false
    elif [ "$var" == "-h" ] || [ "$var" == "--help" ] ;then
      printUsage
      exit 0
    elif [ "$var" == "-r" ] || [ "$var" == "--remote" ] ;then
      nextArgumentIsRemote=true
    elif [ "$var" == "--include-unpushed" ] ;then
      includeUnpushed="true"
    else
      printUsage
      exit 2
    fi
  done
fi

if [ "$remote" = "" ] ;then
  configuredRemotes="$(git remote)"
  if [ ${#configuredRemotes} -eq 0 ] ;then
    fail "Could not find a remote. Aborting" 1
  fi
  countOfConfiguredRemotes="$(echo "$configuredRemotes" | wc -l)"
  if [ $countOfConfiguredRemotes -eq 1 ] ;then
    remote="$configuredRemotes"
  else
    if echo "$configuredRemotes" | grep -xq "origin" ;then
      remote="origin"
    else
      fail "Could not determine default remote. Please specify remote. Aborting" 1
    fi
  fi
fi

echo "Using remote: $remote"

# Store which branches were pushed/fetched with which oid
rm -rf "$TMP_REMOTE_TRACKING_OIDS"
while IFS= read -r branch; do
  if upstream=$(git rev-parse "$branch@{u}" 2>/dev/null); then
    mkdir --parents "$(dirname "$TMP_REMOTE_TRACKING_OIDS/$branch")"
    echo "$upstream" > "$TMP_REMOTE_TRACKING_OIDS/$branch"
  fi
done < <(git branch --format '%(refname:lstrip=2)')

# Delete all the origin/xyz branches
git remote prune "$remote"

# Delete all branches where we do not find a reason to keep

while IFS= read -r branch; do
  remoteExists="$(git ls-remote "$remote" "$branch" | wc -l)"
  if [ "$remoteExists" == "1" ] ;then
    # Remote exists do not delete
    continue
  fi
  if [ "$includeUnpushed" == "false" ] ;then
    if ! test -f "$TMP_REMOTE_TRACKING_OIDS/$branch" ;then
      #Was never pushed, do not delete
      continue
    fi
    currentOid="$(git rev-parse "$branch")"
    pushedOid="$(cat "$TMP_REMOTE_TRACKING_OIDS/$branch")"
    if [ "$currentOid" != "$pushedOid" ] ;then
      #Current commit is different from last pushed commit, do not delete
      continue
    fi
  fi
  git branch -D "$branch"
done < <(git branch --format '%(refname:lstrip=2)')
