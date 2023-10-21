#!/bin/bash

CIRCLECI_EXAMPLE_PARAMETER_RELEASE_TYPE="minor"
CIRCLECI_EXAMPLE_PARAMETER_RELEASE_CANDIDATE=""
CIRCLE_BRANCH=main

# get release type
if [[ $CIRCLE_BRANCH =~ hotfix|patch ]]; then
  INFERRED_RELEASE_TYPE="patch"
elif [[ $CIRCLE_BRANCH =~ minor ]]; then
  INFERRED_RELEASE_TYPE="minor"
elif [[ $CIRCLE_BRANCH =~ major ]]; then
  INFERRED_RELEASE_TYPE="major"
fi
RELEASE_TYPE=$CIRCLECI_EXAMPLE_PARAMETER_RELEASE_TYPE
RELEASE_TYPE=${RELEASE_TYPE:-$INFERRED_RELEASE_TYPE}

if [[ ! $RELEASE_TYPE ]]; then
  echo "Unable to infer release-type from branch $CIRCLE_BRANCH. Please provide release-type parameter."
  exit 1
fi
# echo "export RELEASE_TYPE=$RELEASE_TYPE" >> $BASH_ENV

# get release candidate
INFERRED_RELEASE_CANDIDATE=false
if [[ ! $CIRCLE_BRANCH =~ ^main|master$ ]]; then
  INFERRED_RELEASE_CANDIDATE=true
fi
RELEASE_CANDIDATE=$CIRCLECI_EXAMPLE_PARAMETER_RELEASE_CANDIDATE
RELEASE_CANDIDATE=${RELEASE_CANDIDATE:-$INFERRED_RELEASE_CANDIDATE}

if [[ ! $RELEASE_CANDIDATE ]]; then
  echo "Unable to infer release-candidate from branch $CIRCLE_BRANCH. Please provide release-candidate parameter."
  exit 1
fi

# echo "export RELEASE_CANDIDATE=$RELEASE_CANDIDATE" >> ${BASH_ENV}

# tag
LATESTTAG=$(git tag --merged | sort -V | tail -1)
LATESTTAG=${LATESTTAG:-v0.0.0}

# parse version parts from regex
TAG_REGEX='v?([0-9]+)\.([0-9]+)\.([0-9]+)(-rc\.?([0-9]+))?'
if [[ "$LATESTTAG" =~ $TAG_REGEX ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
  release_candidate=${BASH_REMATCH[5]}

  # increment specified version part
  if [[ $RELEASE_TYPE == "major" ]]; then
    NEWTAG="v$(($major+1)).0.0"
  elif [[ $RELEASE_TYPE == "minor" ]]; then
    NEWTAG="v$major.$(($minor+1)).0"
  elif [[ $RELEASE_TYPE == "patch" ]]; then
    NEWTAG="v$major.$minor.$(($patch+1))"
  fi
  # if specified, mark release candidate (and bump previous if exists)
  if $RELEASE_CANDIDATE; then
    NEWTAG=$NEWTAG-rc$((${release_candidate:-0}+1))
  fi
else
  echo "Unable to parse tag $LATESTTAG with regex $TAG_REGEX"
  exit 1
fi

# tag commit
echo "Tagging $CIRCLE_BRANCH with $NEWTAG"
# git tag -m "Tagging $CIRCLE_BRANCH with $NEWTAG" "$NEWTAG"