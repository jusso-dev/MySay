# MySay Accessibility

Accessibility is the product, not a feature. MySay's users include
children with motor, cognitive, visual, and auditory differences, and the
adults supporting them.

## Touch targets

- Communication tiles: minimum 80×80 pt (preferred size), enforced with
  `frame(minWidth: 80, minHeight: 80)`; at the default 4-column iPad grid
  tiles render well above 150 pt
- All other controls (keypad, speak/clear buttons, category chips) are at
  least 44×44 pt, most 56 pt+
- Grid density is user-configurable (2×2 → 5×5) so children with motor
  challenges can use very large targets

## VoiceOver

- Every tile exposes `accessibilityLabel` (the word) and an
  `accessibilityHint` describing the speak action and favourite gesture
- Favourite state is exposed via the `isSelected` trait, not just the
  star glyph; decorative images are `accessibilityHidden`
- Section headers carry `.isHeader` traits for rotor navigation
- The sentence strip is a container whose label reads the full sentence
- The passcode keypad reports digits entered ("2 of 4 digits entered")
- A UI test runs `performAccessibilityAudit` on the home screen every CI run

Note: when VoiceOver is active, tiles still speak via the app's
synthesizer after activation — consistent with mainstream AAC apps.

## Dynamic Type

- All text uses system text styles (`.headline`, `.title2`, etc.), never
  fixed point sizes, so it scales with the user's setting
- Tile labels scale down gracefully (`minimumScaleFactor`) instead of
  truncating words — the word is the content
- Known tradeoff: inside communication tiles, text cannot grow without
  bound because tiles are a fixed grid. The supported way to make tiles
  (and their labels) bigger is the Grid Size setting (2×2 = very large).
  The automated audit therefore covers descriptions, contrast, hit regions,
  element detection, and traits; Dynamic Type behaviour is reviewed by hand

## Reduced Motion

- The only animation in the speak path is a 140 ms tile pulse; it is
  skipped entirely when `accessibilityReduceMotion` is set
- No flashing, parallax, or decorative animation anywhere

## High Contrast

- A High Contrast toggle in Settings switches tiles to white/black with
  3 pt borders and full-strength icon colours
- The system's Increase Contrast setting (`colorSchemeContrast`) triggers
  the same treatment automatically, no setting required
- The pastel palette pairs every fill with a deep accent ≥ 4.5:1 against it

## Switch Control & external access

- Every interactive element is a real `Button`, so Switch Control,
  Full Keyboard Access, and Voice Control enumerate them automatically
- No gesture-only interactions: long-press favouriting is mirrored by a
  context menu (Switch Control exposes menus), and everything reachable by
  long-press is also reachable in Parent Mode or via tap
- Stable layout: tabs and section order never reorganise themselves, so
  scanning positions stay learnable

## Hearing & speech output

- Speech uses the `.playback` audio session category, so output is not
  silenced by the mute switch — critical for an AAC device
- Rate and pitch are adjustable per child; voices are selectable, with
  Australian English prioritised and higher-quality voices downloadable in
  iPadOS Settings
- **Personal Voice** is fully supported: after granting access in the
  Voice picker, every word and built phrase is spoken in the user's (or a
  parent's) own recreated voice — significant for children losing speech
  progressively, and for familiarity. Falls back to a standard voice
  automatically if authorization is revoked

## Motor planning

- Tile positions are explicit and stable (`sortOrder`): adding vocabulary
  never moves a word a child has already learned the location of
- Words can be **hidden instead of deleted** — they keep their position
  and reappear in the same place when re-shown
- Reordering is a deliberate parent action (drag in passcode-gated edit
  mode), never an automatic re-sort

## Cognitive load

- Calm, warm palette; no bright flashing colours; no busy chrome
- One concept per screen; tabs are few and fixed
- Labels can be hidden for pre-readers (picture-only mode)
- Onboarding is four screens, under 60 seconds, skippable
