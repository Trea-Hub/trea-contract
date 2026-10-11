# Contract benchmark notes

These numbers were collected with the Stellar CLI cost output (`stellar contract invoke ... --send=yes --cost`) against the deployed `registration` contract on testnet. The benchmark scenario used a valid Soroban token contract address in the event pricing map and a zero-price token amount so the same code path could be exercised without needing a funded transfer.

Important note: in this CLI version, the verbose simulation output reported `Cost { cpu_insns: 0, mem_bytes: 0 }` while still exposing the resource fee breakdown. The practical regression signal in this environment is therefore the `Resource Fee Charged` figure, which is the value we record below.

## Approximate resource cost summary

| Function | Final fee charged | Resource fee charged | CPU instruction signal in CLI output | Notes |
|---|---:|---:|---|---|
| `create_event` | 222,252 stroops | 222,152 stroops | `cpu_insns: 0` reported by the CLI | event creation with a zero-price token map |
| `register` | 147,462 stroops | 147,362 stroops | `cpu_insns: 0` reported by the CLI | attendee registration for an existing event |
| `refund` | 14,282 stroops | 14,182 stroops | `cpu_insns: 0` reported by the CLI | self-refund path |
| `check_in` | 92,948 stroops | 92,848 stroops | `cpu_insns: 0` reported by the CLI | organizer marks attendee checked in |
| `payout` | 5,001 stroops | 4,901 stroops | `cpu_insns: 0` reported by the CLI | organizer withdraws zero-balance escrow |

These numbers are approximate and intended as a baseline for later review. They were captured from a single realistic testnet run; for regression tracking, compare the `Resource Fee Charged` field before and after contract changes.

## Local reproduction steps

1. Build the contract wasm:

```bash
cd contracts/registration
stellar contract build
```

2. Generate two funded testnet identities:

```bash
stellar keys generate trea-benchmark --network testnet --fund
stellar keys generate trea-attendee --network testnet --fund
```

3. Deploy a valid Soroban asset contract for the price map and deploy the registration contract:

```bash
stellar contract asset deploy \
  --asset "USDC:GA224SDCGHQX3S7IC3VST3LTRM4D6BF2QFIOSYGPVLIWFWGXAZCBXXHU" \
  --source-account trea-benchmark \
  --network testnet \
  --alias trea-token

stellar contract deploy \
  --wasm target/wasm32v1-none/release/registration.wasm \
  --source-account trea-benchmark \
  --network testnet \
  --alias trea-registration
```

4. Create a JSON file for the event pricing map:

```json
{"CCT4B6SDEHMMM7CHTFFR7KYEQ4RPAYPS6F3USHCJT6AXW626G6IGR477":"0"}
```

Store that in a file such as `event_tokens.json`.

5. Invoke each function with the CLI cost output enabled:

```bash
REGISTRATION_ID="<contract-id-from-stellar-contract-alias-ls>"
ORGANIZER="GDL2JUPECAZTV3C7C66UN4TL52WB7BD6KTQ3R57MXVKJ2ZLHBCBYLQMK"
ATTENDEE="GDLGB4O3HNIXKKAPU5QNMY2DLYMKJRUJTZVBTYSIVH2OVD4EL5KNNKNM"
TOKEN_ID="CCT4B6SDEHMMM7CHTFFR7KYEQ4RPAYPS6F3USHCJT6AXW626G6IGR477"

stellar contract invoke \
  --id "$REGISTRATION_ID" \
  --source-account trea-benchmark \
  --network testnet \
  --send=yes \
  --cost \
  -- create_event \
  --organizer "$ORGANIZER" \
  --event_id 1 \
  --token_prices-file-path event_tokens.json \
  --capacity 100 \
  --self_refund_allowed true \
  --refund_deadline 0

stellar contract invoke \
  --id "$REGISTRATION_ID" \
  --source-account trea-attendee \
  --network testnet \
  --send=yes \
  --cost \
  -- register \
  --attendee "$ATTENDEE" \
  --event_id 1 \
  --payment_token "$TOKEN_ID"

stellar contract invoke \
  --id "$REGISTRATION_ID" \
  --source-account trea-attendee \
  --network testnet \
  --send=yes \
  --cost \
  -- refund \
  --caller "$ATTENDEE" \
  --event_id 1 \
  --attendee "$ATTENDEE"

stellar contract invoke \
  --id "$REGISTRATION_ID" \
  --source-account trea-benchmark \
  --network testnet \
  --send=yes \
  --cost \
  -- check_in \
  --organizer "$ORGANIZER" \
  --event_id 2 \
  --attendee "$ATTENDEE"

stellar contract invoke \
  --id "$REGISTRATION_ID" \
  --source-account trea-benchmark \
  --network testnet \
  --send=yes \
  --cost \
  -- payout \
  --organizer "$ORGANIZER" \
  --event_id 3
```

## Review guidance

- Prefer the `Resource Fee Charged` value when comparing contract changes in PR review.
- If a future CLI version exposes non-zero `cpu_insns`, store that number beside the fee figure in the same table.
- Re-run the same benchmark against the same testnet account setup whenever the contract logic or Soroban SDK version changes.
