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
- The menu bar icon uses a solid template shield, which has enough weight at
  16px and avoids the spinner semantics of a ring-only glyph.

## Stable Exports

- `twentyguard-app-icon-1024.png`
  - Stable 1024px app icon export for README, release notes, social previews,
    and brand handoff.
- `twentyguard-icon-candidate-b/statusbar_icon.png`
  - Current 16px menu bar template glyph candidate.
- `twentyguard-icon-candidate-b/statusbar_icon@2x.png`
  - Current 32px menu bar template glyph candidate.

## Usage Guidance

- Use the app icon as the brand mark in README, release notes, repo social
  preview, download instructions, community posts, and any future press kit.
- Use the menu bar glyph only for the actual macOS status item or when
  explaining menu bar behavior.
- Do not use the menu bar glyph as the primary logo; it is intentionally simple
  and monochrome.
- Website-specific assets such as favicons and Open Graph cards are out of
  scope until there is an explicit website plan.

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
- `twentyguard-icon-candidate-b/statusbar-strength-preview.png`
  - Focused review board for the stronger solid menu bar glyph.
- `twentyguard-icon-candidate-b/TwentyGuard.iconset/`
  - Source PNG set used to build `AppIcon.icns`.

## Candidate A Note

`twentyguard-icon-candidate/` is retained as a comparison version. Its ring-only
status bar glyph is readable, but it risks being interpreted as a loading or
refresh indicator at small sizes, so it is not the preferred option.
