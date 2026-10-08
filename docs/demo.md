# Testnet demo setup

Run the demo from the repository root with PowerShell:

```powershell
.\scripts\testnet-demo.ps1
```

## Prerequisites

- Stellar CLI 26 or newer, available as `stellar`
- Rust with the `wasm32v1-none` target installed
- Internet access to Stellar Testnet and its friendbot
- PowerShell 5.1 or newer

## What the script does

The script generates uniquely named, funded Testnet identities for an organizer
and two attendees, builds and deploys the registration contract, deploys a
native-asset contract, creates event `1`, and registers both attendees. Each
registration costs 1 XLM and is escrowed by the contract.

At the end, it prints the registration contract ID, native asset contract ID,
event ID, identity aliases, and public addresses. The new secret identities
are stored by Stellar CLI in its normal local identity configuration. The
script does not print or export secret keys.

Every run creates new identities and submits real Testnet transactions. The
identities are not automatically removed, and the demo event and registrations
remain on Testnet. Fees and the two 1-XLM payments are Testnet assets, not
Mainnet funds.
