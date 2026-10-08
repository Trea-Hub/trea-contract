Description: There's currently no plan for how the contract will be upgraded post-Mainnet-deploy without losing existing event data. Document (and if feasible, implement scaffolding for) a versioning/migration approach.
Acceptance Criteria:

docs/upgrades.md explains the chosen strategy (e.g. Soroban's upgrade mechanism, or a deliberate immutable-and-redeploy approach)
If code changes are needed, they're implemented and tested