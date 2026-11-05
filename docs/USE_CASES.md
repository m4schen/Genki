# Use cases

This is what Genki does for the patient, written so a human can check it and an agent can turn it into tests. It is the OOSE requirements model. Each alternate flow becomes one test, and the main flow of UC1 becomes the UI smoke test (T-026). If behavior changes, update this file in the same PR.

## Actors

| Actor | Kind | Role |
|---|---|---|
| Patient | Primary | Owns the archive. The only person who uses the app (one person per install, D-005) |
| iOS | Secondary (system) | Camera, Vision OCR, Photos, Files, Face ID, data protection |
| Doctor | Offstage | Never uses the app. Sees only the images the patient chooses to share |

## Use-case list

| ID | Use case | Milestone | Tasks | Today |
|---|---|---|---|---|
| UC1 | Add a record from a paper report or images | M0–M2 | T-002, T-013, T-022, T-038, T-039 | partial |
| UC2 | Add a record by hand | M1 | T-009 | partial: a failed save is invisible |
| UC3 | Find a record | — | T-018 | shipped |
| UC4 | View a record and its images | — | — | shipped |
| UC5 | Edit a record | M1–M2 | T-039, T-010 | missing |
| UC6 | Delete a record | M1 | T-008 | partial: no confirmation |
| UC7 | Back up the archive | M1 | T-014 | missing |
| UC8 | Restore the archive | M1 | T-014, Q-1, Q-2 | missing |
| UC9 | Share images with a doctor | M2 | T-023 | missing |
| UC10 | Lock the app | M3 | T-024 | missing |
| UC11 | First launch | M4 | T-031 | missing |

Only UC1, UC7 and UC8 are written out in full below. They're where a mistake loses or corrupts data. Write out any other use case when its task starts, if its flow isn't obvious.

---

## UC1 Add a record from a paper report or images

- **Goal:** turn a paper report into a searchable record without retyping it.
- **Preconditions:** the app is open (and unlocked, if the lock is on).

**Main flow**
1. The patient taps Add.
2. The patient chooses Scan.
3. The patient scans one or more pages.
4. The system keeps every page image unchanged and runs OCR on the device.
5. The system fills only fields still at their default value, and marks each one "from OCR" (D-014).
6. The patient reviews the fields, then corrects or confirms them.
7. The patient taps Save.
8. The system stores the record and its images, and shows it in the timeline.

**Alternate flows**
- **2a.** No camera, for example in the simulator: the patient picks Photos (or Files, after T-013) instead. The flow continues at step 4.
- **3a.** The patient cancels the scan. Nothing is added.
- **4a.** OCR finds no text. Nothing is filled, the images are kept, and the patient fills the fields by hand.
- **5a.** The patient already typed or picked a value. OCR leaves that field alone, and this includes the date and the category.
- **7a.** Saving fails. The system shows an error and keeps the form open with everything in it (T-009).
- **7b.** The patient cancels. Nothing is stored.

**Postconditions:** the record and the original images are on the device, and nothing left the device.

**Today:**
- Step 5 is broken for the date and the category. `apply()` replaces `occurredAt` whenever OCR finds a date, even one the patient picked (`NewHealthRecordView.swift:405`). `inferCategory` can't tell the default "visit" from a "visit" the patient chose (`:425`). → T-038
- Step 7a doesn't exist yet → T-009

---

## UC7 Back up the archive

- **Goal:** get a complete copy of the archive off the device, so losing the phone doesn't lose the records.
- **Preconditions:** at least one record exists.

**Main flow**
1. The patient opens Backup.
2. The system offers Encrypted (the default) or Plain (D-023).
3. The patient enters a password twice. The system warns that a lost password means a lost backup.
4. The patient picks where to save the backup, using the Files picker.
5. The system writes `manifest.json`, `records.json` and `assets/`, then checks every asset hash (D-022).
6. The system shows how many records were saved and the file size.

**Alternate flows**
- **2a.** The patient picks Plain. The system warns that anyone with the file can read it, then skips step 3.
- **4a.** The patient cancels. Nothing is written.
- **5a.** There isn't enough space, or the write fails. The system deletes the partial file and says why.
- **5b.** The device locks during export. With `NSFileProtectionComplete` (D-012), the store can't be read while the device is locked, so the export stops, the partial file is deleted, and the patient is asked to retry with the device unlocked.

**Postconditions:** the backup contains every record and attachment, and every hash matches. The file went only where the patient chose.

---

## UC8 Restore the archive

- **Goal:** bring records back from a backup, on a new device or after deleting the app.
- **Preconditions:** the patient has a backup file.

**Main flow**
1. The patient opens Restore and picks a backup file.
2. If the backup is encrypted, the patient enters its password.
3. The system reads the manifest, then checks the format version and every asset hash.
4. The system shows a summary: N records in the backup, of which M are new and K are already on the device.
5. The patient confirms.
6. The system adds the records by `recordID`, and shows the result.

**Alternate flows**
- **2a.** Wrong password. The system shows a clear error and changes nothing.
- **3a.** The backup's format is newer than this app understands. The system asks the patient to update Genki and changes nothing.
- **3b.** An asset is missing, or its hash doesn't match. → Q-2 (recommended: restore nothing, and name the affected records)
- **4a.** A record in the backup has the same `recordID` as one on the device but different content. → Q-1 (recommended: keep whichever has the newer `updatedAt`)

**Postconditions:**
- Every record from the backup is on the device.
- No record already on the device was deleted.
- Running the same restore again changes nothing (D-022).
