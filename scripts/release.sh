#!/bin/bash

# Release script for Soup and Nutz
# Usage: ./scripts/release.sh [patch|minor|major]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "mix.exs" ]; then
    print_error "mix.exs not found. Please run this script from the project root."
    exit 1
fi

# Get current version from mix.exs
CURRENT_VERSION=$(grep 'version:' mix.exs | sed 's/.*version: "\(.*\)".*/\1/')
print_status "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# Determine new version based on argument
if [ "$1" = "major" ]; then
    NEW_MAJOR=$((MAJOR + 1))
    NEW_MINOR=0
    NEW_PATCH=0
    VERSION_TYPE="major"
elif [ "$1" = "minor" ]; then
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$((MINOR + 1))
    NEW_PATCH=0
    VERSION_TYPE="minor"
elif [ "$1" = "patch" ] || [ -z "$1" ]; then
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$MINOR
    NEW_PATCH=$((PATCH + 1))
    VERSION_TYPE="patch"
else
    print_error "Invalid version type. Use: patch, minor, or major"
    exit 1
fi

NEW_VERSION="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
TAG_VERSION="v$NEW_VERSION"

print_status "Bumping version to: $NEW_VERSION ($VERSION_TYPE)"

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Working directory is not clean. Please commit or stash changes first."
    git status --short
    exit 1
fi

# Check if we're on master branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "master" ]; then
    print_warning "You're not on the master branch. Current branch: $CURRENT_BRANCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update version in mix.exs
print_status "Updating version in mix.exs..."
sed -i.bak "s/version: \"$CURRENT_VERSION\"/version: \"$NEW_VERSION\"/" mix.exs
rm mix.exs.bak

# Update CHANGELOG.md
print_status "Updating CHANGELOG.md..."
TODAY=$(date +%Y-%m-%d)
sed -i.bak "s/## \[Unreleased\]/## [Unreleased]\n\n## [$NEW_VERSION] - $TODAY\n\n### Added\n- \n\n### Changed\n- \n\n### Fixed\n- \n\n## [$CURRENT_VERSION] - $TODAY/" CHANGELOG.md
rm CHANGELOG.md.bak

# Commit changes
print_status "Committing version bump..."
git add mix.exs CHANGELOG.md
git commit -m "Bump version to $NEW_VERSION"

# Create and push tag
print_status "Creating tag: $TAG_VERSION"
git tag -a "$TAG_VERSION" -m "Release $NEW_VERSION"

# Push changes and tag
print_status "Pushing changes and tag..."
git push origin master
git push origin "$TAG_VERSION"

print_status "Release $NEW_VERSION has been created and pushed!"
print_status "GitHub Actions will automatically create a release when the tag is pushed."
print_status "You can view the release at: https://github.com/adamrobbie/soup_and_nutz/releases"

# Optional: Open the releases page
read -p "Open GitHub releases page? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "https://github.com/adamrobbie/soup_and_nutz/releases"
fi 