# unity-codebuild-pipeline

## ADDED Requirements

### Requirement: REQ-UCP-008 Tag Push Webhook Trigger
The system MUST trigger Unity CodeBuild automatically from GitHub tag push events via CodeBuild webhook.

- Webhook event filter SHALL be `PUSH`
- HEAD ref filter SHALL match `refs/tags/vX.Y.Z` pattern (configurable by Terraform variable)

#### Scenario: Matching tag push triggers a build
- **GIVEN** a webhook with head ref regex for `refs/tags/vX.Y.Z`
- **WHEN** `refs/tags/v1.2.3` is pushed to GitHub
- **THEN** CodeBuild starts a new build automatically

#### Scenario: Non-tag push does not trigger
- **GIVEN** the same webhook configuration
- **WHEN** a normal branch commit is pushed
- **THEN** CodeBuild is not triggered by the webhook

### Requirement: REQ-UCP-009 Persistent Build Cache
The system MUST persist Unity build cache across builds using S3-backed CodeBuild cache.

- Cache storage SHALL be an S3 location managed by Terraform
- Cache paths SHALL include Unity Library and selected dependency caches

#### Scenario: Cache is reused on subsequent build
- **GIVEN** one successful build has populated cache
- **WHEN** the next build runs on the same project configuration
- **THEN** CodeBuild restores cache and reduces repeated import/build work

### Requirement: REQ-UCP-010 Tag-Driven Release Naming
The system MUST derive release tag from webhook ref for webhook-triggered builds and use it for artifact naming and GitHub release upload.

- `RELEASE_TAG` SHALL be resolved from `CODEBUILD_WEBHOOK_HEAD_REF` when present
- Manual builds SHALL require explicit `RELEASE_TAG`
- Artifact filename SHALL be `app-<RELEASE_TAG>.apk`

#### Scenario: Webhook build uses tag in APK filename
- **GIVEN** webhook head ref `refs/tags/v1.2.3`
- **WHEN** the build succeeds
- **THEN** uploaded artifact filename is `app-v1.2.3.apk`

#### Scenario: Manual build without release tag fails fast
- **GIVEN** the build is started manually without webhook context
- **WHEN** `RELEASE_TAG` is not provided
- **THEN** pre-build validation fails before Unity build starts
