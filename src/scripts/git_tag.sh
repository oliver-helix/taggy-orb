#!/bin/bash
# shellcheck disable=SC2004

infer_release_type() {
  # check environment
  [[ ! $CIRCLE_BRANCH ]] && { echo "CIRCLE_BRANCH variable required"; exit 1; }

  if [[ $CIRCLE_BRANCH =~ hotfix|patch ]]; then
    echo patch
  elif [[ $CIRCLE_BRANCH =~ minor ]]; then
    echo minor
  elif [[ $CIRCLE_BRANCH =~ major ]]; then
    echo major
  else
    echo "Unable to infer release-type from branch $CIRCLE_BRANCH"
    exit 1
  fi
}

infer_release_candidate() {
  # check environment
  [[ ! $CIRCLE_BRANCH ]] && { echo "CIRCLE_BRANCH variable required"; exit 1; }

  [[ $CIRCLE_BRANCH =~ ^main|master$ ]] && echo false || echo true
}

infer_current_version() {
  CURRENT_VERSION=$(git tag --merged | sort -V | tail -1 2> /dev/null || echo "")
  CURRENT_VERSION=${CURRENT_VERSION:-v0.0.0}
  echo "$CURRENT_VERSION"
}


get_tag() {
  # if not provided, infer release type
  if [[ ! $RELEASE_TYPE ]]; then
    RELEASE_TYPE=$(infer_release_type)
  fi

  # if not provided, infer release candidate
  if [[ ! $RELEASE_CANDIDATE ]]; then
    RELEASE_CANDIDATE=$(infer_release_candidate)
  fi

  # if not provided, infer current version
  if [[ ! $CURRENT_VERSION ]]; then
    CURRENT_VERSION=$(infer_current_version)
  fi

  # parse version parts from regex
  TAG_REGEX='v?([0-9]+)\.([0-9]+)\.([0-9]+)(-rc\.?([0-9]+))?'
  if [[ "$CURRENT_VERSION" =~ $TAG_REGEX ]]; then
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
    else
      echo "Unknown RELEASE_TYPE $RELEASE_TYPE"
      exit 1
    fi

    # if specified, mark release candidate (and bump previous if exists)
    if $RELEASE_CANDIDATE; then
      NEWTAG=$NEWTAG-rc$((${release_candidate:-0}+1))
    fi
  else
    echo "Unable to parse CURRENT_VERSION $CURRENT_VERSION with regex $TAG_REGEX."
    exit 1
  fi
  echo "$NEWTAG"
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*"$ORB_TEST_ENV"}" == "$0" ]; then
    NEWTAG=$(get_tag)
    git tag -m "Tagging $CIRCLE_BRANCH with $NEWTAG" "$NEWTAG"
fi