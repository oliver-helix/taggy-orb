setup() {
    source ./src/scripts/git_tag.sh
}

function infer_release_type_1 { #@test
    # test hotfix parsed into patch

    export CIRCLE_BRANCH=hotfix
    run infer_release_type
    echo $output
    [ "$output" = "patch" ]
}

function infer_release_type_2 { #@test
    # test that CIRCLE_BRANCH must be defined

    unset CIRCLE_BRANCH
    run infer_release_type
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "CIRCLE_BRANCH variable required" ]
}

function infer_release_type_3 { #@test
    # test unparsable git branch name

    export CIRCLE_BRANCH=bad
    run infer_release_type
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unable to infer release-type from branch $CIRCLE_BRANCH" ]
}

function infer_release_candidate_1 { #@test
    export CIRCLE_BRANCH=main
    run infer_release_candidate
    echo $output
    [ "$output" = false ]
}

function infer_release_candidate_2 { #@test
    export CIRCLE_BRANCH=not-main
    run infer_release_candidate
    echo $output
    [ "$output" = true ]
}

function infer_current_version_1 { #@test
    # not sure how to test git here without a bunch of random tags...

    run infer_current_version
    echo $output
    [ "$output" = "v0.0.0" ]
}

function get_tag_1 { #@test
    # test bad RELEASE_TYPE value

    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="bad"
    run get_tag
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unknown RELEASE_TYPE bad" ]
}

function get_tag_2 { #@test
    # test bad CURRENT_VERSION tag

    export RELEASE_TYPE=patch
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="bad"
    run get_tag
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unable to parse CURRENT_VERSION bad with regex v?([0-9]+)\.([0-9]+)\.([0-9]+)(-rc\.?([0-9]+))?" ]
}

function get_tag_3 { #@test
    # test patch increment

    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4" ]
}

function get_tag_4 { #@test
    # test minor increment

    export RELEASE_TYPE="minor"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.3.0" ]
}

function get_tag_5 { #@test
    # test major increment

    export RELEASE_TYPE="major"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v2.0.0" ]
}

function get_tag_6 { #@test
    # test release candidate added

    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="not-main"
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4-rc1" ]
}

function get_tag_7 { #@test
    # test release candidate increment

    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="not-main"
    export CURRENT_VERSION="v1.2.3-rc1"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4-rc2" ]
}

function get_tag_8 { #@test
    # test release candidate removed

    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="main"
    export CURRENT_VERSION="v1.2.3-rc1"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4" ]
}

function get_tag_9 { #@test
    # test RELEASE_CANDIDATE overwrite inferrence

    export RELEASE_TYPE="patch"
    export CIRCLE_BRANCH="not-main"  # should be release-candidate
    export RELEASE_CANDIDATE="true"  # overwrite
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.2.4-rc1" ]
}

function get_tag_10 { #@test
    # test RELEASE_TYPE overwrite inferrence

    export CIRCLE_BRANCH="fix/patch"  # should be patch
    export RELEASE_TYPE="minor"  # overwrite
    export RELEASE_CANDIDATE=false
    export CURRENT_VERSION="v1.2.3"
    run get_tag
    echo $output
    [ "$output" = "v1.3.0" ]
}
