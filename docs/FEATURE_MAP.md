# Feature map

What Genki does today, what v1 needs, and where each piece lives. Change a status whenever you change a feature. Backlog items in `TODO.md` point here by feature ID.

**Status:** `shipped` works end to end · `partial` works with known gaps · `planned` agreed but not built · `deferred` agreed not now
**v1:** `yes` must ship in the first App Store release · `post` after v1 (D-006)

Last verified against code: 2026-11-05, commit `5ff575c`.

## F1 Records

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F1.1 | Create a record by hand | shipped | yes | `NewHealthRecordView.swift` | Date, institution, department, conclusion; more fields under "更多信息" |
| F1.2 | Categories: visit / checkup / test / other | shipped | yes | `HealthRecord.swift` `HealthRecordCategory` | Stored as a raw string (D-002). `categoryValue` maps legacy Chinese values |
| F1.3 | Edit an existing record | planned | yes | — | The detail view is read-only, so a typo can't be fixed (T-010) |
| F1.4 | Delete a record | partial | yes | `ContentView.swift` `deleteRecords` | Swipe deletes at once, with no confirmation or undo (T-008) |
| F1.5 | Follow-up date | partial | yes | `HealthRecord.followUpDate` | Stored and shown. Reminders come after v1 (T-015) |
| F1.6 | Save reliability | partial | yes | `NewHealthRecordView.save()` | Relies on autosave and never calls `modelContext.save()`, so a failed write is invisible (T-009) |
| F1.7 | Several people per install (family) | deferred | post | — | v1 is one person per install (D-005, T-037) |

## F2 Capture

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F2.1 | Scan paper documents | shipped | yes | `DocumentScannerView.swift` | Device only; scanner errors are reported as a cancel |
| F2.2 | Import photos and medical images | shipped | yes | `NewHealthRecordView.importPhotos` | Up to 20 per pick, images only |
| F2.3 | Import PDFs and files | planned | yes | — | `AttachmentSource.fileImport` exists but nothing uses it (T-013) |
| F2.4 | Attachment kinds: document / medical image / photo / other | shipped | yes | `AttachmentKind` | Bytes use `.externalStorage` |

## F3 OCR and field extraction

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F3.1 | On-device OCR (zh-Hans, zh-Hant, en-US) | shipped | yes | `OCRService.recognize` | Vision `.accurate`, runs detached |
| F3.2 | Extract fields from OCR text | partial | yes | `HealthFieldExtractor` | Chinese regex labels only, untested; first TDD target (T-002) |
| F3.3 | Fill only empty fields | partial | yes | `NewHealthRecordView.fillIfEmpty` | Text fields are correct, but the date and the category get overwritten (bug T-038; fix design in ARCHITECTURE.md §4) |
| F3.4 | Guess category from text | shipped | yes | `NewHealthRecordView.inferCategory` | Keyword match |
| F3.5 | Mark OCR-filled fields "from OCR" | planned | yes | — | The marker stays until the user edits or confirms the field (D-014, T-022) |

## F4 Browse and search

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F4.1 | Timeline grouped by month | shipped | yes | `ContentView.monthSections` | |
| F4.2 | Full-text search incl. OCR text | shipped | yes | `ContentView.filteredRecords` | In-memory filter over all records (perf check: T-018) |
| F4.3 | Filter by category / institution / date range | deferred | post | — | (T-016) |
| F4.4 | iPad layout (sidebar + detail) | planned | yes | — | `NavigationStack` only, no `NavigationSplitView` (T-012) |

## F5 View and share

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F5.1 | Record detail | shipped | yes | `HealthRecordDetailView.swift` | |
| F5.2 | Attachment viewer | shipped | yes | `HealthRecordDetailView.swift` `AttachmentViewer` | |
| F5.3 | Share a record's original images via the share sheet | planned | yes | — | User-initiated only (non-negotiable 1, T-023) |
| F5.4 | Formatted PDF summary of a record | deferred | post | — | (T-036) |

## F6 Data safety and privacy

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F6.1 | Local-only store, CloudKit off | shipped | yes | `GenkiApp.swift` `cloudKitDatabase: .none` | D-001 |
| F6.2 | Data unreadable while the device is locked | planned | yes | — | `NSFileProtectionComplete` entitlement (D-012, T-021) |
| F6.3 | Opt-in app lock (Face ID / passcode) and app-switcher cover | planned | yes | — | Off by default (D-013, T-024) |
| F6.4 | Full backup export and restore | planned | yes | — | Format D-022; encrypted by default, D-023 (T-014) |
| F6.5 | Schema versioning and migration | partial | yes | `HealthRecord.schemaVersion` | Has a version field but no `VersionedSchema` or migration plan; `ModelContainer` failure calls `fatalError` (T-007) |
| F6.6 | No health content in logs | shipped | yes | — | No logging exists. Keep it that way (non-negotiable 5) |

## F7 Integrations

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F7.1 | Transfer types (`HealthRecordTransferRecord` and friends) | partial | yes | `HealthDataIntegration.swift:29-316` | Kept; they become the backup format (D-018) |
| F7.2 | Sync/Health adapter scaffold | partial | no | `HealthDataIntegration.swift:3-28, 317-523`, `HealthDataIntegrationEnvironment.swift` | Delete in T-025 (D-018) |
| F7.3 | Personal iCloud sync | deferred | post | — | Private database only; needs a new decision (T-034) |
| F7.4 | Write to Apple Health / Medications | deferred | post | — | HealthKit clinical records are read-only (T-035) |

## F8 Platform and quality

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F8.1 | iPhone + iPad, both first-class | partial | yes | build settings | iPad runs the phone layout (F4.4, D-008) |
| F8.2 | Localization: zh-Hans source, English second | planned | yes | — | No `.xcstrings` yet (D-009, T-011) |
| F8.3 | Accessibility | partial | yes | row views | Labels and combined rows exist; audit after the redesign (T-017) |
| F8.4 | Unit tests (Swift Testing) | planned | yes | — | No test target (T-001) |
| F8.5 | Quality gates: lint, CRAP, duplication, mutation | planned | yes | — | D-004 (T-003 … T-006) |
| F8.6 | CI on GitHub Actions | planned | yes | — | D-015 (T-020) |
| F8.7 | Swift 6 language mode | planned | yes | — | A trial build had 2 errors (`HealthRecord.swift:182`, `:196`) (D-016, T-019) |
| F8.8 | UI smoke test | planned | yes | — | One XCUITest flow (D-020, T-026) |
| F8.9 | Apache-2.0 license | planned | yes | — | No LICENSE file yet (D-017, T-027) |

## F9 Developer support

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F9.1 | Demo data (DEBUG) | shipped | yes | `DemoDataSeeder.swift` | Three fictional records and two AI-generated images with C2PA provenance |

## F10 Design and UX (M4)

| ID | Feature | Status | v1 | Where | Notes |
|---|---|---|---|---|---|
| F10.1 | Visual direction, chosen from 2–3 mockups | planned | yes | — | D-025 (T-028) |
| F10.2 | Design system: tokens and shared components | planned | yes | `Genki/DesignSystem/`, `docs/DESIGN.md` | (T-029) |
| F10.3 | Redesigned screens | planned | yes | — | Visual parity per screen (T-030) |
| F10.4 | First-launch onboarding | planned | yes | — | (T-031) |
