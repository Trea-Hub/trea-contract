# Contract upgrade and migration plan

## Decision

We will use the upgradeable-contract path for Trea's mainnet deployment rather than deploying a fresh immutable contract and abandoning the old event state.

Why this is the safer choice:

- Soroban keeps persistent storage attached to the contract ID across a code upgrade, so existing event records and registrations are not wiped as long as we keep the same contract identity.
- Trea's core business logic depends on historical event data, attendee registrations, and refund state remaining available after launch.
- A pure immutable-and-redeploy plan would require a new contract ID and a data migration from the old contract into a new one, which is operationally more complex and risks orphaning or losing on-chain history.

## Storage compatibility rules

To avoid data loss during future upgrades:

1. Preserve the same contract ID for the live deployment.
2. Keep existing storage keys stable when possible.
3. Treat `Event(u32)`, `Registered(u32, Address)`, and `CheckedIn(u32, Address)` as the canonical persistent data layout until a migration explicitly changes them.
4. Add a lightweight version marker to the instance storage so the contract can detect the on-chain schema version.
5. For any breaking schema change, write a forward-only migration that reads the old shape and writes the new shape, then marks the migration complete.

This repo includes a minimal version marker scaffold in the contract (`DataKey::Version` and `version()`), which can be extended as the contract evolves.

## Recommended migration flow

1. Ship a new contract wasm that is backward-compatible with the current storage layout.
2. Keep the same contract ID and deploy the upgraded code under the same account/admin governance.
3. Verify the current version in instance storage.
4. If the schema changes, call a dedicated migration entrypoint (admin-authenticated) that:
   - loads legacy records,
   - transforms them into the new structure,
   - writes the migrated data under the new keys,
   - updates the stored contract version,
   - emits an audit event documenting the migration.
5. After the migration succeeds, keep the upgrade path restricted to the admin/governance address until the next formal review.

## Example migration pattern

The exact implementation should look like this conceptually:

```rust
#[contracttype]
pub enum DataKey {
    Event(u32),
    Registered(u32, Address),
    CheckedIn(u32, Address),
    Admin,
    Paused,
    Version,
}

const CONTRACT_VERSION: u32 = 1;

impl EventRegistration {
    pub fn version(env: Env) -> u32 {
        env.storage()
            .instance()
            .get(&DataKey::Version)
            .unwrap_or(CONTRACT_VERSION)
    }
}
```

When the contract requires a breaking change, the next version would add a migration step such as `migrate_v2()` that reads all existing events and copies them into the new layout before updating `DataKey::Version` to `2`.

## Operational safeguards

- Require admin or multisig authorization for every upgrade or migration.
- Perform upgrade and migration on a testnet staging contract before production.
- Keep a dry-run validation step that confirms every migration path preserves the full event and registration dataset.
- Avoid deleting or renaming old keys until migration is confirmed and after the new code has been validated.
- Record the deployed wasm hash and version in the release notes for auditability.

## Why not an immutable redevelopment?

An immutable redeploy is technically possible, but it is not the preferred path for Trea's mainnet contract because it would force an off-chain data migration or a new user onboarding flow. That would make event history non-portable and create a break in the trust model of an already-live ticketing platform.

The contract should therefore remain upgradeable, with strict admin controls and explicit schema-version checks, while preserving the event and registration data already stored under the current contract ID.
