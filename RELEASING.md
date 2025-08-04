# Release Process

This document describes the release process for the Voo Logging package.

## Overview

The release process is designed to support multiple branches and automated publishing to pub.dev:

1. **Development** happens on feature branches
2. **Release preparation** creates a release branch with version bump
3. **Publishing** happens automatically when a version tag is pushed

## Workflows

### 1. Prepare Release Workflow

Trigger manually from GitHub Actions to prepare a new release:

```bash
# From GitHub UI: Actions → Prepare Release → Run workflow
# Select version type: patch, minor, or major
# Select source branch (default: main)
```

This workflow will:
- Create a new `release/x.x.x` branch
- Bump the version in `pubspec.yaml`
- Add a template entry to `CHANGELOG.md`
- Create a pull request

### 2. Publish Workflow

The publish workflow runs automatically on:
- Push to `main` branch (dry run only)
- Push to `release/*` branches (dry run only)
- Push of version tags `v*` (actual publish)
- Manual trigger with dry run option

## Step-by-Step Release Process

### 1. Prepare the Release

```bash
# Option A: Use GitHub UI
# Go to Actions → Prepare Release → Run workflow
# Select version bump type (patch/minor/major)

# Option B: Manual preparation
git checkout -b release/1.2.3
# Update version in pubspec.yaml
# Update CHANGELOG.md
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: prepare release 1.2.3"
git push origin release/1.2.3
```

### 2. Update Release Notes

1. Open the created pull request
2. Edit `CHANGELOG.md` with actual release notes
3. Remove empty sections
4. Commit changes to the release branch

### 3. Merge Release Branch

1. Review the pull request
2. Ensure all tests pass
3. Merge to main branch

### 4. Create and Push Tag

```bash
git checkout main
git pull origin main
git tag v1.2.3
git push origin v1.2.3
```

The tag push will trigger automatic publishing to pub.dev.

### 5. Verify Release

1. Check [GitHub Actions](https://github.com/voostack/voo_logging/actions) for publish status
2. Verify package on [pub.dev](https://pub.dev/packages/voo_logging)
3. Check the created GitHub release

## Manual Publishing

For manual publishing or testing:

```bash
# Dry run (no actual publish)
flutter pub publish --dry-run

# Actual publish (requires credentials)
flutter pub publish
```

## Setting up Pub Credentials

To enable automated publishing, add pub.dev credentials as a GitHub secret:

1. Authenticate locally: `flutter pub login`
2. Copy credentials: `cat ~/.pub-cache/credentials.json`
3. Add as GitHub secret: `PUB_CREDENTIALS`

## Branch Strategy

- **main**: Stable code, ready for release
- **develop**: Integration branch (optional)
- **feature/***: Feature development
- **release/***: Release preparation
- **hotfix/***: Emergency fixes

## Version Numbering

Follow semantic versioning (semver):

- **MAJOR** (x.0.0): Breaking changes
- **MINOR** (0.x.0): New features, backward compatible
- **PATCH** (0.0.x): Bug fixes, backward compatible

## Pre-release Versions

For pre-release versions:

```yaml
version: 1.0.0-beta.1
```

Tag as:
```bash
git tag v1.0.0-beta.1
```

## Troubleshooting

### Publish Fails

1. Check dry run: `flutter pub publish --dry-run`
2. Verify all required files exist (LICENSE, README.md, CHANGELOG.md)
3. Check pubspec.yaml format
4. Ensure version is bumped

### Credential Issues

1. Verify `PUB_CREDENTIALS` secret is set correctly
2. Check credential format (should be JSON)
3. Ensure credentials are not expired

### Tag Issues

1. Ensure tag format is `v{version}` (e.g., `v1.2.3`)
2. Tag must match version in pubspec.yaml
3. Don't reuse existing tags

## Rollback Process

If a release has issues:

1. **Before Publishing**: Delete the tag and fix issues
2. **After Publishing**: 
   - Cannot unpublish from pub.dev
   - Create a new patch version with fixes
   - Mark the broken version as retracted in pubspec.yaml:
   
   ```yaml
   # In the fixed version's pubspec.yaml
   retracted:
     - 1.2.3  # The broken version
   ```