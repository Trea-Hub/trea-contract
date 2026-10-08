# Clippy policy

CI runs `cargo clippy --workspace --all-targets -- -D warnings`. New Clippy
warnings should be fixed rather than suppressed. Any `#[allow(...)]` added to
the code must include an inline rationale and be documented here.

## Intentional allowances

| Allowance | Location | Reason |
|---|---|---|
| `clippy::too_many_arguments` | `contracts/registration/src/lib.rs` | Public Soroban contract methods expose their required inputs as ABI arguments; bundling them into a Rust-only parameter object would change the callable contract interface. |
| `clippy::needless_borrows_for_generic_args` | `contracts/registration/src/lib.rs` | Soroban contract-client and storage APIs conventionally receive borrowed values; retaining that convention avoids inconsistent call sites across contract functions. |

Deprecated APIs are not globally exempted. Token calls use the current
`token::TokenClient` API rather than the deprecated `token::Client` alias.
