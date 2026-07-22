# NFR Design Plan — Unit 2: iPhone Foundation

## Execution Checklist

- [x] Step 1: Analyze NFR requirements
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities
- [x] Step 6: Generate NFR design artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit2-iphone-foundation/nfr-design/nfr-design-patterns.md`
- [x] `aidlc-docs/construction/unit2-iphone-foundation/nfr-design/logical-components.md`

---

## Context Summary

Most NFR design patterns for Unit 2 flow directly from decisions already made:
- Protocol-backed services → Repository pattern ✓ (decided in INCEPTION)
- Firestore offline cache → built-in `PersistentCacheSettings` ✓
- Sign in with Apple nonce → standard cryptographic nonce (required by Apple/Firebase) ✓
- Firebase error mapping → generic user-facing messages ✓ (SECURITY-15)
- NWPathMonitor → singleton in `AppContainer` ✓

One genuine design decision remains: how the offline session queue stores `Session` structs in Core Data.

---

## NFR Design Question

Please fill in the letter after the `[Answer]:` tag.

---

### Question 1
How should `Session` data be stored in the Core Data offline queue?

A) **JSON blob** — serialize the entire `Session` struct to JSON (`JSONEncoder`) and store it as a `Binary Data` attribute in one Core Data entity (`PendingSession`). Simple schema, easy to evolve.
B) **Mapped entity fields** — create a full Core Data entity (`PendingSessionEntity`) with individual attributes matching every `Session` property (date, durationSec, avgHR, etc.) and a relationship for HR records. More queryable but significantly more schema work.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in your answer and let me know when you're done.
