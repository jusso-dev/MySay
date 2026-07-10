# MySay

[![CI](https://github.com/jusso-dev/MySay/actions/workflows/ci.yml/badge.svg)](https://github.com/jusso-dev/MySay/actions/workflows/ci.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![iPadOS 18+](https://img.shields.io/badge/iPadOS-18%2B-000000.svg?logo=apple)](https://developer.apple.com/ipados/)

A native iPad communication and language-learning app (AAC — Augmentative
and Alternative Communication) for children with developmental delays,
autism, speech delays, apraxia, and other communication challenges.

Tap a picture → the iPad speaks the word. Favourite the words you use most.
Build sentences like **"I want drink"** and hear them spoken naturally with
Apple's built-in speech synthesis.

MySay is an early-stage open-source project. It is suitable for development
and evaluation, but it is not a medical device or a substitute for advice
from a qualified speech-language professional.

> **Private by design.** No accounts, no backend, no analytics, no
> tracking, no ads. Everything lives on the iPad and works completely
> offline.

## Features

- **Tap to speak** — every icon speaks instantly using `AVSpeechSynthesizer`
  with an Australian English voice by default
- **150+ starter words** across 14 categories (Quick Phrases, Core Words,
  People, Food, Drinks, Feelings, Needs, Activities, Places, Body, Clothes,
  Animals, School, Weather)
- **Sentence strip everywhere** — a message window sits above every screen
  (toggleable); with "Build sentences from taps" enabled in Settings, any
  tapped word joins the sentence and the strip speaks the whole thing
- **Edit-in-place** — a passcode-gated pencil on every board: tap a tile to
  edit it, drag tiles to reorder, and add words right there
- **Hide, don't delete** — an eye badge masks words a child isn't ready
  for; positions never shift, so motor patterns stay intact
- **Stable tile positions** — words keep their place as vocabulary grows
  (motor planning, the LAMP principle); new words append at the end
- **Custom boards** — parent-curated boards for routines and places
  ("Morning", "At Grandma's"), shown on the Home screen
- **Recorded voice per word** — a parent can record their own voice for
  any icon; the tile then plays the familiar voice instead of the
  synthesiser
- **Personal Voice** — on iPadOS 17+, MySay can speak every word and
  phrase with a Personal Voice (a recreation of a real person's voice made
  in iPadOS Accessibility settings); pick it in Settings → Voice
- **Quick Phrases** — one tap speaks a whole pre-stored sentence ("I need
  help please")
- **Favourites** — long-press any tile to favourite it; sort manually, by
  most used, or A–Z
- **Most Used & Recently Used** — generated automatically from on-device
  usage tracking
- **Phrase Builder** — a full-size sentence workspace with category chips
- **Global search** — live results across icon names, phrases, and categories
- **Parent Mode** (passcode-protected) — add custom icons from photos
  (e.g. a photo of your child's actual cup), edit and delete icons, manage
  categories and boards, reset statistics, and export/import the whole
  library (including photos, recordings, and boards) as JSON
- **Settings** — speech rate and pitch, voice selection, grid size
  (2×2–5×5), labels on/off, sentence strip on/off, high contrast
- **60-second onboarding** on first launch

## Requirements

- Xcode 16 or newer (project uses the synchronized-folder format)
- iPadOS 18.0+
- iPad only

## Getting started

```bash
git clone https://github.com/jusso-dev/MySay.git
cd MySay
open MySay.xcodeproj
```

Select an iPad simulator and press **Run**. No configuration, packages, or
accounts needed — the starter vocabulary seeds itself on first launch.

### Running tests

```bash
xcodebuild test -project MySay.xcodeproj -scheme MySay \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

If that simulator is not installed, replace its name with any available iPad
simulator shown by Xcode.

- `MySayTests` — Swift Testing unit suite: seed data, speech, phrase
  building, favourites, usage tracking, persistence/backup round-trips,
  settings, parent gate, search, icon editor, and a live audio-pipeline
  smoke test
- `MySayUITests` — XCTest UI suite: onboarding, speaking tiles, favourites,
  phrase builder, search, parent mode, an accessibility audit, and launch
  performance

UI tests launch the app with `--uitest`, which switches to an in-memory
store and throwaway preferences so test runs never touch real data.

## Architecture

SwiftUI + MVVM + SwiftData. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
for the full picture and [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md) for
the accessibility story.

```
MySay/
├── App/            App entry, root tab view
├── Models/         SwiftData models (IconItem, IconCategory, Board) + DTOs
├── Services/       SpeechService, DataStore, UsageTrackingService,
│                   FavoritesService, SymbolProviders (import seam)
├── ViewModels/     PhraseBuilder, Search, ParentGate, IconEditor
├── Views/          Home, Categories, Favorites, PhraseBuilder, Search,
│                   Settings, ParentMode, Onboarding, shared Components
├── SampleData/     SeedData (152-icon starter vocabulary)
└── Assets.xcassets
```

## Artwork & symbol licensing

The bundled vocabulary references **SF Symbols as development placeholders**.
The artwork is supplied by Apple at runtime and remains subject to Apple's
licence terms; it is not redistributed under this project's MIT License. The
data layer records a `SymbolSource` per icon and exposes a `SymbolProvider`
protocol so open symbol libraries can be integrated later:

- **ARASAAC** (CC BY-NC-SA — attribution required)
- **OpenSymbols.org**
- Custom SVG packs
- Parent photos (already supported, stored in the database)

No copyrighted symbol sets are shipped.

## Privacy

- No analytics, telemetry, tracking, or advertising
- No account creation, no cloud dependency
- **Camera** access is requested only when a parent photographs an object
  for a custom icon
- **Microphone** access is requested only when a parent records a familiar
  voice for a word
- Backups are explicit, parent-initiated JSON exports

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md)
and our [Code of Conduct](CODE_OF_CONDUCT.md) before opening a pull request.
Security issues should be reported as described in [SECURITY.md](SECURITY.md),
not in a public issue.

## License

MySay is available under the [MIT License](LICENSE). Apple SF Symbols are
referenced through the operating system and remain subject to Apple's terms.
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for asset details.

## Roadmap (architecture prepared, not implemented)

iCloud sync, therapist portal, shared family boards, progress reporting,
multiple child profiles, sentence prediction, symbol recommendations,
speech-therapy activities, and learning games. The `Board` model, versioned
export format, and provider seams exist so these can land without data
migrations or rewrites.
