# Contributing to MySay

Thank you for helping make MySay more useful and accessible.

## Before you start

- Search existing issues before opening a new one.
- Use an issue to discuss substantial features or architectural changes before
  investing in an implementation.
- Never include personal health information, recordings, photos, API keys, or
  other sensitive data in issues, fixtures, screenshots, or commits.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Development setup

You need Xcode 16 or newer and an iPadOS 18 or newer simulator.

```bash
git clone https://github.com/jusso-dev/MySay.git
cd MySay
open MySay.xcodeproj
```

MySay has no third-party package dependencies. Select the shared `MySay`
scheme and an iPad simulator, then build and run. For a physical device,
choose your own development team in Xcode's Signing & Capabilities settings.

## Testing

Run the complete unit and UI test suite before submitting a pull request:

```bash
xcodebuild test \
  -project MySay.xcodeproj \
  -scheme MySay \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

Replace the destination name with any installed iPad simulator when needed.

Add focused unit tests for new model, service, persistence, or view-model
behaviour. Add UI tests only for end-to-end behaviour that cannot be covered
reliably at a lower level.

## Project expectations

- Preserve the offline-first design. New networking, analytics, accounts, or
  external services require prior discussion.
- Treat accessibility as a release requirement. Check VoiceOver labels,
  Dynamic Type, Reduce Motion, contrast, and 44-by-44-point minimum targets.
- Preserve stable vocabulary positions and avoid unexpected changes to a
  child's learned motor patterns.
- Use modern Swift concurrency and SwiftUI APIs supported by iPadOS 18.
- Keep user-facing Australian English consistent with the existing app.
- Update documentation when behaviour, architecture, privacy, or permissions
  change.

## Pull requests

Keep pull requests focused and explain the user-facing reason for the change.
Complete the pull-request checklist, link related issues, and include before
and after screenshots or a short recording for visible UI changes. By
submitting a contribution, you agree that it may be distributed under the
project's [MIT License](LICENSE).
