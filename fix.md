Description: There's currently no automated CI running cargo test and stellar contract build on pull requests. Add a GitHub Actions workflow.
Acceptance Criteria:

.github/workflows/ci.yml runs cargo fmt --check, cargo test, and stellar contract build on every PR and push to main
Workflow status is visible as a required check on PRs
README badge added showing CI status