# Protection UI Refresh Design

Date: 2026-05-03

## Goal

Refresh the app's protection experience with a restrained but firm UI language. The app should reduce opportunities for self-negotiation while making its current state easy to understand.

This refresh covers three surfaces:

- Night screen lock menu.
- Full-screen night lock overlay.
- Eye health statistics window.

## Product Tone

The chosen tone is restrained but mandatory:

- Use fewer labels and fewer explanatory sentences.
- Make status clear before exposing details.
- Keep controls direct, but avoid making escape paths visually prominent.
- Avoid adding new windows unless a workflow cannot fit naturally in an existing surface.

## Night Screen Lock Menu

Keep all night screen lock configuration inside the menu. Do not add a separate "Edit Plan" window.

The menu should be reorganized into:

- `Enable`.
- `Wind-down Starts: 20:00`.
- `Full Lock Starts: 21:00`.
- `Unlocks: 07:00`.
- A short generated rhythm summary, for example: `Tonight: 35 -> 25 -> 15 -> 5 -> Locked`.
- A low-prominence testing escape submenu at the bottom, for example: `Testing Escape: Shown >`.

The testing escape should feel like a temporary test-stage control, not a primary app feature.

## Full-Screen Night Lock Overlay

Replace the current centered card-like overlay with a full-screen status page.

The overlay should show:

- Small context label: `Night Lock`.
- Primary state: `Screen Locked`.
- Large countdown.
- Recovery time: `07:00 Unlocks`.
- Small schedule line: `20:00 Wind-down - 21:00 Lock`.
- A very low-prominence testing escape in a corner when enabled.

The overlay must not include a normal quit button. The testing escape remains for early testing and still requires a second confirmation click.

## Eye Health Statistics

Use a verdict-first information structure.

The window should present:

- Today's verdict first, for example `Overlong Work` or `Healthy`.
- A short reason under the verdict.
- Three key metrics immediately below the verdict, such as completion rate, postpones, and night lock status.
- A properly aligned seven-day table with columns for date, work time, break completion, and postpones.
- Data quality warnings only when they are relevant.

The goal is that opening the statistics window answers: "Is today okay? If not, what is the problem?"

## Non-Goals

- Do not change the night restriction algorithm.
- Do not change statistics data definitions.
- Do not add a separate night schedule editor window.
- Do not redesign the normal break overlay except for any needed night wind-down hint polish.

## Verification

The implementation should be verified with:

- Swift package tests.
- Standard Makefile build and install flow.
- Installed app version check under `/Applications/20-20-20.app`.
- Desktop UI inspection for the menu, full-screen night overlay, and statistics window.
