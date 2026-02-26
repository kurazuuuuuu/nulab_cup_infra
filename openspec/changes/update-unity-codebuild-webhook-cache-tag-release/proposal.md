# Change: Update Unity CodeBuild Trigger, Cache, and Tag-Driven Release

## Why
Current pipeline execution is effectively manual and does not enforce release tags as the source of truth. Build times are also longer because Unity build cache is not persisted across builds.

## What Changes
- Add a CodeBuild webhook that triggers only on Git tag push events matching `vX.Y.Z`
- Persist Unity build cache to S3 and reuse it in subsequent builds
- Resolve `RELEASE_TAG` from webhook `HEAD_REF` and enforce tag format validation
- Rename release artifact to `app-<tag>.apk` and upload that file to GitHub Releases
- Keep manual build support by requiring explicit `RELEASE_TAG` when webhook context is unavailable

## Impact
- Affected specs: `unity-codebuild-pipeline`
- Affected code:
  - `terraform/unity_cicd/main.tf`
  - `terraform/unity_cicd/variables.tf`
  - `terraform/unity_cicd/outputs.tf`
  - `terraform/unity_cicd/buildspec.yml`
  - `terraform/unity_cicd/terraform.tfvars.example`
