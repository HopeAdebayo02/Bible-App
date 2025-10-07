## 2025-10-06

- Fix: Cross References screens used hardcoded white text causing invisible rows in light mode. Replaced with adaptive `.primary`/`.secondary` colors in `CrossReferencesView.swift` for both the table list and the connection detail modal. No functional changes.

- chore(web): add stable highlight CSS/React demo that avoids layout shifts when highlighting verses. Includes `-webkit-text-size-adjust` safeguards and accessible focus styles.
## Changelog

### [Unreleased]
#### Added
- Translation picker includes NLT.
- NLT API fallback using `NLTAPI.env` when selected version is NLT and DB has no rows.
- Animations.md deep-dive guide covering SwiftUI animation patterns and best practices.
- CrossReferencesView: blank-slate Canvas visualization that adds an arc per user-created cross reference.
  - Removed forced rotation; the view now follows device orientation.
  - Added per-chapter ticks along the baseline (Genesis → Revelation), one tick per chapter.
  - Added validation against curated cross-reference index; unknown pairs show a confirmation alert with "Connect" to add manually.
  - New calm animation for newly added cross references: path trim with subtle glow while drawing, then settles to base stroke.
  - Added pinch-to-zoom and pan for exploring dense sections; interactions feel steady and calm.
  - Added interactions: tap an arc to open its source chapter; long-press to delete the arc.
  - Added an "Add Cross Reference" sheet from verse context menu with target book/chapter/verse and optional note.
  - Restyled cross-reference sheet: modern cards, searchable book picker, steppers for chapter/verse.
  - Animated arcs now feature a curved path trim with a leading glow head; newest arcs render on top.
  - After adding a cross reference, the app now opens the Cross Reference map and focuses the newly created link with a re-animation.
  - Added hover tooltip showing cross-reference connections (e.g., "1 Peter 2:6 → Isaiah 28:16") when hovering over arcs.
  - Added restart button in top right corner to clear all cross references with confirmation alert.
  - Added Home screen shortcut card to open Cross References visualization.
  - Each cross-reference line now uses a unique, bright solid color for clarity.
  - Enhanced animation: when a new cross reference is added, the line progressively draws from origin to destination over 4 seconds with a traveling glow effect. Animation starts after a 2.5 second delay to allow device rotation.
  - Added toggle button to switch between Map visualization and Table list view of all cross references.
  - Made table rows clickable to open a side-by-side view showing both connected verses with their full text.
  - Added back button in navigation bar to return to Bible from Cross References views.
  - Added a test "Seed 100" button to quickly add 100 sample cross references for stress-testing the visualization (no validation).
  - Fixed arc selection accuracy by using actual Canvas content size for hit testing; taps now open the correct connection.
- Web-based cross-reference animation components (`web-components/` directory):
  - `CrossReferenceAnimation.jsx`: React component with smooth zoom/pan, animated line drawing, and pulsing glow effects
  - `cross-reference-animation.html`: Standalone HTML/JavaScript implementation with no dependencies
  - `animation-utils.js`: Reusable animation utility module with easing functions, path generation, and animator class
  - `example-usage.html`: Interactive demo with click-to-connect verse nodes and pre-built animation buttons
  - All components use SVG-based animations optimized for mobile performance with smooth easing (easeInOutQuad, easeOutCubic)
  - Features include: zoom to verse, pulsing glow highlights, stroke-dasharray path animation, moving glow trail, and reset view functionality
  - Comprehensive README with usage examples, customization guide, and SwiftUI integration tips

#### Fixed
- Feedback: compile error in `FeedbackView` by importing `PhotosUI`/`Photos` and using `PHPhotoLibrary.shared()` in `PHPickerConfiguration`. Limits to images and supports multi-select.
- Books list view: filtered out invalid "cancelled" entries and removed cleanup functionality per user request

#### UI
- `BookListView` now groups books under collapsible `Old Testament` and `New Testament` sections using `DisclosureGroup`. Grouping prefers `book.testament` when available, otherwise falls back to canonical ID (1–39 OT, 40–66 NT). This keeps the list tidy and lets users quickly focus on the desired testament.
 - Active book chevron rotates 90° downward while the chapter picker sheet is open, providing a subtle visual cue. Uses a calm ease-in-out animation.
 - Added inline search in `BookListView` to quickly filter books by name or abbreviation. Uses diacritic-insensitive matching and shows results in a single section.
 - Search entry updated: removed inline search from `BookListView`. Added a magnifying-glass button that opens the dedicated `SearchView` as a sheet for a cleaner books list and focused search experience.
 - Typography: Book titles are regular weight by default and only become semibold while the chapter picker sheet for that book is open.

#### Auth
- Sign-in is now optional. The `Profile` screen shows a Google sign-in button under an Account section when signed out (with brief benefits copy) and only shows Sign Out when signed in.
 - Removed forced sign-in full-screen modal on Home. Users can browse and read as guests after signing out; sign-in remains available from Home and Profile.

#### Data
- Bookmarks, Notes, and Cross References are now scoped per-identity: synced to a user's namespace when signed in (Supabase `user.id`), and stored per-device when signed out (stable device UUID). Switching accounts or signing out automatically loads the appropriate data set.

#### Features
- **Verse Highlighting**: Simplified verse highlighting system that works directly on the chapter page for immediate interaction.
  - Selection: Tap any verse to select it and immediately show the color picker at the bottom. Tap additional verses to select multiple verses for batch highlighting.
  - Color Picker: Bottom overlay with 8 predefined colors (Yellow, Green, Blue, Pink, Orange, Purple, Red, Cyan) plus option to remove highlights.
  - Persistence: Highlights are saved locally via `HighlightService` and automatically reapplied when viewing chapters.
  - UI: Pure background color application with visual selection indicators. Tapping highlighted verses re-opens the color picker for changes or removal.
  - Integration: Works across all verse rendering modes in `VersesView` with immediate visual feedback.

#### Added
- Feedback submission now emails via Resend using `FeedbackService`. Configure `RESEND_API_KEY` and sender/recipient fields via `RESEND.env`, Info.plist, UserDefaults, or environment.
 - Resend sender fallback: when a free mailbox is configured as `RESEND_FROM_EMAIL`, the app sends with `onboarding@resend.dev` and sets `Reply-To` to the mailbox to avoid domain verification issues.
 - Search: Added `SearchView` with a dedicated search field, focus on appear, debounce, and server-side verse search. If no results in the selected translation, it falls back to search across all translations and displays a version badge. Opening a result auto-switches translation to match. Added phrase shortcut for "Jesus wept" → John 11:35.
- ESV API key lookup via `ESV_API_KEY` from Info.plist, env, or `ESVAPI.env`.
- ESV parser supports bracketed verse numbers and unicode punctuation to avoid fallback to WEB.
 - NLT cleanup: removed API.Bible titles from chapter content, restricted inline heading extraction to BSB only, and stripped leading asterisk disclaimer lines from verse text.
 - Validation now scans all translations (BSB, ESV, NLT, WEB, KJV) and shows the version tag in the report so gaps and duplicates are caught per-version.
 - Removed API.BIBLE.env usage on request; API.Bible support now relies only on `APIBIBLE_API_KEY` via Info.plist/UserDefaults/environment.

## Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning where practical.

### [Unreleased]
#### Fixed
- Normalize verse numbering when loading chapters to eliminate "Missing verse numbers (gap detected)" in `ValidationReportView`. Implemented placeholder insertion in `BibleService.fetchVerses` via `normalizeContiguousNumbering`.
- Merge duplicate verse rows (same verse number) by combining their content in `BibleService.mergeDuplicateVerses`, preventing duplicate verse markers in the reader.
 - Improve duplicate handling: when duplicates indicate misnumbered rows and the subsequent verse numbers are missing, split them into sequential verses (N..N+k-1) instead of merging, preserving the correct content for verse 1.

### [0.1.0] - 2025-09-27
#### Added
- Copy action in verse context menu in `VersesView` to copy the selected verse text with reference. Also added helpers to copy multiple selected verses.
- Translation picker with ESV support via `TranslationService`. `BibleService.fetchVerses` now filters by selected `version` and falls back to ESV API (if key provided) or WEB when DB rows are missing.
#### Fixed
- Corrected ESV API key lookup (`ESV_API_KEY`) to prevent unintended fallback to WEB when ESV is selected.
- Improved ESV parsing to handle bracketed verse markers and unicode punctuation so chapters load in ESV without falling back.
- Initial project setup with SwiftUI entry points (`Bible_AppApp.swift`, `ContentView.swift`).
- Supabase integration via `SupabaseManager.swift`.
- Services:
  - `AppearanceService.swift`
  - `AudioService.swift`
  - `AuthService.swift`
  - `BibleRouter.swift`
  - `BibleService.swift`
  - `HeaderService.swift`
  - `LibraryService.swift`
  - `ReadingTrackerService.swift`
  - `StreakService.swift`
  - `ValidationService.swift`
  - `VerseOfTheDayService.swift`
- Views:
  - `BookListView.swift`
  - `BookmarksNotesView.swift`
  - `FocusedVersesView.swift`
  - `HomeView.swift`
  - `MainTabsView.swift`
  - `ProfileSheetView.swift`
  - `ReadingTrackerView.swift`
  - `SignInView.swift`
  - `SplitStudyView.swift`
  - `ValidationReportView.swift`
  - `VersesView.swift`
- Models:
  - `BibleVerse.swift`
  - `Bookmark.swift`
  - `Footnote.swift`
  - `Notifications.swift`
- Data and assets:
  - `verses_of_the_day_curated.json`
  - Asset catalogs in `Assets.xcassets/`
- Documentation:
  - `README.md` with setup, features, and SQL schemas
  - `Header.md`
  - `CHANGELOG.md` and `Plans.md` scaffolds

