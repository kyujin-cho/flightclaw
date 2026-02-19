Create a new release for flightclaw.

Steps:
1. Run `git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD` to show commits since last tag.
2. Determine the next version by looking at the latest tag with `git describe --tags --abbrev=0 2>/dev/null`. If no tags exist, use v0.1.0. Bump minor for features, patch for fixes.
3. Ask the user to confirm the version number before proceeding.
4. Commit any uncommitted changes first (ask user).
5. Create the tag: `git tag <version>`
6. Push the commit and tag: `git push upstream master && git push upstream <version>`
7. Report the GitHub Actions URL: https://github.com/kyujin-cho/flightclaw/actions
