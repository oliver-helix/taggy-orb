setup() {
    source ./src/scripts/git_tag.sh
}

@test 'infer_release_type 1: hotfix' {
    export CIRCLE_BRANCH=hotfix
    run infer_release_type
    echo $output
    [ "$output" = "patch" ]
}

@test 'infer_release_type 2: CIRCLE_BRANCH not defined' {
    run infer_release_type
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "CIRCLE_BRANCH variable required" ]
}

@test 'infer_release_type 3: bad branch name' {
    export CIRCLE_BRANCH=bad
    run infer_release_type
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unable to infer release-type from branch $CIRCLE_BRANCH" ]
}

@test 'infer_release_candidate 1' {
    export CIRCLE_BRANCH=main
    run infer_release_candidate
    echo $output
    [ "$output" = false ]
}

@test 'infer_release_candidate 2' {
    export CIRCLE_BRANCH=not-main
    run infer_release_candidate
    echo $output
    [ "$output" = true ]
}

@test 'infer_current_version 1' {
    # not sure how to test git here without a bunch of random tags...
    run infer_current_version
    echo $output
    [ "$output" = "v0.0.0" ]
}

@test 'get_tag 1: Bad RELEASE_TYPE value' {
    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="bad"
    run get_tag
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unkown RELEASE_TYPE bad" ]
}

@test 'get_tag 2: Bad CURRENT_VERSION value' {
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="bad"
    run get_tag
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unable to parse CURRENT_VERSION bad with regex $TAG_REGEX." ]
}

@test 'get_tag 3: patch' {
    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4" ]
}

@test 'get_tag 4: minor' {
    export RELEASE_TYPE="minor"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.3.0" ]
}

@test 'get_tag 5: major' {
    export RELEASE_TYPE="major"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v2.0.0" ]
}

@test 'get_tag 6: release-candidate' {
    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="not-main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4-rc1" ]
}

@test 'get_tag 7: release-candidate increment' {
    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="not-main"
    export CURRENT_VERSION="v1.2.3-rc1"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4-rc2" ]
}

@test 'get_tag 8: RELEASE_CANDIDATE overwrite' {
    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="not-main"  # should be release-candidate
    export RELEASE_CANDIDATE="true"  # overwrite
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4-rc1" ]
}

@test 'get_tag 9: RELEASE_TYPE overwrite' {
    export CIRCLE_BRANCH="fix/patch"  # should be patch
    export RELEASE_TYPE="minor"  # overwrite
    export RELEASE_CANDIDATE=false
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.3.0" ]
}
