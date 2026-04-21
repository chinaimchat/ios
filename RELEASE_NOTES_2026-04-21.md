# iOS Update Notes (2026-04-21)

This update focuses on register/login stability across devices and full-screen recharge parity after replacing the previous half-sheet entry flow.

## Registration/Login reliability and adaptivity
- Fixed first-launch register invite-code refresh path so UI reliably reflects remote config on initial install/start.
- Improved remote-config callback handling to avoid missed callbacks when requests overlap.
- Migrated login/register layout behavior from fragile fixed-frame positioning to more stable constraint-driven arrangement for adaptive screens.
- Added keyboard avoidance and lifecycle-safe keyboard observer management for login/register pages.

## Wallet / Recharge full-screen parity
- Wallet recharge entry uses full-screen flow.
- Full-screen recharge page now includes parity capabilities previously expected from the sheet flow:
  - QR display
  - Copy address
  - Save QR
  - Persistent channel row presentation
  - Top-right Orders entry
  - Floating Contact Customer Service entry
- QR rendering behavior aligned to expected channel output (prefer channel server QR when provided).
- Fixed overlap between Confirm Recharge button and floating customer-service button by moving confirm action area upward.

## UI behavior consistency
- Updated related register/invite-code interactions to keep UI state consistent between initial render and async config update.

