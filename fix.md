Description: Deploying to Testnet currently requires remembering several CLI flags. Add a make deploy-testnet (or equivalent script) that wraps the build + deploy commands.
Acceptance Criteria:

Running one command builds and deploys to Testnet using a configurable source identity
The resulting contract ID is printed and optionally saved to a local file
README is updated to reference the new command
