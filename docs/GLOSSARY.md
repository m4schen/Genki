# Glossary

Use these terms in code, docs and UI copy. If you introduce a new domain term, add it here first.

| English | 中文 (UI) | Code | Meaning |
|---|---|---|---|
| Record | 健康记录 | `HealthRecord` | One health event: a visit, checkup, test or other entry, with its fields and attachments |
| Visit | 就诊 | `.visit` | Outpatient, emergency or inpatient care. Legacy values: 门诊, 急诊, 住院 |
| Checkup | 体检 | `.checkup` | A routine physical or health screening |
| Test | 检查 | `.test` | An exam or lab test report. Legacy values: 检查 / 检验, 检查报告, 检验报告 |
| Institution | 医院或体检机构 | `hospitalName` | Hospital, clinic or checkup center. Future transfer ID: `institution.name` |
| Diagnosis or conclusion | 诊断或结论 | `diagnosisOrConclusion` | The doctor's diagnosis, or a report's conclusion when nothing was diagnosed |
| Examination results | 检查或检验结果 | `examinationResults` | Findings and measured values, kept as free text |
| Doctor advice | 医生建议或后续安排 | `doctorAdvice` | Orders and next steps |
| Medical record number | 门诊号、住院号或报告编号 | `medicalRecordNumber` | The institution's identifier. Sensitive: never log it |
| Follow-up date | 复查日期 | `followUpDate` | When the patient should return |
| Attachment | 资料与影像 | `RecordAttachment` | Image bytes (external storage) plus kind, source and order |
| Medical image | 医学影像 | `.medicalImage` | X-ray, fundus photo and similar images |
| Source | — | `AttachmentSource` | How bytes arrived: `scanner`, `photoLibrary`, `fileImport`, `demo` |
| Raw OCR text | OCR 原文 | `rawOCRText` | Unedited Vision output, kept for search and audit |
| Extracted fields | — | `ExtractedHealthFields` | Suggestions parsed from OCR text, including a category guess. They only fill fields still at their default |
| Record draft | — | `RecordDraft` | The form's unsaved values. Nothing is stored until Save |
| Field origin | — | `FieldOrigin`, `DraftField` | Where a form value came from: `defaultValue`, `suggestedByOCR` or `userOwned`. OCR may write only to `defaultValue` |
| Demo record | 演示 | `isDemo` | Fictional seed data, DEBUG builds only |
| Transfer record | — | `HealthRecordTransferRecord` | A versioned, `Sendable` snapshot detached from SwiftData. It's the unit of a backup (D-022) |
| Backup | 备份 (proposed) | `manifest.json`, `records.json`, `assets/` | A full export of every record and original file, encrypted by default (D-022, D-023) |
| From OCR marker | 来自 OCR (proposed) | — | Shows that OCR filled a field and the user hasn't confirmed it yet (D-014) |
| App lock | 应用锁 (proposed) | — | Optional Face ID / passcode gate plus the app-switcher cover (D-013) |
| Milestone | — | M0 … M5 | A stage of the v1 plan (D-019) |
