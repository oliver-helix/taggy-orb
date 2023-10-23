#!/bin/bash
# shellcheck disable=SC2004

infer_release_type_from_branch() {
  # check environment
  if [[ ! $CIRCLE_BRANCH ]]; then
    echo "CIRCLE_BRANCH variable required for function infer_release_type_from_branch"
    exit 1
  fi

  if [[ $CIRCLE_BRANCH =~ hotfix|patch ]]; then
    RELEASE_TYPE="patch"
  elif [[ $CIRCLE_BRANCH =~ minor ]]; then
    RELEASE_TYPE="minor"
  elif [[ $CIRCLE_BRANCH =~ major ]]; then
    RELEASE_TYPE="major"
  else
    echo "Unable to infer release-type from branch $CIRCLE_BRANCH"
    exit 1
  fi
  echo "$RELEASE_TYPE"
}

infer_is_release_candidate_from_branch() {
  # check environment
  if [[ ! $CIRCLE_BRANCH ]]; then
    echo "CIRCLE_BRANCH variable required for function infer_is_release_candidate_from_branch"
    exit 1
  fi

  IS_RELEASE_CANDIDATE=$([[ $CIRCLE_BRANCH =~ ^main|master$ ]] && echo false || echo true)
  echo "$IS_RELEASE_CANDIDATE"
}

infer_current_version() {
  CURRENT_VERSION=$(git tag --merged | sort -V | tail -1 2> /dev/null || echo "")
  CURRENT_VERSION=${CURRENT_VERSION:-v0.0.0}
  echo "$CURRENT_VERSION"
}

increment_current_version() {
  # check environment
  if [[ ! $CURRENT_VERSION ]]; then
    echo "CURRENT_VERSION variable required for function increment_current_version"
    exit 1
  elif [[ ! $RELEASE_TYPE ]]; then
    echo "RELEASE_TYPE variable required for function increment_current_version"
    exit 1
  fi

  # parse version parts from regex
  TAG_REGEX='v?([0-9]+)\.([0-9]+)\.([0-9]+)'
  if [[ "$CURRENT_VERSION" =~ $TAG_REGEX ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}

    # increment specified version part
    if [[ $RELEASE_TYPE == "major" ]]; then
      NEXT_VERSION="v$(($major+1)).0.0"
    elif [[ $RELEASE_TYPE == "minor" ]]; then
      NEXT_VERSION="v$major.$(($minor+1)).0"
    elif [[ $RELEASE_TYPE == "patch" ]]; then
      NEXT_VERSION="v$major.$minor.$(($patch+1))"
    else
      echo "Unknown RELEASE_TYPE $RELEASE_TYPE"
      exit 1
    fi
  else
    echo "Unable to parse CURRENT_VERSION $CURRENT_VERSION with regex $TAG_REGEX"
    exit 1
  fi
  echo "$NEXT_VERSION"
}

get_release_candidate() {
  if [[ ! $NEXT_VERSION ]]; then
    echo "NEXT_VERSION variable required for function get_release_candidate"
    exit 1
  fi

  for i in {1..999}; do
    RELEASE_CANDIDATE="$NEXT_VERSION-rc$i"
    [[ ! $(git tag --list "$RELEASE_CANDIDATE") ]] && break
  done
  echo "$RELEASE_CANDIDATE"
}

get_next_version() {
  # if not provided, infer release type from branch name
  if [[ ! $RELEASE_TYPE ]]; then
    RELEASE_TYPE=$(infer_release_type_from_branch)
  fi

  # if not provided, infer if release is a candidate from branch name
  if [[ ! $IS_RELEASE_CANDIDATE ]]; then
    IS_RELEASE_CANDIDATE=$(infer_is_release_candidate_from_branch)
  fi

  # if specified, use version from file
  if [[ $FILE ]]; then
    NEXT_VERSION=$(cat "$FILE")
  else
    CURRENT_VERSION=$(infer_current_version)
    NEXT_VERSION=$(increment_current_version)
  fi

  # if specified, add release candidate
  if $IS_RELEASE_CANDIDATE; then
    NEXT_VERSION=$(get_release_candidate)
  fi
  echo "$NEXT_VERSION"
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*"$ORB_TEST_ENV"}" == "$0" ]; then
    NEXT_VERSION=$(get_next_version)
    git tag -m "Tagging $CIRCLE_BRANCH with $NEXT_VERSION" "$NEXT_VERSION"
fi
