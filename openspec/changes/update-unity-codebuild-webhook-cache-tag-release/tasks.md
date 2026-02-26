## 1. Terraform: Trigger and Cache
- [x] 1.1 Add webhook-related variables (`enable_webhook`, `tag_regex`)
- [x] 1.2 Add cache-related variables (`codebuild_cache_prefix`, `cache_namespace`)
- [x] 1.3 Add CodeBuild project S3 cache configuration
- [x] 1.4 Add `aws_codebuild_webhook` with tag push filter
- [x] 1.5 Add outputs for cache location and webhook URL

## 2. Buildspec: Tag and Artifact Behavior
- [x] 2.1 Resolve `RELEASE_TAG` from `CODEBUILD_WEBHOOK_HEAD_REF` when available
- [x] 2.2 Enforce `vX.Y.Z` validation and fail fast when invalid/missing
- [x] 2.3 Rename output APK to `Builds/app-<tag>.apk`
- [x] 2.4 Add cache paths for Unity/Gradle

## 3. Configuration and Validation
- [x] 3.1 Update `terraform.tfvars.example` with new webhook/cache options
- [x] 3.2 Run `terraform fmt` and `terraform validate` for `terraform/unity_cicd`
- [x] 3.3 Run `openspec validate update-unity-codebuild-webhook-cache-tag-release --strict`
