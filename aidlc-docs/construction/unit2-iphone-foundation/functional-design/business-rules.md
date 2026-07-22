# Business Rules — Unit 2: iPhone Foundation

---

## Authentication Rules

### BR-U2-01: Sign in with Apple Only
- **Rule**: The only authentication method is Sign in with Apple. No email/password, no Google, no anonymous auth.
- **Rationale**: Brief specification; Apple sign-in is required for apps that offer third-party sign-in on iOS.

### BR-U2-02: Auth State Persistence
- **Rule**: Firebase Auth persists the session across app restarts. The app must check auth state on every launch before showing any screen.
- **Rule**: If Firebase returns an authenticated user on launch, skip the sign-in screen entirely.

### BR-U2-03: Onboarding Gate
- **Rule**: A user who has signed in but has no Firestore profile document is considered "new" and must complete onboarding before accessing the main app.
- **Rule**: Returning users (profile exists in Firestore) go directly to the Home tab.

### BR-U2-04: Sign Out
- **Rule**: Signing out clears the Firebase Auth session and returns the app to `.signedOut` state.
- **Rule**: Local Core Data (offline queue) is NOT cleared on sign-out — it will be synced on next sign-in.

---

## Onboarding Rules

### BR-U2-05: Onboarding Cannot Be Skipped
- **Rule**: A user cannot access the main tab bar until all required onboarding fields (age, RHR, goal, preferred workout) are filled and the profile is saved to Firestore.

### BR-U2-06: Step 1 Validation is Blocking
- **Rule**: The user cannot advance past Step 1 until age and restingHR pass validation and `ZoneCalculator.calculate()` succeeds without throwing.
- **Rule**: If `ZoneCalculator` throws, the specific error is shown inline — the user must correct the value.

### BR-U2-07: Step 2 is Skippable
- **Rule**: Sex and weight are optional. The "Next" button on Step 2 advances without requiring any input.

### BR-U2-08: HealthKit Authorization is Requested Once
- **Rule**: HealthKit HR read authorization is requested on Step 1.
- **Rule**: If the user denies it during onboarding, the app continues to onboarding completion. A denial warning is shown on the Home screen and on workout start.
- **Rule**: The app must NOT re-request HealthKit permission after the system dialog is dismissed — it must direct the user to Settings if needed.

### BR-U2-09: Zone Preview Uses Step 1 Data
- **Rule**: The zones shown on Step 4 (Zone Preview) are computed from the age and RHR entered in Step 1. They are NOT recomputed from the Step 3 preferences.

### BR-U2-10: Profile is Saved Only at Step 4 Completion
- **Rule**: No Firestore write occurs during onboarding Steps 1–3. The single profile save happens only when the user taps "Start Training" on Step 4.

---

## Profile Update Rules

### BR-U2-11: Save is Explicit
- **Rule**: On the Settings screen, profile changes are NOT written to Firestore until the user taps "Save."
- **Rule**: Navigating away from Settings without saving discards all edits silently.

### BR-U2-12: Zone Preview in Settings is Live
- **Rule**: As the user types a valid age and RHR in Settings, a zone preview updates in real-time below the form (using `previewZones()` — local only, no Firestore write).
- **Rule**: Zone preview only renders when both age and RHR are currently valid inputs. Invalid inputs show no preview.

### BR-U2-13: Save Triggers Zone Recalculation
- **Rule**: When the user taps "Save" in Settings, zones are recalculated via `ZoneCalculator.calculate()` before the Firestore write.
- **Rule**: If `ZoneCalculator` throws (invalid input), the save is aborted and the specific error is shown inline.

---

## Navigation Rules

### BR-U2-14: Tab Bar Always Visible in Main App
- **Rule**: The three tabs (Home, History, Settings) are always visible once the user is in `.main` state.
- **Rule**: History tab content is a placeholder in Unit 2 — it shows "Coming soon" until Unit 3 is complete.

### BR-U2-15: Back Navigation in Onboarding
- **Rule**: Users can navigate back through onboarding steps without losing entered data.
- **Rule**: The back button is not shown on Step 4 (Zone Preview) — the user must tap "Start Training" or use the iOS back gesture.

---

## Home Screen Rules

### BR-U2-16: Home Content Priority
- **Rule**: If `lastSession != nil` → show LastSessionCard. Else → show ZoneCard.
- **Rule**: The Start Workout button is always visible on the Home screen regardless of session history.

### BR-U2-17: History Tab Placeholder
- **Rule**: Unit 2 renders a placeholder view in the History tab. Full implementation is delivered in Unit 3.

---

## Decision Log

| Decision | Answer | Rationale |
|---|---|---|
| Onboarding flow | Multi-step wizard (Q1 — B) | Health data deserves focused per-step context; zone preview as step 4 creates "aha moment" |
| Navigation | Tab bar (Q2 — A) | History is frequently accessed post-workout; one tap from anywhere |
| HealthKit timing | During onboarding (Q3 — A) | Contextual — user is already thinking about HR; no mid-workout interruption |
| Profile save | Explicit Save button (Q4 — A) | Avoids keystroke writes; zone recalculation should be intentional |
| Home empty state | Zone summary card (Q5 — B) | Reinforces onboarding value; feels personalised from day one |
