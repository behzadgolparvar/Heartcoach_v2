# Build Instructions

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| macOS | 14.0+ (Sonoma) | Required for Xcode 15 |
| Xcode | 15.4+ | Set in `project.yml` `xcodeVersion` |
| XcodeGen | 2.40+ | Generates `.xcodeproj` from `project.yml` |
| Apple Developer Account | Any (free or paid) | Required for device signing |
| Swift | 5.9 | Bundled with Xcode 15 |

---

## Step 1: Install XcodeGen

XcodeGen converts `project.yml` into the Xcode project. It must be run before opening the project in Xcode.

```bash
# Install via Homebrew (one-time)
brew install xcodegen
```

---

## Step 2: Configure Firebase

> **SECURITY**: `GoogleService-Info.plist` must NEVER be committed to git (see `.gitignore`).

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Open your `HeartCoach` project (or create one)
3. Download `GoogleService-Info.plist` for the iOS app
4. Place it at: `HeartCoach/GoogleService-Info.plist`

Verify the file is gitignored:
```bash
git check-ignore -v HeartCoach/GoogleService-Info.plist
# Expected: .gitignore:X:GoogleService-Info.plist  HeartCoach/GoogleService-Info.plist
```

---

## Step 3: Configure Apple Developer Team

Edit `project.yml` and set your Apple Developer Team ID in all three `DEVELOPMENT_TEAM` fields:

```yaml
# HeartCoach target
DEVELOPMENT_TEAM: "XXXXXXXXXX"   # ← your 10-character Team ID

# HeartCoachWatch target
DEVELOPMENT_TEAM: "XXXXXXXXXX"

# HeartCoachWatchTests target
# (inherits from parent)
```

Find your Team ID at [developer.apple.com/account](https://developer.apple.com/account) → Membership.

---

## Step 4: Generate Xcode Project

```bash
cd /path/to/Heartcoach_v2
xcodegen generate
```

**Expected output:**
```
⚙️  Resolving packages...
✅  Generated: HeartCoach.xcodeproj
```

This generates `HeartCoach.xcodeproj`. Open it in Xcode (do not commit `.xcodeproj` — regenerate as needed from `project.yml`).

---

## Step 5: Resolve Swift Package Manager Dependencies

XcodeGen will prompt SPM resolution on first open. Alternatively, run:

```bash
xcodebuild -resolvePackageDependencies \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoach
```

SPM packages resolved:
- `firebase-ios-sdk` → FirebaseAuth, FirebaseFirestore
- `HeartRateCoachCore` (local path `./HeartRateCoachCore`) → HeartRateCoachCore, SwiftCheck (test only)

---

## Step 6: Build All Targets

### Build HeartRateCoachCore (SPM package)

```bash
swift build \
    --package-path HeartRateCoachCore \
    -c release
```

**Expected output:** `Build complete!`

### Build HeartCoach (iPhone app)

```bash
xcodebuild build \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoach \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -configuration Debug \
    | xcpretty
```

### Build HeartCoachWatch (Watch app)

```bash
xcodebuild build \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoachWatch \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
    -configuration Debug \
    | xcpretty
```

---

## Step 7: Verify Build Success

**Expected:** Zero errors, zero warnings (warnings from Firebase/third-party are acceptable).

**Build artifacts (Debug):**
- `~/Library/Developer/Xcode/DerivedData/HeartCoach-*/Build/Products/Debug-iphonesimulator/HeartCoach.app`
- `~/Library/Developer/Xcode/DerivedData/HeartCoach-*/Build/Products/Debug-watchossimulator/HeartCoachWatch.app`

---

## Troubleshooting

### `xcodegen: command not found`
```bash
brew install xcodegen
# or update: brew upgrade xcodegen
```

### `Missing package product 'HeartRateCoachCore'`
The local SPM package path in `project.yml` must match the directory name exactly.
```bash
ls HeartRateCoachCore/Package.swift   # verify this exists
```

### `GoogleService-Info.plist not found` (build error)
Place the file at `HeartCoach/GoogleService-Info.plist` (see Step 2).

### `Signing requires a development team`
Set `DEVELOPMENT_TEAM` in `project.yml` (see Step 3), then re-run `xcodegen generate`.

### `Module 'SwiftCheck' not found` (test build only)
SwiftCheck is declared in `HeartRateCoachCore/Package.swift` as a test dependency. Run `swift package resolve` inside `HeartRateCoachCore/` to fetch it.
```bash
cd HeartRateCoachCore && swift package resolve
```
