## Context
The Unity Android pipeline already uses CodeBuild with a custom AMI and uploads APK files to GitHub Releases. Triggering and release naming must now be tag-centric (`vX.Y.Z`) and build performance needs cache persistence.

## Goals
- Trigger builds only when matching Git tags are pushed
- Reduce build time by persisting Unity/Gradle caches
- Ensure release metadata and artifact names derive from the same tag

## Non-Goals
- Introducing CodePipeline
- Reworking Unity project build scripts
- Changing AMI creation workflow

## Decisions
- Use `aws_codebuild_webhook` with filter group:
  - `EVENT = PUSH`
  - `HEAD_REF = ^refs/tags/v[0-9]+\\.[0-9]+\\.[0-9]+$`
- Use CodeBuild S3 cache in the existing artifacts bucket with namespaced prefix
- Resolve `RELEASE_TAG` from `CODEBUILD_WEBHOOK_HEAD_REF`; fallback to manual `RELEASE_TAG` only
- Keep compatibility by renaming `Builds/app.apk` to `Builds/app-<tag>.apk` when needed

## Risks / Trade-offs
- Cache can become stale or corrupted: mitigated with `cache_namespace` variable for easy invalidation
- Strict semver tag regex may reject non-conforming release tags by design

## Validation Plan
- `terraform validate` on `terraform/unity_cicd`
- Webhook trigger test with `vX.Y.Z` tag push
- Non-tag push should not trigger
- Verify resulting GitHub Release asset name is `app-vX.Y.Z.apk`
