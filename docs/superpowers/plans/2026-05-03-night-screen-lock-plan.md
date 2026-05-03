# Night Screen Lock Implementation Plan

Date: 2026-05-03

## Steps

1. Add a tested core night restriction policy.
2. Persist night restriction settings in UserDefaults.
3. Add night settings menu controls and rhythm summary.
4. Apply effective work duration during wind-down.
5. Add a full-screen night lock overlay with a temporary testing escape.
6. Integrate night lock checks into work, break, wake, and launch flows.
7. Update release metadata.
8. Build, install, launch, and verify the installed app.

## Verification

- Run Swift package tests.
- Build through the Makefile.
- Install through the Makefile.
- Launch the `/Applications` version.
- Inspect the menu and overlay behavior with the desktop UI.
