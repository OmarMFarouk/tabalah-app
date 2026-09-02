# Tabalah App

The member-facing Flutter app for [أكاديمية تبالة الرياضية](https://tabalahacademy.com).

One binary serves three audiences, chosen by what the API says at sign-in:

| Portal | Who | What they get |
|---|---|---|
| **Player** | members | sports catalogue, memberships, enrolment & checkout, payments, attendance, session ratings, personal QR |
| **Trainer** | coaches | daily session board, rosters, QR attendance scanning, KPIs, salary |
| **Guardian** | parents | read-only view of their child's memberships, attendance and payments |

Arabic-first (RTL) with full English support.

Backend: [tabalah-backend](https://github.com/OmarMFarouk/tabalah-backend) ·
Admin panel: [tabalah-admin](https://github.com/OmarMFarouk/tabalah-admin)

---

## Getting started

```bash
flutter pub get
flutter run
```

The app points at production by default. Override the API without editing any file:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` is how the Android emulator reaches your host machine; a physical device
needs your machine's LAN IP.

### Release builds

```bash
flutter build apk --release --split-per-abi
```

> **Signing:** `android/app/build.gradle.kts` still signs release builds with the
> **debug** key from the Flutter scaffold. Those APKs install fine for testing but the
> Play Store will reject them — and once published under a real key, debug-signed
> installs cannot be upgraded over. Set up a keystore before any public release.

> **Stale builds:** if a change to `ApiConfig` does not appear in the binary, run
> `flutter clean` first. An incremental build has been observed reusing a cached Dart
> snapshot and shipping the previous API URL. Verify with:
> `strings lib/arm64-v8a/libapp.so | grep https` on the unzipped APK.

---

## Architecture

```
lib/
├── api/          Dio client, endpoints, typed exceptions, base URL config
├── cubits/       one cubit per screen or feature; auth/ holds the session machine
├── models/       API response models (hand-written fromJson, no codegen)
├── components/   shared widgets — cards, rails, scanner, empty/async states
├── views/        auth/ · player/ · trainer/ · guardian/
└── src/          theme, colours, localization, prefs, secure storage, scope
```

State management is **flutter_bloc** (cubits, not blocs). Networking is **dio**.
Tokens live in `flutter_secure_storage`.

### Navigation and the session

`AuthGate` sits at route 0 and renders the portal for the current session. Auth screens
are *pushed above it*. A single `BlocListener` in `main.dart` unwinds the stack whenever
a session starts or ends.

Two rules follow, and breaking either produces bugs that only a restart clears:

1. **No screen navigates on auth state itself.** Signing in from a screen's own listener
   made correct navigation depend on that screen surviving the transition. The root owns
   it, once, from outside anything that might be torn down.
2. **Every `AuthState` must be handled in `AuthGate`.** Its unauthenticated branch
   enumerates states explicitly; one that falls through drops to the splash screen,
   replacing what route 0 shows while pushed routes sit on top of it.

### AppScope

`AppScope` holds two process-wide facts the API layer needs but has no `BuildContext`
to look up: the request locale, and whether this session is a guardian. Endpoints swap
their `/player` prefix for `/guardian` off that flag, which is what lets every player
cubit, model and screen work unchanged for parents.

A guardian token authenticates *as* the player, so `user.isPlayer` is true for a parent
too — check `AppScope.isGuardian` **first** anywhere behaviour differs.

### QR attendance

The trainer scans the player's personal QR against a session. On the trainer's home
screen the session is inferred from the clock: whichever of the day's sessions the API
would currently accept attendance for, with a picker only when several overlap. The
client mirrors the server's grace window
(`TrainerDaySession.attendanceGraceMinutes`) so the UI never offers a scan the API
would reject.

The reverse flow — the player scanning a session code shown by the trainer —
is fully built (`ScanSessionQrView`, `/player/check-in`) but **not routed**: a code
visible to a whole class can be forwarded to an absent member, and members young enough
to need a guardian do not carry their own phone. Re-enable it by restoring the
commented-out entry points if you ever want self check-in.

### Localization

`easy_localization` with `assets/translation/{ar,en}.json`. Arabic is the primary
language; every user-facing string goes through `.tr()`.

---

## Conventions

- **Comments explain why, not what.** Several non-obvious decisions in this codebase are
  documented at the line that depends on them — read them before "simplifying" one.
- **Models are hand-written.** No build_runner, no codegen step.
- **`J.` helpers** (`lib/models/json_utils.dart`) coerce API values defensively; a null
  or a string where a number was expected should degrade, not crash.
