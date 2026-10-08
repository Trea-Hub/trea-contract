Description: Add a pre-commit hook (or documented git hook setup) so contributors can't accidentally commit unformatted code.
Acceptance Criteria:

A .pre-commit-config or simple git hook script is added
CONTRIBUTING.md is updated with setup instructions
Hook runs cargo fmt --check and blocks commit on failure