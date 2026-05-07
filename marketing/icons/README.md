# TwentyGuard Icon Resources

This folder contains marketing-side icon resource candidates. These files are
prepared for review and handoff only; they do not replace the app resources
under `Sources/TwentyGuard/Resources/` unless explicitly approved.

## Recommended Candidate

Use `twentyguard-icon-candidate-b/` as the current preferred direction.

Rationale:
- The app icon keeps the intended identity: boundary rhythm plus guard shield.
- The cyan segment is restrained enough to avoid looking like a generic sync or
  loading icon.
- The menu bar icon uses a simplified template shield, which stays legible at
  16px and avoids the spinner semantics of a ring-only glyph.

## Candidate B Files

- `twentyguard-icon-candidate-b/twentyguard-app-icon-master-1024.png`
  - 1024px app icon master preview.
- `twentyguard-icon-candidate-b/AppIcon.icns`
  - macOS app icon candidate built from the generated iconset.
- `twentyguard-icon-candidate-b/statusbar_icon.png`
  - 16px template-style menu bar icon candidate.
- `twentyguard-icon-candidate-b/statusbar_icon@2x.png`
  - 32px template-style menu bar icon candidate.
- `twentyguard-icon-candidate-b/twentyguard-icon-size-preview.png`
  - Review board showing app icon sizes and status bar light/dark checks.
- `twentyguard-icon-candidate-b/TwentyGuard.iconset/`
  - Source PNG set used to build `AppIcon.icns`.

## Candidate A Note

`twentyguard-icon-candidate/` is retained as a comparison version. Its ring-only
status bar glyph is readable, but it risks being interpreted as a loading or
refresh indicator at small sizes, so it is not the preferred option.
