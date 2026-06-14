# Corra Booth Architecture

Corra Booth is designed as a portable core application with platform adapters.

## Rule

The UI must not directly access Windows hardware SDKs.

Correct flow:

React UI → Platform API → Electron Preload → IPC → Electron Main → Windows Native Adapter

## Apps

- booth-ui: portable photobooth interface
- desktop-electron: Windows shell and native adapter
- admin-web: remote admin dashboard
- download-page: public QR download page
- landing-page: marketing site

## Packages

- booth-core: business rules
- image-engine: frame composition and GIF generation
- data-access: Supabase and local persistence
- shared: shared types and validators

