# Handoff: Live Workout — Direction D "Broadcast + Trace"

## Overview
Redesign of the iPhone **live workout** screen (and mirrored Apple Watch view) for HeartCoach. Direction D = a sports-broadcast layout (scoreboard header, giant HR numeral, zone gauge with target bracket, lower-third coach caption) plus a **live HR trace panel** that shows the entire session's target-zone bands with the user's HR line drawn over them.

Target codebase: `Heartcoach_v2` (SwiftUI, iOS 17+, watchOS 10+). Coaching logic is unchanged — this is a presentation-layer change fed by existing `WorkoutViewModel` / `CoachingState`.

## About the Design Files
`HeartCoach Live Workout.dc.html` is a **design reference built in HTML** — an interactive prototype showing intended look and behavior, not production code. Recreate it in SwiftUI using the codebase's existing patterns (`WorkoutView`, `ButtonStyles`, view models). Open the HTML in a browser (keep `support.js` next to it); choose **D** in the top switcher, pick a program, press Start. The simulator panel (speed, skip phase, push HR, drop signal, spike) exercises every state. A/B/C are rejected alternatives — ignore them.

## Fidelity
**High-fidelity.** Colors, type, sizes, spacing and transitions are final. Recreate pixel-perfectly at 390×844 pt (iPhone 15/16) and let it flex vertically on other sizes (the hero HR block is the flexible region).

---

## Screen: Live Workout (running) — iPhone
Replaces `Views/Workout/WorkoutView.swift → runningContent` (and retires `ZoneRingView`).

Root: full-screen, background `#0A0A0B`, `VStack(spacing: 14)`, padding top 60 (below status bar), horizontal 18, bottom 30. Text white. All live numbers use **monospaced digits** (`.monospacedDigit()`).

Top → bottom:

### 1. Scoreboard header (height 44)
`HStack(spacing: 0)`:
- **Phase chip** — bg `#FF3B30`, padding h12, Barlow Condensed ExtraBold 20, tracking 0.05em, UPPERCASE, single line. Copy: `WARM UP` / `EXERCISE` / `RECOVERY` / `COOL DOWN`.
- **Elapsed clock** — bg `#1C1C1E`, padding h12, Barlow Condensed Bold 28, `m:ss`.
- `Spacer()`
- **Phase ends** (right-aligned VStack, spacing 2): label `PHASE ENDS` Barlow SemiBold 10, tracking 0.16em, `#8E8E93`; value Barlow Condensed Bold 26, `m:ss` remaining in current segment.
No corner radius (square broadcast slabs).

### 2. HR trace panel (new `HRTraceView`)
Container: bg `#111214`, corner radius 14, 1pt inner stroke `#1F2023`, padding top 10 / bottom 6, horizontal 0.
- **Chart area** 354×150 pt (full inner width). Y domain **95–195 bpm** (clamp), X domain **0 → total session seconds** (incl. 2 min cooldown).
  - For each program segment: a rect spanning its time range.
    - Zoned segment (warm-up, exercise): y from zone **min** to **max** bpm, fill = zone color, opacity **0.45** (future/current) or **0.22** (completed). Width = segment width − 0.6pt (hairline gap between blocks).
    - Recovery / cooldown: y 110–135 bpm, fill white @ **0.07**.
  - **Max line**: dashed (3,3) 1pt `#FF3B30` at HRmax (185 in demo = `profile.effectiveMaxHR`); label `MAX 185` right-aligned 6pt from right edge, 4pt above line, Barlow Condensed 9, `#FF453A`.
  - **HR line**: white, 1.6pt, round joins; one point every 5 s (matches hr_stream cadence).
  - **Now cursor**: vertical 1pt white @ 0.35 opacity, full height, at current time.
  - **Now dot**: r 4.5, fill = current-zone color, 2pt stroke `#08090A`.
  - Suggested: Swift Charts (`RectangleMark`, `LineMark`, `RuleMark`, `PointMark`) or a `Canvas`.
- **Caption row** (padding h12, top 6, bottom 2; single line): left = round label (ellipsizes), right = `{m:ss} TO GO` (total remaining). Barlow SemiBold 11, tracking 0.14em, `#8E8E93`.
  - Round label copy: `WARM-UP 1 / 2`, `ROUND 4 / 15` (HIIT), `CYCLE 2 / 5` (Continuous), `SEGMENT 7 / 15` (Fartlek), `RECOVERY 4 / 15`, `STRETCH 2 / 4`.

### 3. Sensor-dropout banner (conditional)
Full width, bg `#FFD60A`, text black Barlow Bold 13, padding 8×12, centered: `No heart-rate signal — safety checks paused. Check your Watch.` (maps to `workoutVM.sensorDropout`). While dropped: HR shows `--`, zone color `#636366`.

### 4. Hero (flexible, centered)
- **Zone tag row** (HStack spacing 8): chip bg = current-zone color, text black, Barlow Condensed ExtraBold 18, padding 5×8, `Z3`; then zone name in zone color, Barlow Condensed Bold 18, tracking 0.08em, uppercase (`AEROBIC`). Colors animate 0.4 s.
- **HR numeral**: Barlow Condensed ExtraBold **140**, line-height 0.86, tracking −0.02em, top margin 6.
- `BPM`: Barlow Condensed Bold 15, tracking 0.34em, `#8E8E93`.

### 5. Zone gauge (new `ZoneGaugeView`, replaces ZoneRingView)
- Track height 30, top margin 10, `HStack(spacing: 3)` of 6 blocks, widths proportional to bpm spans over domain **110–190**: [below-Z1 12, Z1 13, Z2 12, Z3 13, Z4 12, Z5 13].
- Block fill: current zone = full zone color, others = zone color mixed **32% into `#1C1C1E`** (dim). Label `Z1…Z5` Barlow Condensed ExtraBold 13, tracking 0.04em; ink black on active, `#8E8E93` otherwise. First block unlabeled.
- **Target bracket**: 2pt white outline, 3pt offset, around the target-zone block (none during recovery/cooldown).
- **Marker**: downward white triangle 14w×10h, its tip 13pt above the track top, x = clamp((HR − 110) / 80, 1%, 99%) of track width; animate x 0.5 s.
- **Caption row** (single line, gap 10): left `TARGET Z3 · 147–160` (zone tag tinted target color); right delta in status color — `IN ZONE` (green), `6 BELOW` (orange), `4 ABOVE` (blue), `WALK IT OUT` / `STRETCH` (gray). Barlow SemiBold 12, tracking 0.1em, `#8E8E93` base.

### 6. Coach lower-third (height 76, clipped)
Two layers:
- **Idle line** (always under): 1pt border `#2C2C2E`, padding h14, Barlow Condensed Bold 15, tracking 0.12em, `#A1A1A6`, single line. Copy priority: `NO SIGNAL — CHECK YOUR WATCH` → `GRACE PERIOD — SETTLE IN` → `STRETCH · CALF STRETCH` → `RECOVERY — WALK IT OUT` → `IN ZONE · STEADY FOR 0:24` → `6 BELOW TARGET`. Opacity → 0 while a message is showing (0.3 s).
- **Message banner**: slides in from the left (x −104% → 0) with 0.45 s `cubic-bezier(.2,.8,.2,1)`; stays **4.5 s** after each new `coachingMessage`, then slides out.
  - 10pt left bar in message-type color; body bg `#F2F2F0`, text black, padding h14.
  - Kicker: `COACH · {KICKER}` Barlow Bold 10.5, tracking 0.18em, `#636366`, uppercase.
  - Message: Barlow Condensed ExtraBold 26, line-height 1.02, uppercase, single line + tail truncation.

| Message type | Example copy | Bar color | Kicker | Watch haptic |
|---|---|---|---|---|
| speed up | Speed up | `#FF9F0A` | Below target | short |
| slow down | Slow down / Slow your walk | `#4DACF6` | Above target | long |
| good | Good job, keep going | `#56D57B` | In the zone | double tap |
| phase | Zone 3 — Aerobic. Moderate effort — change pace / Recovery — walk it out, keep walking | `#FF3B30` | New phase | tap |
| stretch | Stretch: Calf stretch | `#C7C7CC` | Cool down | tap |

### 7. Stats row
3 equal columns, 1pt top+bottom borders `#2C2C2E`, 1pt vertical dividers (cols 2–3 padded left 12), padding v8. Label Barlow SemiBold 10, tracking 0.16em, `#8E8E93` (`AVG`, `PEAK`, `IN TARGET`); value Barlow Condensed Bold 24. In-target = exercise-phase seconds in target zone ÷ exercise seconds.

### 8. Controls (height 56, HStack spacing 10)
- `PAUSE` — flex, bg `#1C1C1E`, Barlow Condensed ExtraBold 21, tracking 0.1em, square corners.
- `STOP` — width 120, transparent, 2pt inner stroke `#FF3B30`, text `#FF453A`, same type. Opens the stop-confirm sheet (replaces the toolbar ⚠ button; keep accessibility id `emergency-stop-button`).

---

## Overlays (shared, same visual language)
Black @ 0.88–0.9 scrims; headings Barlow Condensed ExtraBold uppercase; primary buttons 56h, radius 16, `#FF3B30`, Barlow Condensed ExtraBold 20 tracking 0.06em; secondary same with white @ 0.10.
- **Paused**: `PAUSED` 64pt centered; `{elapsed} in · {remaining} to go` Barlow 15 `#A1A1A6`; `Resume` / `End workout`.
- **Cooldown gate** (existing `awaitingCooldownStart`): kicker `TRAINING COMPLETE` Barlow Bold 12 tracking 0.2em `#30D158`; `GREAT WORK!` 56pt; body "Step off and get ready for a 2-minute stretch — it's part of the session and helps prevent injury."; `Begin stretches` / `Skip`.
- **Stop confirm** (bottom-aligned, padding 20/40): `STOP NOW?` 44pt; "Feeling unwell — dizzy, chest pain, short of breath? Stop and rest. Your session so far will be saved."; `Stop workout` / `Keep going`.
- **Safety stop** (HR > HRmax): full-screen bg `#C4140C`; kicker `SAFETY STOP`; HR 150pt; `BPM · ABOVE YOUR MAX OF 185`; spec copy "Your heart rate is above your estimated maximum. Stop exercising and check your condition." Barlow Medium 19; white button with red text `I've stopped · View summary`.
- **Startup**: spinner (44pt ring, 3pt, white@0.14 track, `#FF3B30` head, 0.9 s linear) + "Getting your heart rate…"; countdown numeral Barlow Condensed ExtraBold 220 + `GET READY` Barlow Bold 16 tracking 0.3em `#FF453A`.

## Apple Watch — Workout (replaces `WorkoutWatchView`)
198×242 pt screen, black, padding 18/16/16, VStack spacing 4:
- Row: phase chip (bg `#FF3B30`, Barlow Condensed ExtraBold 12, padding 3×5, uppercase) · spacer · phase remaining Barlow Condensed Bold 15.
- Center: HR Barlow Condensed ExtraBold 88, colored by current zone; below `Z3 · TARGET Z3` Barlow Condensed Bold 12 tracking 0.14em `#8E8E93`.
- Mini zone gauge: 8pt tall, same 6 blocks/dimming, 1.5pt white outline on target.
- Message line (34pt tall, centered, Barlow Condensed ExtraBold 15 uppercase) in message-type color while fresh; otherwise blank / "Settle in" during grace.
- Haptics per table above (existing `HapticService`).

---

## Interactions & Behavior
- Coaching rules unchanged (`CoachingEngine`): 10 s grace after each segment change (no correction cues; safety still active), evaluation every 10 s, 20 s anti-spam per message, "Good job" after 30 s continuous in-zone, recovery "Slow your walk" when HR ≥ Z4 min.
- Each new message → banner in, watch haptic, (voice via existing `VoiceFeedbackService`). Phase announcements bypass anti-spam.
- Zone color changes animate 0.4 s; gauge marker 0.5 s; banner 0.45 s ease-out.
- Phase ends / elapsed / to-go tick every second; HR trace appends every 5 s.

## State Needed (additions to WorkoutViewModel)
- `segments: [Segment]` — flattened program incl. cooldown (`phase`, `start`, `duration`, `targetZone?`, `index`, `ordinal`). Build from `WorkoutProgram`.
- `hrTrace: [(second: Int, hr: Int)]` — append every 5 s.
- `lastMessage: (text, type, timestamp)` — drive banner visibility (4.5 s).
- `inZoneSince: Int?` — for "steady for m:ss".
- `exerciseSeconds`, `inTargetSeconds`, `peakHR`, `avgHR` (may already exist in summary VM).

## Design Tokens
**Neutrals**: bg `#0A0A0B` · panel `#111214` · panel stroke `#1F2023` · surface `#1C1C1E` · divider `#2C2C2E` · secondary text `#8E8E93` · tertiary `#636366` · light text `#A1A1A6` · banner paper `#F2F2F0`.
**Brand**: red `#FF3B30` (= SwiftUI `.red`), red text `#FF453A`, safety bg `#C4140C`, success `#30D158`, warning `#FFD60A`.
**Zones (D)** — authored in OKLCH, sRGB hex:
- Below Z1 `#48484A`
- Z1 Recovery `#46A6EF` — oklch(0.70 0.14 245)
- Z2 Easy `#56D57B` — oklch(0.78 0.17 150)
- Z3 Aerobic `#F2D42D` — oklch(0.87 0.17 98)
- Z4 Threshold `#FF8B00` — oklch(0.75 0.18 58)
- Z5 Max `#F93534` — oklch(0.64 0.23 27)
- Dimmed block = zone color mixed 32% into `#1C1C1E` (e.g. Z1 → `#2C455A`).

**Type**: Barlow Condensed (600/700/800) for numerals, chips, headings, buttons; Barlow (400–700) for labels/body. Labels are uppercase with 0.1–0.18em tracking. Scale used: 10, 11, 12, 13, 15, 18, 20, 21, 24, 26, 28, 140 (iPhone HR), 88 (Watch HR), 220 (countdown).
**Radii**: 0 (broadcast slabs, buttons on running screen), 14 (trace panel), 16 (overlay buttons).
**Spacing**: screen padding 18; stack gap 14; panel inner 10/12.

## Assets
- Fonts: **Barlow** and **Barlow Condensed** (Google Fonts, OFL) — add .ttf files to both iPhone and Watch targets and register under `UIAppFonts`.
- No images or icons; triangle marker and status dots are simple shapes.

## Zone math (demo values)
Age 35, RHR 60 → HRmax 185, Karvonen bands: Z1 122–135, Z2 135–147, Z3 147–160, Z4 160–172, Z5 172–185. Use real `HRZones` from the profile.

## Files
- `HeartCoach Live Workout.dc.html` — interactive prototype (select **D**). Template markup = layout/styles; logic class at bottom = simulation, coaching, and all derived display values (`renderVals`, `graph()`).
- `support.js` — runtime required to open the prototype locally.
- Codebase files to change: `HeartCoach/Views/Workout/WorkoutView.swift`, `ZoneRingView.swift` (→ `ZoneGaugeView`), new `HRTraceView.swift`, `EmergencyStopOverlay.swift`, `ViewModels/WorkoutViewModel.swift`, `HeartCoachWatch/Views/WorkoutWatchView.swift`, `Info.plist` (fonts).
