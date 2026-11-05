# Genki: instructions for agents and contributors

Read this file before you change anything. It is the source of truth for how work happens in this repo. `CLAUDE.md` imports it. Other agents (Codex, Cursor, Copilot) read it directly. Humans should follow it too. Decision IDs (D-xxx) point to `docs/DECISIONS.md`.

## What Genki is

Genki is a personal health archive for iPhone and iPad. The patient owns it. It collects visit records, checkup reports, test results and medical images from different hospitals in one place on the device.

- **Audience:** a public App Store app, one person per install (D-005). The license is Apache-2.0 (D-017).
- **Current phase:** making v1 work, milestones M0–M3. Next, M4 redesigns the UI and M5 releases. The scope and order are in `docs/TODO.md` (D-006, D-019).
- **Stack:** SwiftUI, SwiftData, Vision (on-device OCR), VisionKit (document scanner). No third-party dependencies.
- **Targets:** iOS/iPadOS 26.5+. iPhone and iPad are both first-class (D-008). Built with Xcode 26.5+ (verified on Xcode 27.2).
- **Build settings that matter:** `SWIFT_VERSION = 6.0` (D-016), `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`. The project uses file-system-synchronized groups, so new files under `Genki/` are picked up without editing `project.pbxproj`.
- **Languages:** docs, code, comments and commits are in English. The UI's source language is Simplified Chinese, and English is the second UI language (D-009).

## Non-negotiables

Stop and ask the human before you cross any of these lines. A "yes" goes into `docs/DECISIONS.md`.

1. **Health data stays on the device** unless the user takes an explicit action, such as exporting or sharing. Do not add network calls, analytics, crash reporters, or third-party SDKs. The App Store privacy label says "Data Not Collected", and that must stay true.
2. **No CloudKit or HealthKit in v1, and no new entitlement or permission string without a decision.** Approved so far: camera (`NSCameraUsageDescription`), `NSFileProtectionComplete` data protection (D-012), and Face ID for the opt-in app lock (D-013). iCloud sync and Apple Health writes come after v1. Adding either one needs a decision that also defines its adapter boundary (D-018).
3. **Do not lose user data.** Existing stores hold real records, and they must survive every update (D-007). Every SwiftData schema change ships with a migration and a test that opens a store from the previous version. Destructive actions need confirmation or undo. A backup restore is idempotent (D-022).
4. **Never commit real patient data.** That covers tests, fixtures, screenshots, issues, commit messages, and logs. Demo data is fictional and sets `isDemo = true`.
5. **Do not log health content.** Never `print` field values. If you must log with `os.Logger`, mark the values `privacy: .private`.
6. **OCR is a suggestion.** Extracted values reach the form only through `DraftField.suggest`, which writes only to fields still at their default value, so OCR never overwrites what the user typed or picked (`Genki/RecordDraft.swift`). A field OCR filled shows a "from OCR" marker until the user edits or confirms it (D-014). The original image is always kept.
7. **No medical interpretation.** The app does not judge results as normal or abnormal, diagnose, or recommend treatment.

## How to work: pstack routes, ub-mode executes

This repo combines two agent skill stacks:

- **pstack**: Lauren Tan's (poteto) workflow stack. Its entry skill, `poteto-mode`, sends each task to a *playbook* and a set of *principles*.
- **ub-mode**: Robert C. Martin's (Uncle Bob) discipline. Every change goes through **First Make it Work → Then Make it Right → Practice**.

The two stacks share principle names. ub-mode is the reduced set. This repo does not include either skill (D-003). You can install them yourself if you want, but this file is complete on its own, and it wins where they disagree. The overrides are marked **[Genki]**.

**[Genki] Functional first.** In M0–M3, use standard SwiftUI components and system styling, with no custom visual design. This overrides pstack's "Experience First" for those milestones. From M4 on, UI code uses only the tokens and components in `Genki/DesignSystem/` (D-024).

### Start every non-trivial task like this

1. In your first message, state the goal, the problem, and the smallest change you expect to make. Then proceed without waiting, unless a non-negotiable is involved. If the evidence rules out the requested change, show the evidence and stop.
2. Find the item in `docs/TODO.md`, or add one. Set it to `[~]` with your name or agent ID. Work the current milestone before you start a later one.
3. Pick a playbook from the table below and copy its steps into your task list. If you skip a step, keep it in the list as `skip: <reason>`.

| Playbook | Use when | Steps |
|---|---|---|
| Session pickup | Starting a session | Read `docs/TODO.md` (the `[~]` items first) → `git log --oneline -15` → `git status` → continue the oldest `[~]` you own |
| Feature | New user-visible behavior | Find its use case in `docs/USE_CASES.md` → read the code path (*how*) → design the boundary first if the change crosses files/modules (*architect*) → failing test → smallest change → Make it Right → prove in the simulator → update `FEATURE_MAP.md` + `TODO.md` |
| Bug fix | Something is wrong | Reproduce with a failing test → find the first place it went wrong → fix there → Make it Right → prove |
| Refactoring | Same behavior, better structure | Pin the behavior with tests → change the structure → prove the behavior is unchanged → delete what became dead |
| Investigation | A question, with no code change | Stay read-only. Report findings labeled **measured** / **inferred** / **guess**, with file:line evidence |
| Perf issue | Slow, hot, or heavy | Measure first (Instruments or a timed test) → explain what limits the number → change → measure again |
| Design direction | Starting M4, or a new visual area | Build 2–3 distinct clickable mockups of the list, record and add-record screens → the human picks one → write `docs/DESIGN.md` + `Genki/DesignSystem/` → rebuild each screen with Visual parity (D-025) |
| Visual parity | Matching a design or screenshot | Simulator screenshot before → change → screenshot after on iPhone and iPad → compare |
| Prototype | Exploring an idea | Throwaway branch, no gates. Then delete it or rebuild it through Feature |
| Pause safely | Stopping mid-task | Leave the tree building. Update the `TODO.md` item with what is done, what is left, and the next command |

### Phase 1: First make it work

- **Laziness Protocol.** Ship the smallest complete edit. One decision lives in one place.
- **Foundational Thinking.** Get the data shape right before writing logic. In Genki, settle the SwiftData model and transfer types before views.
- **TDD.** Write the failing test first with Swift Testing (`import Testing`, `@Test`, `#expect`). Watch it fail for the expected reason, then make the smallest change that passes. If an honest test is impractical, as with pure layout, do not write a bad one. Prove it in the simulator instead.
- **Redesign from First Principles.** Do not bolt a new requirement onto the old design. Ask what you would have built if you had known about the requirement from the start, then deliver that in pieces.
- **Attack the Premise.** If two fixes based on the same premise fail the same check, write the premise down in one sentence and test it before you try a third fix.
- **Subtract Before You Add.** Remove the obsolete path before you build its replacement.
- **Outcome-Oriented Execution.** Aim at an end state you can check. Do not keep compatibility shims for code that never shipped. Persisted user data is the exception (see non-negotiable 3).
- **Build the Lever.** For repeated non-trivial work, do one unit by hand, then build the script or check that does the rest.
- **Architecture, in Swift terms:**
  - *Model the Domain.* Use the terms in `docs/GLOSSARY.md`. Add new terms there.
  - *Boundary Discipline.* Parse external input once, where it enters. OCR text becomes `ExtractedHealthFields`. Scanner, photo and file bytes become `AttachmentDraft`. Backups become `HealthRecordTransferRecord`. Keep business logic out of `View` bodies by moving it into plain types that can be tested without SwiftUI.
  - *Type System Discipline.* New code uses enums, not strings. SwiftData stores raw strings, such as `category` and `kind`, which convert at the model edge (`categoryValue`, `kindValue`). No `try!`, and no force unwraps outside tests and previews. Do not use `@unchecked Sendable` or `nonisolated(unsafe)` unless a comment names the external constraint that requires it.
  - *Make Operations Idempotent.* Seeding, import, migration and backup restore key on stable IDs (`recordID`, `attachmentID`). Running twice gives the same result.
  - *Separate Before Serializing Shared State.* Use one `ModelContext` per actor. Never pass `@Model` objects across actors. Pass IDs or `HealthRecordTransferRecord` instead.

### Phase 2: Then make it right

- **Fix Root Causes.** A guard that only hides the crash is not a fix.
- **Sequence Work into Verifiable Units.** Every unit ends with a passing build and passing tests before the next one starts.
- **Test Behavior, Not Implementation.** Call the code the way its user does and check what that user would see. If the test would still pass when every function returned nothing, delete it.
- **Quality gates.** Uncle Bob's `crapper`, `dryer` and `mutator` do not support Swift, so this repo uses equivalents (D-004). A gate blocks merging once its tool exists:

  | Gate | Genki tool | Threshold | Blocking |
  |---|---|---|---|
  | Build | `xcodebuild build` | no new warnings | now |
  | Tests | `xcodebuild test` | all pass | now |
  | Lint | `swiftlint lint --strict` | zero violations (D-026) | now |
  | Crapper | `scripts/crap.sh`: `lizard` complexity + `xccov` coverage | CRAP < 10 per function, non-View code | once T-004 lands |
  | Dryer | PMD CPD (`--language swift`) | no clone ≥ 50 tokens in `Genki/` | once T-005 lands |
  | Mutator | `muter` | no surviving mutants in changed non-View files | once T-006 lands |
  | UI smoke | XCUITest smoke flow | passes | once T-026 lands |

  If a gate cannot run, say so in your report, for example "Mutator: not run, muter not installed". Never claim a gate passed when it did not run.
- **Refactoring.** Pin what the code does, change the structure, then prove the behavior did not change.

### Phase 3: Practice

- **Keep a Log.** Your final report lists what you did, why, and the evidence. Commit messages carry the same three things.
- **Guard the Context Window.** Send broad searches to subagents and keep only their summaries. Never delegate the playbook itself. Verify what a subagent says it did before you repeat it.
- **Worktree Cleanup.** Remove worktrees and branches you created once they are merged or abandoned. Uncommitted work waits for a human decision.
- **Commit, then push.** **[Genki]** Commit to a feature branch after each verified unit, without asking. Make small, ordered commits, each saying why, what changed, and how it was proven. Never commit directly to `main`, which changes only through PRs. Pushing, opening PRs, merging, tagging and releasing need explicit human approval (D-010). This overrides ub-mode's "push to the main line".

## Definition of done

- [ ] Every blocking gate in the table above passes. Every non-blocking gate passed, or the report names it as "not run" with the reason.
- [ ] New behavior has a test that failed before the change.
- [ ] UI changes were run in the simulator on iPhone and on iPad, with a screenshot checked. If the layout changed, also check the largest Dynamic Type size and dark mode.
- [ ] CI is green on the PR (once T-020 lands).
- [ ] `docs/TODO.md` item set to `[x]` with the commit hash. `docs/FEATURE_MAP.md` status updated. A `docs/DECISIONS.md` entry exists if a decision was made.
- [ ] If a use-case flow or a diagrammed design changed, `docs/USE_CASES.md` or `docs/ARCHITECTURE.md` is updated in the same PR.
- [ ] The final report cites only the principles that actually shaped a decision, and labels claims measured / inferred / guess.

## Commands

If `xcodebuild` reports "requires Xcode, but active developer directory … is a command line tools instance", run `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, or run `sudo xcode-select -s /Applications/Xcode.app` once.

```bash
# Build (verified working)
xcodebuild -project Genki.xcodeproj -scheme Genki \
  -destination 'platform=iOS Simulator,name=iPhone 17' build | xcbeautify

# Test: GenkiTests via the shared Genki scheme (verified: 33 tests on iPhone 17 and iPad Pro 11")
xcodebuild -project Genki.xcodeproj -scheme Genki \
  -destination 'platform=iOS Simulator,name=iPhone 17' test | xcbeautify

# Lint (config: .swiftlint.yml, verified: 0 violations)
swiftlint lint --strict
```

CI (T-020) will run the same commands on GitHub's `macos-26` runners. Those runners have Xcode 26.x, which also catches any API newer than the iOS 26.5 minimum.

The document scanner needs a real device camera. Photo import and manual entry work in the simulator. Debug builds seed three fictional demo records on first launch.

## Releases

- **Only the human** signs, archives, and uploads to TestFlight and App Store Connect. Agents never touch certificates, provisioning profiles, or App Store Connect (D-021).
- **Agents prepare:** the version and build number bump, release notes, a check that the privacy label is still "Data Not Collected" (non-negotiable 1), and the `vX.Y.Z` tag. The tag is pushed only after approval.

## Code map

| File | Owns |
|---|---|
| `Genki/GenkiApp.swift` | App entry: opens the store, or shows `StoreUnavailableView` |
| `Genki/GenkiStore.swift` | The one place the schema and `cloudKitDatabase: .none` live; `StoreUnavailableView` |
| `Genki/HealthRecord.swift` | SwiftData models `HealthRecord`, `RecordAttachment`; `HealthRecordCategory`, `AttachmentKind`, `AttachmentSource` |
| `Genki/HealthRecordTransfer.swift` | Versioned, store-independent transfer types: the future backup format |
| `Genki/ContentView.swift` | Record list, search box, swipe-to-delete with confirmation |
| `Genki/RecordTimeline.swift` | Search filter and month grouping (pure, tested); `searchableFields` |
| `Genki/NewHealthRecordView.swift` | Add-record form: attachments, scanner/photo import, OCR trigger, save |
| `Genki/RecordFormSections.swift` | The form's text sections; `Binding<RecordDraft>.field(_:)` |
| `Genki/RecordDraft.swift` | `RecordDraft`, `DraftField`, `FieldOrigin`, `AttachmentDraft`: every form rule (tested) |
| `Genki/RecordFormField.swift` | Keyboard focus order (pure, tested) |
| `Genki/AttachmentDraftThumbnail.swift` | Thumbnail of an unsaved attachment |
| `Genki/HealthRecordDetailView.swift` | Read-only detail, attachment viewer |
| `Genki/OCRService.swift` | Vision OCR; `HealthFieldExtractor` (pure, tested) and `FieldPattern` |
| `Genki/DocumentScannerView.swift` | VisionKit scanner adapter (pages, cancel, failure) |
| `Genki/DemoDataSeeder.swift` | DEBUG-only fictional records and AI-generated demo images |
| `Genki/HealthRecordStyle.swift` | SF Symbols and tints per category/kind |
| `Genki/String+Trimmed.swift`, `Genki/Binding+IsPresenting.swift` | Small shared helpers |
| `GenkiTests/` | Swift Testing unit tests; `TestStore` gives each test an in-memory store |
| `Genki/DesignSystem/` | Starting in M4: color, type and spacing tokens, and shared components (T-029) |

## Conventions

- **Tests:** use Swift Testing for unit tests. The only UI test is one XCUITest smoke flow: create → search → edit → delete with confirmation (T-026, D-020). Tests use an in-memory `ModelContainer` and never use the real store.
- **Strings:** user-facing text goes through `LocalizedStringResource`, `String(localized:)` or a SwiftUI string literal, so the String Catalog picks it up (T-011). Simplified Chinese is the source language. Do not build UI text by concatenating strings.
- **Styling:** use system styling until M4. After M4, use only `Genki/DesignSystem/` (D-024).
- **Accessibility:** every control has a label. Decorative images use `.accessibilityHidden(true)`. Rows combine their children (`.accessibilityElement(children: .combine)`).
- **Comments:** write one only for a non-obvious constraint that comes from outside the code, such as an OS limitation, a privacy rule, or a data-format promise. The doc comments in `HealthRecordTransfer.swift` and `RecordDraft.swift` are the model.
- **Dependencies:** none. Adding a Swift package needs a `DECISIONS.md` entry.
- **Previews:** use in-memory containers with fictional data only.

## Tracking docs

| File | Purpose | Who updates it |
|---|---|---|
| `docs/README.md` | The reading order for humans | Whoever adds a doc |
| `docs/USE_CASES.md` | Actors and use cases (the requirements model). Alternate flows become tests | Whoever changes a use case's behavior |
| `docs/ARCHITECTURE.md` | Layers, domain model, capture flow, and the field-origin state machine, as Mermaid diagrams | Whoever changes a diagrammed design |
| `docs/FEATURE_MAP.md` | What the app does, by area, with status, v1 scope and code pointers | Whoever changes a feature's status |
| `docs/TODO.md` | The single backlog, ordered by milestone (D-011). Claim items with `[~]`, finish them with `[x]` and the commit hash | Everyone, every task |
| `docs/DECISIONS.md` | Decisions with reasons. Append-only; supersede an entry instead of editing it | Whoever makes or records a decision |
| `docs/GLOSSARY.md` | Domain terms in zh / en / code | Whoever introduces a term |
| `docs/DESIGN.md` | Starting in M4: the chosen visual direction and how to use the design system | Whoever changes the design system |

## Authority

- **Proceed without asking:** reversible local work. That covers reading, editing, building, testing, simulator runs, local branches and worktrees, and commits to feature branches.
- **Ask first:** pushing, PRs, merging, tags, releases, adding dependencies, entitlements or permission strings, deleting a user-visible feature, and anything that touches a non-negotiable.
- **Never:** commit to `main`, handle signing material, or use App Store Connect.
- **Never block on the human for reversible in-scope work.** Make the reasonable choice, note it in the report, and keep going.
