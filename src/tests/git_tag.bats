setup() {
    source ./src/scripts/git_tag.sh
}

function test_infer_release_type_from_branch_1 { #@test
    # test hotfix parsed into patch

    export CIRCLE_BRANCH=hotfix
    run infer_release_type_from_branch
    echo $output
    [ "$output" = "patch" ]
}

function test_infer_release_type_from_branch_2 { #@test
    # test that CIRCLE_BRANCH must be defined

    unset CIRCLE_BRANCH
    run infer_release_type_from_branch
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "CIRCLE_BRANCH variable required" ]
}

function test_infer_release_type_from_branch_3 { #@test
    # test unparsable git branch name

    export CIRCLE_BRANCH=bad
    run infer_release_type_from_branch
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unable to infer release-type from branch $CIRCLE_BRANCH" ]
}

function test_infer_release_candidate_from_branch_1 { #@test
    export CIRCLE_BRANCH=main
    run infer_release_candidate_from_branch
    echo $output
    [ "$output" = false ]
}

function test_infer_release_candidate_from_branch_2 { #@test
    export CIRCLE_BRANCH=not-main
    run infer_release_candidate_from_branch
    echo $output
    [ "$output" = true ]
}

function test_infer_current_version_1 { #@test
    # no recent tag

    run infer_current_version
    echo $output
    [ "$output" = "v0.0.0" ]
}

function test_infer_current_version_2 { #@test
    # recent tag

    git tag v0.1.0
    run infer_current_version
    echo $output
    [ "$output" = "v0.1.0" ]  # track previous 'git tag' L59'
}

function test_infer_current_version_3 { #@test
    # recent tag

    git tag v0.2.0
    run infer_current_version
    echo $output
    [ "$output" = "v0.2.0" ]  # track previous 'git tag' L59 L68'
}

function test_increment_current_version_1 { #@test
    # test bad RELEASE_TYPE value

    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="bad"
    run increment_current_version
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unknown RELEASE_TYPE bad" ]
}

function test_increment_current_version_2 { #@test
    # test bad CURRENT_VERSION tag

    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="patch"
    export CURRENT_VERSION="bad"
    run increment_current_version
    [ "$status" -eq 1 ]
    echo $output
    [ "$output" = "Unable to parse CURRENT_VERSION bad with regex v?([0-9]+)\.([0-9]+)\.([0-9]+)(-rc\.?([0-9]+))?" ]
}

function test_increment_current_version_3 { #@test
    # test patch increment

    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="patch"
    export CURRENT_VERSION="v1.2.3"
    run increment_current_version
    echo $output
    [ "$output" = "v1.2.4" ]
}

function test_increment_current_version_4 { #@test
    # test minor increment

    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="minor"
    export CURRENT_VERSION="v1.2.3"
    run increment_current_version
    echo $output
    [ "$output" = "v1.3.0" ]
}

function test_increment_current_version_5 { #@test
    # test major increment

    export CIRCLE_BRANCH="main"
    export RELEASE_TYPE="major"
    export CURRENT_VERSION="v1.2.3"
    run increment_current_version
    echo $output
    [ "$output" = "v2.0.0" ]
}

function test_increment_current_version_6 { #@test
    # test multi-number version parts

    export CIRCLE_BRANCH="fix/patch"
    export IS_RELEASE_CANDIDATE=false
    export CURRENT_VERSION="v10.21.32"
    run increment_current_version
    echo $output
    [ "$output" = "v10.21.33" ]
}


function test_get_release_candidate_1 { #@test
    # test release candidate added

    export NEXT_VERSION="v1.2.3"
    run get_release_candidate
    echo $output
    [ "$output" = "v1.2.4-rc1" ]   # track previous 'git tag' L59 L68'
}

function test_get_release_candidate_2 { #@test
    # test release candidate increment

    export NEXT_VERSION="v0.2.0"
    git tag "$NEXT_VERSION-rc1"

    run get_release_candidate
    echo $output
    [ "$output" = v0.2.0-rc2" ]  # track previous 'git tag' L59 L68 L155'
}

function test_get_next_version_1 { #@test
    # test IS_RELEASE_CANDIDATE overwrites inferrence

    export RELEASE_TYPE="minor"
    export CIRCLE_BRANCH="main"  # should not be release-candidate
    export IS_RELEASE_CANDIDATE=true  # overwrite
    run get_next_version
    echo $output
    [ "$output" = "0.3.0-rc1" ]  # track previous 'git tag' L59 L68 L155'
}

function test_get_next_version_3 { #@test
    # test FILE overwrite inferrence

    export IS_RELEASE_CANDIDATE=false
    export RELEASE_TYPE="patch"
    export FILE="VERSION"

    echo v1.0.0 >> $FILE

    run get_next_version
    echo $output
    [ "$output" = "v1.0.0" ]
}

function test_get_next_version_4 { #@test
    # test if IS_RELEASE_CANDIDATE not provided, it is inferred

    export RELEASE_TYPE="minor"
    export CIRCLE_BRANCH="not main"  # should be release-candidate
    run get_next_version
    echo $output
    [ "$output" = "0.2.0-rc3" ]   # track previous 'git tag' L59 L68 L155'
}

function test_get_next_version_5 { #@test
    # test if RELEASE_TYPE not provided, it is inferred

    export CIRCLE_BRANCH="patch/not main"  # should be patch increment
    run get_next_version
    echo $output
    [ "$output" = "0.2.1-rc1" ]   # track previous 'git tag' L59 L68 L155'
}
