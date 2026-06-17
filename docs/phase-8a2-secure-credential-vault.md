# Phase 8A2 - Secure Credential Vault

## Added

- Electron encrypted secure vault
- AES-256-GCM local encryption
- IPC handlers for:
  - set secret
  - get secret status
  - delete secret
  - list secret statuses
- Preload bridge for secure vault
- Renderer helper
- Payment Settings support for:
  - DOKU Secret Key
  - Mayar Checkout API Key

## Important

Renderer never receives raw secret values back.
It only receives configured status, masked value, and updated timestamp.

## Storage

Secrets are stored in Electron userData:

- secure-vault.json

The encryption key is derived locally from the device fingerprint and app data path.
This is appropriate for development/local desktop MVP.
Future production can migrate to OS keychain/keytar.
