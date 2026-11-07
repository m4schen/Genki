# TODO

The single backlog for humans and agents (D-011), ordered by milestone (D-019). Work the current milestone before you start a later one. Quality-gate items (T-005, T-006) can be picked up any time during M1–M2.

**Markers:** `[ ]` open · `[~]` in progress (add `@who`) · `[x]` done (add the commit hash or PR) · `[!]` blocked (add the reason)

**Rules:**
- Claim an item before you start. Set it to `[~] @name`.
- Every item has a **Done when** line that someone else could check.
- Finished items move to **Done** with the commit hash. Never delete them.
- New ideas go to **Post-v1**, or to **Needs decision** if the right answer isn't clear.
- Priority: **P0** blocks safe use or blocks other work · **P1** needed for v1 · **P2** nice to have.

## M0 Foundation


## M1 Data safety

- [ ] **T-007** Add `VersionedSchema` V1 and a `SchemaMigrationPlan` · P0 · F6.5 · D-007
  - Done when: a test opens a V1 store through the plan. (The recoverable error screen already shipped as T-041.)
- [ ] **T-021** Add `com.apple.developer.default-data-protection = NSFileProtectionComplete` · P1 · F6.2 · D-012
  - Done when: an entitlements file is checked in, and a check on a device shows the store file's `FileProtectionType` is `.complete`.
- [ ] **T-014** Backup export and restore · P0 · F6.4 · D-022, D-023
  - Done when: export, then delete the app, then restore round-trips the demo records with every attachment hash matching (tested); restoring twice creates no duplicates; the encrypted path decrypts with the right password and fails clearly with a wrong one; plain export shows the warning.
- [ ] **T-005** Set up the duplication gate (PMD CPD, Swift, 50 tokens) · P2 · F8.5
  - Done when: one command reports clones and the repo has none above the threshold. (The duplicate `String.trimmed` it would have caught was already merged into `String+Trimmed.swift`, 5c1231f.)
- [ ] **T-042** Improve OCR field extraction, found while pinning it (T-002) · P2 · F3.2 · UC1
  - (a) A label alone on its line takes the next line as its value, even when that line is another label (pinned in `readsValueFromNextLine`).
  - (b) Full-width digits in dates ("２０２６年３月５日") aren't parsed.
  - (c) Inferred, untested: "医生建议：…" may also be read as a doctor name.
  - Done when: each case has a test with the behavior the product wants.
- [ ] **T-006** Set up the mutation gate (`muter`) against `GenkiTests` · P2 · F8.5
  - Done when: `muter` runs on `OCRService.swift` and survivors are listed or killed.

## M2 Core features

- [ ] **T-010** Edit an existing record (reuse the create form) · P1 · F1.3
  - Done when: from the detail view, editing a field and saving updates `updatedAt`, and the change persists across relaunch.
- [ ] **T-013** Import PDFs and files via `fileImporter`, with OCR on PDF pages · P1 · F2.3
  - Done when: a fictional PDF imports as attachments with `source = fileImport`, and its OCR text fills empty fields.
- [ ] **T-022** Mark OCR-filled fields "from OCR" until the user edits or confirms them · P1 · F3.5 · D-014
  - Done when: after OCR, filled fields show the marker; editing a field removes its marker; fields the user typed never get one.
- [ ] **T-023** Share a record's original images through the system share sheet · P1 · F5.3
  - Done when: from the detail view, sharing sends the untouched original bytes (hash matches); nothing is shared without a user tap.
- [ ] **T-026** XCUITest smoke flow, run in CI: create → search → edit → delete with confirmation · P1 · F8.8 · D-020
  - Done when: the flow passes locally and in CI and uses only fictional data.

## M3 Platform

- [ ] **T-012** iPad layout with `NavigationSplitView` · P1 · F4.4 · D-008
  - Done when: on iPad Pro 11" the list and detail show side by side in landscape (screenshot); iPhone is unchanged.
- [ ] **T-011** Add a String Catalog (`Localizable.xcstrings`) with zh-Hans as the source and English as the second language · P1 · F8.2 · D-009
  - Done when: every user-facing string is in the catalog; the app runs in English with no Chinese left in the UI.
- [ ] **T-024** Opt-in app lock (Face ID / passcode) and an app-switcher privacy cover · P1 · F6.3 · D-013
  - Done when: the lock is off by default; when it's on, a relaunch or return from background asks to unlock; the app-switcher snapshot shows no record content; `NSFaceIDUsageDescription` is added.

## M4 UI/UX design

- [ ] **T-028** Build 2–3 distinct visual directions as clickable mockups of the list, record and add-record screens; the human picks one · P1 · F10.1 · D-025
  - Done when: the human has chosen a direction and the choice is recorded in DECISIONS.md.
- [ ] **T-029** Write `docs/DESIGN.md` and build `Genki/DesignSystem/` (color, type and spacing tokens, plus shared components) · P1 · F10.2 · D-024
  - Done when: tokens are defined once, and support light, dark and Dynamic Type.
- [ ] **T-030** Rebuild each screen on the design system with the Visual parity playbook: list, detail, form, attachment viewer, settings, backup · P1 · F10.3
  - Done when: each screen has before/after screenshots on iPhone and iPad; no screen uses styling outside `DesignSystem/`.
- [ ] **T-031** First-launch onboarding: what Genki stores, that data stays on the device, and how to back up · P1 · F10.4
  - Done when: onboarding shows once and can be skipped; it makes no claim the app doesn't keep.
- [ ] **T-017** Accessibility audit: VoiceOver walk-through and the largest Dynamic Type size on every screen · P1 · F8.3
  - Done when: every screen is usable with VoiceOver and at AX5 text size; the problems found are fixed or filed.

## M5 Release

- [ ] **T-032** Release prep (agent): version and build bump, release notes, a check that the privacy label is "Data Not Collected", draft App Store text · P1 · D-021
  - Done when: the human has approved the prep PR.
- [ ] **T-033** Archive, sign, TestFlight, then App Store submission (human only) · P1 · D-021
  - Done when: v1.0.0 is live, and the `v1.0.0` tag is pushed.

## Post-v1

- [ ] **T-015** Follow-up reminders through local notifications · P2 · F1.5
- [ ] **T-016** Filter by category, institution and date range · P2 · F4.3
- [ ] **T-018** Search performance check at 1,000 records (measure before changing anything) · P2 · F4.2
- [ ] **T-034** Personal iCloud sync (private database), built on the transfer types · needs a decision · F7.3
- [ ] **T-035** Write to Apple Health / Medications · needs a decision · F7.4
- [ ] **T-036** Formatted PDF summary of a record · P2 · F5.4
- [ ] **T-037** Several people per install (family profiles) · needs a decision · F1.7

## Needs decision

Add questions here as `Q-n`, with the feature ID. Settle these before T-014 starts.

- [ ] **Q-1** Restore finds a record with the same `recordID` but different content: which one wins? Recommended: keep whichever has the newer `updatedAt`, and never delete device records that aren't in the backup · F6.4 · UC8 4a
- [ ] **Q-2** Restore finds a missing or corrupt asset: skip that record, or restore nothing? Recommended: restore nothing, and name the affected records · F6.4 · UC8 3b

## Done

- [x] **T-000** Add AGENTS.md, CLAUDE.md, the feature map, TODO, decisions and glossary; record the decisions from the grill session (D-003 … D-025) · 0793f19
- [x] **T-001** Add a `GenkiTests` unit test target using Swift Testing · P0 · F8.4 · 308a015
  - Done when: `xcodebuild … test` runs at least one test on the iPhone 17 simulator, and AGENTS.md → Commands says so.
- [x] **T-019** Switch to Swift 6 language mode · P1 · F8.7 · D-016 · 57503f9
  - Done when: `SWIFT_VERSION = 6.0`; the two errors at `HealthRecord.swift:182` and `:196` are fixed at the cause, not silenced; build and tests pass.
- [x] **T-002** TDD `HealthFieldExtractor` with fictional report text: every field, full-width colons, the three date formats, no match → nil · P0 · F3.2 · fa4f6f6
  - Done when: each regex branch has a behavior test; one test per real OCR sample shape.
- [x] **T-003** Add `.swiftlint.yml` and make `swiftlint lint --strict` pass · P1 · F8.5 · 6f44fcd
  - Done when: zero violations; the config is checked in; the rules are justified in DECISIONS.md.
- [x] **T-009** Make save explicit: `try modelContext.save()` and show an error when it fails · P0 · F1.6 · 5c1231f
  - Done when: a failed save shows an alert and keeps the form open.
- [x] **T-039** Extract `RecordDraft` from `NewHealthRecordView`: field values, a `FieldOrigin` per field, OCR apply, and building a `HealthRecord` · P1 · F1.3, F3.3 · UC1, UC5 · 5c1231f
  - Done when: the form view holds one `RecordDraft` instead of 19 `@State` fields; draft logic has unit tests; behavior is unchanged (Refactoring playbook). See ARCHITECTURE.md §4.
- [x] **T-038** Bug: OCR overwrites a date or category the patient chose · P0 · F3.3 · UC1 step 5a · D-014 · 5c1231f
  - Done when: tests prove that a date the patient picked, or a category the patient chose, survives OCR, and that untouched defaults can still be filled. Builds on T-039.
- [x] **T-008** Confirm before deleting a record · P0 · F1.4 · c2ec4b2, 3621703
  - Done when: swipe-delete asks for confirmation; a test or simulator run proves a cancelled delete keeps the record.
- [x] **T-025** Delete the sync/Health scaffold and keep the transfer types · P1 · F7.1, F7.2 · D-018 · dc4b287
  - Done when: `HealthDataIntegration.swift:3-28, 317-523`, the change-set/deletion types, `SystemHealthDataTypeIdentifier` and `HealthDataIntegrationEnvironment.swift` are gone; the kept types have Codable round-trip tests; README no longer mentions reserved sync interfaces.
- [x] **T-041** Replace `fatalError` at startup with a recoverable "store unavailable" screen (`GenkiStore`, `StoreUnavailableView`) · P0 · F6.5 · D-007 · dc4b287
  - Done when: a store that can't be opened shows a screen saying the data was not deleted, instead of crashing.
- [x] **T-027** Add the Apache-2.0 `LICENSE` and a license line in README · P1 · F8.9 · D-017 · 5982850
  - Done when: GitHub shows the repo as Apache-2.0.
- [x] **T-004** Build `scripts/crap.sh`, which joins `lizard` per-function complexity with `xccov` coverage and fails on CRAP ≥ 10 · P1 · F8.5 · D-004 · 3164d70
  - Done when: it runs on the repo, prints the worst 10 functions, and exits non-zero above the threshold.
- [x] **T-020** GitHub Actions CI: build, test and lint on every PR, on `macos-26` · P1 · F8.6 · D-015 · 52d6a7f, 85a963a
  - Done when: a PR shows a green check with all three steps; a deliberately failing test turns it red.
  - Proof (PR #4): run 42342747562 green on all steps (lint, simulator, build + test with warnings as errors, CRAP); run 42345387043 red on the deliberate `CIRedCheckTests` failure only (commit 4de43bc, reverted).
  - First run failed: `xcodebuild` found no simulator by name although iPhone 17 on iOS 26.5 existed (inferred: the simulator service hadn't started). `scripts/ci_simulator.py` now runs `simctl` first and passes an exact UDID.
- [x] **T-040** Add USE_CASES.md, ARCHITECTURE.md (Mermaid diagrams) and the docs index for human readers · c8b56da
