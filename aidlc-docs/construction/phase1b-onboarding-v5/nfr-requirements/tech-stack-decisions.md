# Phase 1b — Tech Stack Decisions (Onboarding v5 deltas)

**No new technology decisions.** P1b reuses the stack fixed in Phase 1 / v2 Requirements:

| Concern | Decision | Status |
|---|---|---|
| Language/UI | Swift / SwiftUI (`@Observable` @MainActor view models) | Reused |
| Pure domain logic | `HeartRateCoachCore` SPM package | Reused — new types (`TrainingHistory`, `TrainingStage`, `StageProgress`, `ProgramState`, `ExperienceResolver`) land here |
| Persistence | Firebase Firestore, `users/{uid}.v2profile` Codable map | Reused — new fields added to the same document |
| Auth | Firebase Auth (email/pw) | Reused |
| Testing | App test target (XCTest) + PBT where pure; core SwiftCheck target excluded (Xcode 26 breakage, Phase 1 note) | Reused |
| Project gen | xcodegen (`xcodegen generate` after adding files) | Reused |

## Placement rules for new code (P1b)
- Pure models + `ExperienceResolver` → `HeartRateCoachCore/Sources/HeartRateCoachCore/Models/` and `.../Engine/` (testable, no Firebase).
- Persistence encode/decode of new fields → app `FirestoreService` (`saveProfileV2`/`loadProfileV2`), tolerant decode so pre-v5 docs decode as `isV5Complete == false`.
- Onboarding UI (Q1/Q2 rework, Ozempic popup) → app `Views/Onboarding/`.
- Routing change (v5-complete gate) → `AuthViewModel`.

No infrastructure changes → Infrastructure Design will be **SKIPPED** for P1b (consistent with Phase 1).
