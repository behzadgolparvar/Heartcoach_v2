# Build Instructions — HeartCoach v5

**Branch:** `new_design_Sep_2026` · **Workspace root:** repo root.

## Prerequisites
- Xcode 26, iOS 17+ / watchOS 10+ SDKs; a paid Apple Developer account (TEAM `Z5F9A35728`).
- `xcodegen` installed (`brew install xcodegen`).
- `GoogleService-Info.plist` present at the app path (gitignored — never commit).

## Core package (SPM)
```
swift build --package-path HeartRateCoachCore
```
Note: the core's SwiftCheck test target does not compile under Xcode 26 (pre-existing); PBT lives in the app test target instead.

## Generate the Xcode project (after any file add/remove)
```
xcodegen generate
```
`.xcodeproj` is gitignored and must be regenerated. Phase 6 added `FirebaseStorage` to the iOS target in `project.yml`.

## Build the app (simulator)
```
xcodebuild build -project HeartCoach.xcodeproj -scheme HeartCoach \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Build + install on device (iPhone + Watch)
- Select the paired device; ensure Developer Mode is enabled on both iPhone and Watch.
- The Watch app is embedded in the iPhone app. If companion install stalls at 75%, install the Watch app directly:
  `xcrun devicectl device install app --device <watch-udid> <DerivedData>/.../HeartCoachWatch.app`
  (See the `wcsession-install-fix` note.)

## Config / capabilities
- `WKBackgroundModes: [workout-processing]` (Watch) — required for background HR.
- Local notifications (`UserNotifications`) — no entitlement needed; permission requested at runtime.
- Firebase Storage uses the existing `GoogleService-Info.plist`; **publish the Storage security rules** (see infrastructure-design) before relying on export.

## TestFlight
- Bump `CFBundleVersion` in `project.yml`; `xcodegen generate`; Archive → upload via Xcode Organizer or `xcodebuild -exportArchive`.
- Internal testers re-onboard once (Q8=B). Keep internal until the §J safety items (backlog A) are wired.
