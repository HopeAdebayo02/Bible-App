### Cross References Visibility Fix (2025-10-06)

- Audit `CrossReferencesView.swift` for hardcoded `.white` text.
- Update list/table rows and `CrossReferenceConnectionView` header/labels/verses to use `.primary` and `.secondary` for light/dark adaptability.
- Verify no linter issues and that counts/footer remain readable.

- Web UI highlight bug: implemented stable, non-layout-shifting CSS (`web-highlight-reference/verse.css`) and a minimal React example (`web-highlight-reference/Verse.jsx`, `index.html`) to demonstrate behavior and serve as a reference for any web embed or WKWebView content.
## Plans

This document tracks high-level plans, priorities, and upcoming tasks for the Bible App.

### Working Agreements
- Maintain calm, smooth button transitions.
- Respect Reduce Motion; provide instant or gentler alternatives for all animations.
- Ask for approval before deploying to main/production.
- Store sensitive keys (e.g., Stripe) in `.env`.
- Test locally before enabling cloud integrations.

### Short-Term Roadmap
- Calendar/event feature UX polish and persistence.
- Appearance settings via `AppearanceService` (themes, font size, dynamic type).
- Reading tracker improvements and streak reliability.
 - Data integrity: ensure contiguous verse numbering at load time to guard against gaps or duplicates from upstream data. Implemented placeholder strategy in `BibleService`.
 - Animations: adopt app-wide motion tokens; add calm transitions to palette, headers, list inserts/deletes, and navigation.
  - Cross Reference Map (Genesis → Revelation timeline)
    - [x] Show baseline with per-chapter ticks (one tick per chapter)
    - [x] Animate new arcs with calm glow + path trim
    - [x] Zoom/Pan controls for dense regions
    - [x] Interaction: tap arc to open verses; long-press to delete
    - [x] Add Cross Reference sheet from verse menu (target selection)
    - [x] Restyle Add Cross Reference sheet (cards, searchable book, steppers)
    - [x] Animated arc with moving glow head and topmost draw order
    - [x] Post-save navigation: open CrossReferencesView with focus on new arc
    - [x] Hover tooltip showing cross-reference connections
    - [x] Restart button to clear all cross references with confirmation
- [x] Validate cross reference against curated index; warn if missing and allow manual connect
- [x] Add "Seed 100" button to Cross References view to rapidly populate 100 sample connections for visualization tests
- [x] Fix arc hit-testing to use Canvas size for accurate selection of connections
    - [x] Home shortcut to open Cross References visualization
    - [x] Unique bright solid colors per connection line
    - [x] Progressive line drawing animation with traveling glow (2.5s delay, 4s duration)
    - [x] Toggle between Map and Table views for cross references
    - [x] Clickable table rows for side-by-side verse comparison
    - [x] Back button navigation to return to Bible
    - [x] Web-based animation components for cross-reference visualization
      - [x] React component with smooth zoom/pan and animated line drawing
      - [x] Vanilla JavaScript/HTML implementation (no dependencies)
      - [x] Reusable animation utilities module
      - [x] Interactive example with click-to-connect functionality
      - [x] SVG-based animations optimized for mobile performance

### Notes
- See `CHANGELOG.md` for a historical list of edits and releases.
 - Heading-source consistency: UI headings come from `Header.md` and BSB inline-only fallback. For API.Bible and NLT, titles are disabled to avoid duplicates.
 - Validation: provide an all-version report to ensure no chapter/verse gaps or duplicates exist per translation.
 - Key management: load ESV from `ESVAPI.env`, NLT from `NLTAPI.env`. API.Bible uses `APIBIBLE_API_KEY` only (Info.plist/UserDefaults/env); no bundled `API.BIBLE.env`.

### Authentication
- Make sign-in optional. Default user experience is Guest mode with full reading access.
- Add a Google sign-in button in `Profile` under an "Account" section explaining benefits (sync bookmarks/settings). Keep a Sign Out button only when signed in.
 - Remove any forced sign-in modals from `HomeView` to allow continuous guest access after sign out. Provide voluntary entry points (Home card and Profile Account section).

### Data Scoping
- Scope user data by identity: when signed in, namespace `bookmarks`, `notes`, and `crossReferences` by Supabase `user.id`; when signed out, namespace by a persisted per-device UUID. Implemented via `LibraryService` namespaced UserDefaults keys.

- iOS build hygiene: Prefer `PhotosUI` over legacy `UIImagePickerController`. `FeedbackView` now imports `PhotosUI` and initializes `PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())` with images-only filter and multi-select.
 - Feedback email: Use Resend via `FeedbackService.sendFeedback`. Configure keys in `RESEND.env` or Info.plist/UserDefaults/env: `RESEND_API_KEY`, `FEEDBACK_TO_EMAIL`, `RESEND_FROM_EMAIL`, `RESEND_FROM_NAME`.
  - Resend sender policy: if `RESEND_FROM_EMAIL` is a free mailbox (gmail/outlook/yahoo/icloud), the app will send from `onboarding@resend.dev` and set `Reply-To` to the free mailbox to ensure delivery without domain verification.

### Verse Highlighting
- Implemented verse highlighting feature that allows users to select one or more consecutive verses and apply colored background highlights.
 - Selection mechanism: Tap any verse to select it and immediately show the color picker at the bottom. Tap additional verses to select multiple verses for batch highlighting.
 - Color picker: Bottom overlay with 8 predefined colors (Yellow, Green, Blue, Pink, Orange, Purple, Red, Cyan) plus a "no color" option to remove highlights.
 - Persistence: Highlights are saved locally using `HighlightService` and reapplied when viewing chapters. Each verse can have its own highlight color.
 - UI: Pure background color change (no text modifications). Visual indicators show which verses are selected before applying highlights.
 - Integration: Works with both verse item rendering and fallback rendering in `VersesView`. Tapping highlighted verses re-opens the color picker for changes or removal.

### Navigation UX
- Add collapsible sections for `Old Testament` and `New Testament` in `BookListView` using `DisclosureGroup` with calm expand/collapse animation. Books auto-group by `book.testament` when present; otherwise fallback to canonical ID (1–39 OT, 40–66 NT).
 - When a book's chapter picker sheet is open, rotate the chevron on that row 90° (pointing down) with a calm ease-in-out animation to indicate the active context.
 - Add inline book search in `BookListView` using `.searchable`; filters on name and abbreviation with diacritic-insensitive matching. When searching, show a single "Results" section.
 - Entry point change: remove inline `.searchable` from `BookListView`; add a toolbar search button that opens the dedicated `SearchView` (second screen) as a sheet for a focused experience.
 - Typography: book titles are regular weight by default; they become semibold only while their chapter picker is open.

### Search
- Implemented `SearchView` with `.searchable`, debounced queries (>=3 chars), and result list.
  - Updated to a custom `TextField` with explicit focus to avoid `.searchable` input issues on some devices. Submits open the first match immediately.
- Uses `BibleService.searchVerses` filtered by the current translation.
- Tapping a result switches to Bible tab at the corresponding book and chapter.
 - Cross-version fallback: if no matches in the selected translation, search all versions and show a version badge per result; opening a result auto-switches translation to match.
 - Phrase shortcuts: added common phrase mapping (e.g., "jesus wept" → John 11:35). Extendable list.

