# Architecture

This file explains how Genki's code is organized, for humans first. It holds four diagrams: layers, domain model, the capture flow, and field origin. The diagrams are Mermaid, which GitHub renders. Update a diagram in the same PR as the code it describes. A stale diagram is worse than none.

## 1. Layers: boundary, control, entity

Every type plays one of three roles (Jacobson's analysis model):

- **Boundary** talks to the outside: to the patient through SwiftUI views, or to iOS through the camera, Vision and files.
- **Control** holds the rules and decisions for a use case. It is plain Swift with no UI, so it can be unit-tested.
- **Entity** is the data that persists.

```mermaid
flowchart LR
  subgraph Boundary
    CV[ContentView]
    NV["NewHealthRecordView<br/>+ RecordFormSections"]
    DV[HealthRecordDetailView]
    SV[DocumentScannerView]
    OS[OCRService]
  end
  subgraph Control
    TL[RecordTimeline]
    RD["RecordDraft<br/>(DraftField, FieldOrigin)"]
    FX[HealthFieldExtractor]
    FF[RecordFormField]
    DS[DemoDataSeeder]
  end
  subgraph Entity
    HR[HealthRecord]
    RA[RecordAttachment]
    TR[HealthRecordTransfer types]
  end
  CV --> TL
  NV --> SV
  NV --> OS
  NV --> RD
  NV --> FF
  RD --> FX
  RD --> HR
  DS --> HR
  DV --> HR
  HR --> RA
```

Every piece of control logic is now its own plain type, with unit tests in `GenkiTests/`. Views only lay out and forward user actions. `HealthRecordTransfer` holds versioned types that aren't stored yet; they become the backup format (T-014).

**Where new code goes**

| You are adding… | Put it in… |
|---|---|
| A rule, calculation or decision | A plain `struct` or `enum` under `Genki/`, with a Swift Testing test |
| Something the patient sees | A `View` that calls the rule, with no logic in `body` |
| Access to a new iOS capability (files, Face ID) | A thin adapter type, like `OCRService` |
| A new stored field | `HealthRecord`, plus a migration and its test (non-negotiable 3) |

## 2. Domain model

These are the concepts and how they relate. There is no `Patient` type, because v1 has one person per install (D-005). The institution is plain text today.

```mermaid
classDiagram
  direction LR
  class HealthRecord {
    recordID: UUID
    occurredAt: Date
    category: HealthRecordCategory
    hospitalName: String
    diagnosisOrConclusion: String
    examinationResults: String
    medications: String
    followUpDate: Date optional
    rawOCRText: String
    isDemo: Bool
  }
  class RecordAttachment {
    attachmentID: UUID
    sortOrder: Int
    kind: AttachmentKind
    source: AttachmentSource
    imageData: Data
  }
  class HealthRecordCategory {
    <<enumeration>>
    visit
    checkup
    test
    other
  }
  class AttachmentKind {
    <<enumeration>>
    document
    medicalImage
    photo
    other
  }
  class AttachmentSource {
    <<enumeration>>
    scanner
    photoLibrary
    fileImport
    demo
  }
  class ExtractedHealthFields {
    <<value>>
    suggestions parsed from OCR text
  }
  HealthRecord "1" *-- "0..*" RecordAttachment : attachments
  HealthRecord --> HealthRecordCategory
  RecordAttachment --> AttachmentKind
  RecordAttachment --> AttachmentSource
  ExtractedHealthFields ..> HealthRecord : fills empty fields of
```

How to read the diagram:

- **`*--` is composition.** Deleting a record deletes its attachments (`@Relationship(deleteRule: .cascade)`).
- **Enums are stored as raw strings** (D-002).
- **Only key fields are shown.** The full list is in `Genki/HealthRecord.swift`, and the terms are in `GLOSSARY.md`.

## 3. Capture flow (UC1)

This is what happens when the patient scans a report.

```mermaid
sequenceDiagram
  actor P as Patient
  participant F as NewHealthRecordView
  participant S as DocumentScannerView
  participant O as OCRService
  participant D as RecordDraft
  participant X as HealthFieldExtractor
  participant DB as ModelContext
  P->>F: Tap Add, then Scan
  F->>S: Present the scanner
  S-->>F: Page images, cancel, or failure
  F->>D: addScannedPage(data)
  F->>O: recognize(imageData)
  Note over O: Vision runs on the device, off the main thread
  O-->>F: Raw OCR text
  F->>D: applyRecognizedText(text)
  D->>X: extract(from: text)
  X-->>D: ExtractedHealthFields
  D->>D: suggest() fills only fields still at their default
  P->>F: Review, correct, tap Save
  F->>D: save(in: context)
  D->>DB: Insert record + attachments, then save()
  Note over D,DB: On failure the inserts are removed and the form stays open
```

Nothing touches the database until Save. Cancel just throws away the draft.

## 4. Field origin (design for T-038 and T-022)

OCR must never overwrite what the patient chose (non-negotiable 6). To enforce that, each form field needs to remember where its value came from. The patient sees the "from OCR" marker while a field is in the `SuggestedByOCR` state.

```mermaid
stateDiagram-v2
  [*] --> DefaultValue: form opens (empty, today, or visit)
  DefaultValue --> SuggestedByOCR: OCR finds a value
  DefaultValue --> UserOwned: patient types or picks
  SuggestedByOCR --> UserOwned: patient edits or confirms
  SuggestedByOCR --> DefaultValue: patient clears
  UserOwned --> DefaultValue: patient clears
  UserOwned --> UserOwned: OCR finds a value, ignored
```

The rule is: **OCR may write only to a field in the `DefaultValue` state.** This is implemented in `Genki/RecordDraft.swift`. Each form value is a `DraftField<Value>` that holds its value and a `FieldOrigin`. The value can change only through two methods, so the origin can't fall out of date:

```swift
mutating func setByUser(_ newValue: Value)  // → userOwned (or defaultValue if blank)
mutating func suggest(_ suggestion: Value?)  // writes only while origin == .defaultValue
```

The form binds every field through `setByUser`, and OCR goes through `suggest`. `RecordDraftTests` covers each transition. A hand mutation test (removing the origin check) made 4 of those tests fail.

## When to add a diagram

Only when a design is risky or hard to undo, and before the code is written:

- the backup format and restore flow (T-014)
- the schema migration (T-007)
- the app-lock states (T-024)

Everything else is covered by code, tests and `AGENTS.md`.
