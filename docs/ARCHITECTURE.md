# MySay Architecture

## Overview

SwiftUI + MVVM + SwiftData, Swift 6 language mode with main-actor default
isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Everything is
offline and on-device; there is no networking code in the app.

```
┌─────────────────────────────────────────────────────┐
│ Views (SwiftUI)                                      │
│  Home · Categories · Favorites · PhraseBuilder ·     │
│  Search · Settings · ParentMode · Onboarding         │
├─────────────────────────────────────────────────────┤
│ ViewModels (@Observable)                             │
│  PhraseBuilderViewModel · SearchViewModel ·          │
│  ParentGateViewModel · IconEditorViewModel           │
├─────────────────────────────────────────────────────┤
│ Services                                             │
│  SpeechService · DataStore/DataStoreActions ·        │
│  UsageTrackingService · FavoritesService ·           │
│  SettingsStore · SymbolProviders                     │
├─────────────────────────────────────────────────────┤
│ Persistence                                          │
│  SwiftData (icons, categories, boards) ·             │
│  UserDefaults (settings, passcode hash)              │
└─────────────────────────────────────────────────────┘
```

## Models

| Type | Kind | Purpose |
|---|---|---|
| `IconItem` | `@Model` | A communication tile: title, artwork, phrase, colour, favourite state, usage stats, stable position (`sortOrder`), visibility (`isHidden`), and optional parent recording |
| `IconCategory` | `@Model` | Vocabulary category; cascade-deletes its icons |
| `Board` | `@Model` | Custom ordered icon collection shown on Home; references icons by ID so deleting a board never deletes vocabulary |
| `CommunicationIcon` | struct | Value DTO used by seed data and import/export |
| `ExportArchive` | struct | Versioned JSON backup format |
| `TileColor` | enum | The pastel palette + high-contrast variants |

Custom photos are stored on `IconItem.customImageData` with
`@Attribute(.externalStorage)`, downscaled to ≤600 px JPEG before saving,
so the database stays lean with thousands of icons.

## Services

- **SpeechService** — wraps `AVSpeechSynthesizer`. Speaks immediately
  (interrupting in-flight speech so fast taps always win), tracks the last
  utterance for Replay, resolves voices with an en-AU → en-GB → system
  fallback chain. Utterance construction is `nonisolated static` and pure,
  so it unit-tests without audio. `audioEnabled: false` gives tests a
  silent double of the full service.
- **DataStore** — owns the `ModelContainer`; `inMemory: true` for tests,
  previews, and UI test runs. Seeds the bundled vocabulary on first launch
  only. `DataStoreActions` exposes the same export/import routines against
  any `ModelContext` so parent-mode views act on the live context.
- **UsageTrackingService** — increments counts/timestamps on every speak;
  derives Most Used / Recently Used via fetch descriptors with limits.
- **FavoritesService** — favourite toggling and the three sort modes
  (manual order, most used, alphabetical); sorting is pure/static.
- **SettingsStore** — `@Observable`, `UserDefaults`-backed, injectable
  suite for tests. Holds speech rate/pitch/voice, grid size, labels,
  sentence strip visibility, high contrast, favourite sort, onboarding
  flag, and the SHA-256 hash of the parent passcode (a child gate, not a
  security boundary).
- **AudioRecordingService** — short AAC/M4A clips recorded by a parent for
  individual words; stored on the icon (`recordedAudioData`) so recordings
  travel with backups. `SpeechService.speak(icon:)` prefers the recording
  and falls back to synthesis.

## Sentence strip

One shared `PhraseBuilderViewModel` is injected at the app root.
`CompactSentenceStripView` renders it above the tab view on all screens
except Phrases, and the Phrases tab is the full-size workspace over the
same model — so a sentence started on Home continues in Phrases. Tiles
append to the sentence only when both strip settings are on
(`showSentenceStrip` + `autoAddToSentence`, the latter off by default so
taps just speak), or always inside the Phrase Builder.

## Library upgrades

`DataStore.seedIfNeeded()` seeds empty stores, and for existing stores
runs `upgradeExistingLibrary()`: inserts seed categories added in later
releases (e.g. Quick Phrases) and backfills `sortOrder` by freezing the
legacy alphabetical layout, keeping tile positions stable from then on.
The JSON archive is versioned (v2 adds positions, hidden flags,
recordings, boards) and v1 archives still import.

## Dependency flow

`MySayApp` builds the container, `SpeechService`, and `SettingsStore` once
and injects them via `.environment(...)` / `.modelContainer(...)`. Views
read with `@Environment` and `@Query`; per-interaction services
(`UsageTrackingService`, `FavoritesService`) are cheap structs-over-context
created at the call site.

## Launch arguments

| Argument | Effect |
|---|---|
| `--uitest` | In-memory store + throwaway `UserDefaults` suite |
| `--uitest-skip-onboarding` | Marks onboarding complete |

## Performance notes

- All grids are `LazyVGrid`/`LazyHStack`; home rows are capped (top 10)
- Fetches that feed rows use `fetchLimit`
- Photos resized + external-storage attributes keep row loads small
- Speech latency: utterance is enqueued synchronously on tap; no awaits in
  the tap path

## Extension points (designed, not implemented)

- **Symbol libraries** — `SymbolProvider` protocol + `SymbolSource`
  provenance on every icon (ARASAAC, OpenSymbols, custom SVG packs)
- **iCloud sync / shared boards** — `Board` references icons by UUID;
  `ExportArchive` is versioned for migration
- **Profiles, reporting, therapist portal** — usage data is already
  per-icon counts + timestamps; a profile layer can partition the container
- **Prediction / recommendations** — `PhraseBuilderViewModel.sentence` is
  the single seam where token streams become text
