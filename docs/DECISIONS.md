# Decisions

This log is append-only. To change a decision, add a new entry that supersedes the old one, and mark the old one `superseded by D-xxx`.

**Status:** `accepted` · `proposed` (waiting for a human yes) · `superseded`

Template:

```
## D-xxx Title
- Date: YYYY-MM-DD · Status: proposed | accepted | superseded by D-yyy
- Decision: what we do
- Why: the reason
- Consequences: what it costs or rules out
```

---

## D-001 Local-first, with no network by default
- Date: 2026-08-19 · Status: accepted (recorded from existing code and README)
- Decision: The SwiftData store stays on the device with `cloudKitDatabase: .none`. The app imports neither CloudKit nor HealthKit and requests no health permission.
- Why: Health records are sensitive, and the app is patient-owned.
- Consequences: Without an export there is no recovery if the device is lost, so backup becomes a v1 requirement (D-022).

## D-002 Persisted enums are stored as raw strings
- Date: 2026-08-19 · Status: accepted (recorded from existing code)
- Decision: `HealthRecord.category` and `RecordAttachment.kind` / `.source` are `String`s. Typed access goes through `categoryValue` / `kindValue`, which fall back to `.other`.
- Why: SwiftData migration safety, and legacy Chinese category values.
- Consequences: Invalid values can't crash the app, but they can be written. New code must write through the enums' `rawValue`.

## D-003 Workflow: pstack routes, ub-mode executes; skills not included
- Date: 2026-11-05 · Status: accepted
- Decision: `AGENTS.md` encodes pstack's playbooks and principles, plus ub-mode's Work → Right → Practice phases. The repo does not include either skill; contributors can install them for themselves. `AGENTS.md` wins over any skill.
- Why: Copied skills drift from upstream and could contradict the Genki overrides.
- Consequences: Rule changes happen only in `AGENTS.md`.

## D-004 Swift stand-ins for ub-mode's quality tools, phased in
- Date: 2026-11-05 · Status: accepted
- Decision: CRAP comes from `lizard` + `xccov` via `scripts/crap.sh` (threshold < 10, non-View code). Duplication comes from PMD CPD (50 tokens). Mutation testing uses `muter`. Lint uses SwiftLint `--strict`. Build, tests and lint block merging as soon as each exists. CRAP, duplication and mutation block once their tool lands; until then, a report says "not run".
- Why: `crapper`, `dryer` and `mutator` support Clojure, Java, Go, TypeScript, Rust and Python, but not Swift. Making every gate blocking on day one would stop all work.
- Consequences: Contributors need `lizard`, `pmd` and `muter` installed.

## D-005 Audience: a public App Store app, one person per install
- Date: 2026-11-05 · Status: accepted
- Decision: Genki is built for public App Store release. v1 stores one person's records per install.
- Why: It sets the bar for privacy and data safety. Family profiles would change every record's shape, so they're deferred.
- Consequences: App Store review and privacy-label rules apply. Family profiles come after v1 (T-037).

## D-006 v1 scope
- Date: 2026-11-05 · Status: accepted
- Decision:
  - In v1: create, edit and delete records with confirmation; scan, photo and PDF/file import; on-device OCR with suggestions; search; the iPad split layout; backup and restore; English UI; sharing original images; the M4 redesign and onboarding.
  - After v1: iCloud sync, Apple Health writes, reminders, filters, a formatted PDF summary, and family profiles.
- Why: It's the smallest app that's safe to trust with records. Users can fix mistakes, can't lose data by accident, and can get everything back out.
- Consequences: Work outside the v1 list waits in TODO → Post-v1.

## D-007 Existing stores hold real data
- Date: 2026-11-05 · Status: accepted
- Decision: Treat every existing store as holding real records that must survive every update.
- Why: A health archive that loses data on an update is worse than having no app.
- Consequences: Schema migration (T-007) is P0, and every schema change needs a migration test.

## D-008 iPhone and iPad are both first-class
- Date: 2026-11-05 · Status: accepted
- Decision: Every UI change is checked on iPhone and on iPad. The iPad split layout is in v1.
- Why: The target already includes iPad. Without a check, iPad keeps running the phone layout.
- Consequences: The definition of done needs screenshots on both devices.

## D-009 Languages
- Date: 2026-11-05 · Status: accepted
- Decision: Docs, code, comments and commits are in English. The UI's source language is Simplified Chinese, and English is the second UI language. README stays in Chinese for users.
- Why: English suits contributors and agents. Chinese is the primary audience.
- Consequences: A String Catalog is required (T-011).

## D-010 Git flow
- Date: 2026-11-05 · Status: accepted
- Decision: Agents commit to feature branches after each verified unit, without asking. `main` changes only through PRs. Pushing, PRs, merging, tags and releases need explicit human approval.
- Why: Small commits are cheap to undo. PRs give review and CI a place to run on a public repo.
- Consequences: This overrides ub-mode's "push to the main line".

## D-011 The backlog lives in `docs/TODO.md`
- Date: 2026-11-05 · Status: accepted
- Decision: `docs/TODO.md` is the single backlog. There are no GitHub Issues or Linear boards for planning.
- Why: Agents update the task in the same commit as the code, and it works offline.
- Consequences: GitHub Issues are only for outside bug reports. Agents move any accepted ones into TODO.md.

## D-012 Data is unreadable while the device is locked
- Date: 2026-11-05 · Status: accepted
- Decision: Add the entitlement `com.apple.developer.default-data-protection = NSFileProtectionComplete`.
- Why: iOS's default only protects files until the first unlock after a restart, which is too weak for medical records.
- Consequences: Nothing can read the store in the background. Future background work (reminders, sync) must not depend on reading the store while the device is locked.

## D-013 Opt-in app lock
- Date: 2026-11-05 · Status: accepted
- Decision: An optional Face ID or passcode lock, off by default, plus a privacy cover in the app switcher. Add `NSFaceIDUsageDescription`.
- Why: People hand their unlocked phones to others. Turning the lock on by default would make onboarding worse for people who don't want it.
- Consequences: Adds one permission string and a settings screen.

## D-014 Fields filled by OCR are marked
- Date: 2026-11-05 · Status: accepted
- Decision: A field filled by OCR shows a "from OCR" marker until the user edits or confirms it. There is no pop-up review step.
- Why: The form is already on screen. A pop-up adds a step every time, and people learn to tap through it.
- Consequences: The form has to track which fields OCR filled.

## D-015 CI on GitHub Actions
- Date: 2026-11-05 · Status: accepted
- Decision: Run build, tests and SwiftLint on every PR, on `macos-26` runners. Set it up right after T-001.
- Why: macOS runners are free for public repos. The runners have Xcode 26.x, so CI also catches APIs newer than the iOS 26.5 minimum.
- Consequences: CI may run a different Xcode version than local builds (27.2).

## D-016 Swift 6 language mode
- Date: 2026-11-05 · Status: accepted
- Decision: Switch to Swift 6 as a P1 task right after T-001.
- Why: A trial build had only 2 errors (`HealthRecord.swift:182`, `:196`, measured on 2026-11-05). Every feature added first makes the switch bigger.
- Consequences: Concurrency bugs become compile errors.

## D-017 License: Apache-2.0
- Date: 2026-11-05 · Status: accepted
- Decision: Add an Apache-2.0 LICENSE.
- Why: The repo is public. Without a license, nobody can legally reuse or contribute to it. Apache-2.0 is permissive and adds a patent grant. GPL conflicts with App Store terms.
- Consequences: Contributions arrive under Apache-2.0.

## D-018 Delete the sync/Health scaffold, keep the transfer types
- Date: 2026-11-05 · Status: accepted
- Decision: Keep `HealthDataIntegration.swift` lines 29–316 (the transfer types, minus the change-set/deletion types and `SystemHealthDataTypeIdentifier`). Delete the iCloud and system-health protocols, the adapters, the environment key and its injection.
- Why: Subtract Before You Add. About 270 lines have no callers. The transfer types become the backup format.
- Consequences: Sync and Health writes (post-v1) each need a new decision that defines their boundary. The old code stays in git history.

## D-019 Milestones
- Date: 2026-11-05 · Status: accepted
- Decision: M0 Foundation → M1 Data safety → M2 Core features → M3 Platform → M4 UI/UX design → M5 Release. Items for each milestone are in `docs/TODO.md`.
- Why: Data safety comes before features because real data must survive (D-007). Design waits until behavior is stable (D-024).
- Consequences: Agents work the current milestone first.

## D-020 UI tests: one smoke flow
- Date: 2026-11-05 · Status: accepted
- Decision: One XCUITest flow (create → search → edit → delete with confirmation) runs in CI. Other UI checks are simulator screenshots.
- Why: The form-to-store path is where users lose data. A wide UI suite would be slow and break easily.
- Consequences: Layout regressions rely on the screenshot step in the definition of done.

## D-021 Releases: only the human signs and uploads
- Date: 2026-11-05 · Status: accepted
- Decision: Only the human signs, archives, and uploads to TestFlight and the App Store. Agents prepare the version bump, release notes, the privacy-label check and the tag, all after approval.
- Why: Signing material and App Store Connect access shouldn't reach an agent, and a release can't be undone.
- Consequences: Agents never touch certificates, profiles or App Store Connect.

## D-022 Backup format
- Date: 2026-11-05 · Status: accepted
- Decision: A backup contains:
  - `manifest.json`: format version, app version, creation date, record count, and a SHA-256 hash for every asset
  - `records.json`: an array of `HealthRecordTransferRecord`
  - `assets/<attachmentID>.<ext>`: the original bytes, untouched
  
  Restore matches on `recordID` / `attachmentID`, so it is idempotent and adds no duplicates.
- Why: JSON plus the original files can be read without Genki. The hashes prove a restore came back complete.
- Consequences: Changing the format means bumping its version and keeping a reader for every older version.

## D-023 Backups are encrypted by default
- Date: 2026-11-05 · Status: accepted
- Decision: Export offers **Encrypted** (the default) or **Plain**. Encrypted uses Apple Encrypted Archive with the `hkdf_sha256_aesctr_hmac__scrypt__none` password profile. Plain is a zip, shown with a warning. The UI says that a lost password means a lost backup.
- Why: A backup leaves the protected app container. Apple Encrypted Archive is built in, so no dependency is added. The plain option keeps the data portable.
- Consequences: iOS availability of the profile is inferred and not yet tested; T-014 verifies it. A forgotten password can't be recovered.

## D-024 Functional first; design system from M4
- Date: 2026-11-05 · Status: accepted
- Decision: M0–M3 use standard SwiftUI components and system styling. M4 is an easy-to-use, polished UI/UX pass, including onboarding and the accessibility audit, before the first App Store release. From then on, UI code uses only `Genki/DesignSystem/`.
- Why: Polishing screens that are still changing wastes effort. Releasing before the redesign would make early users relearn the app.
- Consequences: This overrides pstack's "Experience First" for M0–M3. The app looks plain until M4.

## D-025 How the M4 design is chosen
- Date: 2026-11-05 · Status: accepted
- Decision: An agent builds 2–3 distinct clickable mockups of the list, record and add-record screens, and the human picks one. The choice becomes `docs/DESIGN.md` plus `Genki/DesignSystem/`. Each screen is then rebuilt with the Visual parity playbook.
- Why: Choosing between real options is faster than describing a look from scratch (Exhaust the Design Space for a decision that's hard to undo).
- Consequences: The design-system folder means each style choice lives in one place.

## D-026 SwiftLint configuration
- Date: 2026-11-06 · Status: accepted
- Decision: `.swiftlint.yml` keeps SwiftLint's defaults and changes one rule: `trailing_comma: mandatory_comma: true`. It lints `Genki/` and `GenkiTests/`, and the gate is `swiftlint lint --strict`. No `swiftlint:disable` comments.
- Why: The codebase already ends multi-line lists with a comma, as Airbnb's Swift style guide (`#trailing-commas`) requires. The defaults' length limits pointed at real smells, a 533-line form and an oversized struct, which the refactor fixed instead of suppressing.
- Consequences: Under `--strict`, warnings fail the gate too. For example, a type body over 250 lines must be split.
