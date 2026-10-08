Description: Add clippy linting to catch common Rust issues, with a documented list of any intentionally allowed lints and why.
Acceptance Criteria:

CI runs cargo clippy -- -D warnings (or a scoped equivalent)
Any #[allow(...)] in the codebase has an inline comment explaining why
Existing code is cleaned up to pass without new allows unless justified