# myhelix/taggy

[![CircleCI Build Status](https://circleci.com/gh/myhelix/taggy-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/myhelix/taggy-orb) [![CircleCI Orb Version](https://badges.circleci.com/orbs/myhelix/taggy.svg)](https://circleci.com/orbs/registry/orb/myhelix/taggy) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/myhelix/taggy-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)



## The Taggy Workflow

This orb has a job and a command, both named `cut-release`. The purpose of this orb is to
provide the tooling to automatically handle versioning for minor or patch level changes following SemVer.

cut-release will check on the latest tag and bump minor or patch based on the parameter passed to the orb.

```yaml
- taggy/cut-release:
  name: "Cut release - patch"
  release-type: patch
  filters:
    branches:
      only:
        - /hotfix[^a-zA-Z].*/

```

The tag is then pushed back up to the remote. To avoid conflicts the tag must not already exist. This only
becomes a problem when applying multiple hotfixes to a minor version. Hence for sequential hotfixes,
branch off of the last hotfix that was applied.


### Getting started

An initial tag must be set. `git checkout main; git pull; git tag v0.0.0; git push --tags`

Add the taggy orb to your circle config and setup a build and deploy workflow to handle
automatic version bumps and releases


#### Sample Workflow
```yaml
orbs:
  cdk: myhelix/cdk@1.0.3
  taggy: myhelix/taggy@0.1.0

tag_filters: &tag_filters
  tags:
    only: /^v[0-9]+\.[0-9]+\.[0-9]+$/ # matches tags like "v1.10.38"
  branches:
    ignore: /.*/  # ignore all branches

workflows:
  build: # The build workflow builds and cuts a release
    jobs:
      - cdk/build:
          name: "Install NPM packages for cdk"

      - hold:
          name: "Approval: Cut release"
          type: approval
          filters:
            branches:
              only:
                - main
                - /hotfix[^a-zA-Z].*/

      - taggy/cut-release:
          name: "Cut release - patch"
          requires:
            - "Approval: Cut release"
          release-type: patch
          filters:
            branches:
              only:
                - /hotfix[^a-zA-Z].*/

      - taggy/cut-release:
          name: "Cut release - minor"
          requires:
            - "Approval: Cut release"
          release-type: minor
          filters:
            branches:
              only:
                - main
  deploy: # The deploy workflow runs the deploy step when cut-release has created a new release
    jobs:
      - cdk/deploy:
          name: "Deploy cdk"
          filters:
            <<: *tag_filters

```


## CONTRIBUTING - How to Publish
* Create and push a branch with your new features.
* When ready to publish a new production version, create a Pull Request from _feature branch_ to `master`.
* The title of the pull request must contain a special semver tag: `[semver:<segment>]` where `<segment>` is replaced by one of the following values.

| Increment | Description|
| ----------| -----------|
| major     | Issue a 1.0.0 incremented release|
| minor     | Issue a x.1.0 incremented release|
| patch     | Issue a x.x.1 incremented release|
| skip      | Do not issue a release|

Example: `[semver:major]`

* Squash and merge. Ensure the semver tag is preserved and entered as a part of the commit message.
* On merge, after manual approval, the orb will automatically be published to the Orb Registry.


For further questions/comments about this or other orbs, visit the Orb Category of [CircleCI Discuss](https://discuss.circleci.com/c/orbs).
