# Requirements Clarification Questions — HeartRateCoach

I detected a contradiction in your responses that needs clarification before I can generate the requirements document.

---

## Contradiction: Offline Session Handling (Q7 vs PROJECT_BRIEF.md Section 13)

Your `PROJECT_BRIEF.md` Section 13 explicitly lists the following as **out of scope for v1**:

> *"Offline Firebase sync handling"*

However, your answer to **Question 7** was:

> **A) Yes — queue the session locally and sync to Firebase when connection is restored**

These two statements are directly contradictory. Implementing local offline queuing requires:
- A local persistence layer (e.g., Core Data or UserDefaults) to store sessions when offline
- A background sync mechanism to detect reconnection and flush queued sessions to Firebase
- Conflict resolution logic if the same session is partially written

This is meaningful extra scope for v1.

---

### Clarification Question 1
How should offline session handling work in v1?

A) Keep it out of scope as the brief states — if offline, show an error and do not save the session (simpler, matches brief)
B) Include offline queuing — override the brief, implement local storage + sync on reconnect (more robust, extra scope)
C) Other (please describe after [Answer]: tag below)

[Answer]: B - please edit the PROJECT_BRIEF.md file to resolve the contradiction

---

Please fill in your answer and let me know when done.
