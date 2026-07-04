# ARCHITECTURE.md — Smart University (Flutter Client)

**Document type:** Frontend architecture & folder-layout reference
**Project:** Smart University Management Platform (Smart Campus) — Flutter client
**Stack:** Flutter · Dart · `http` · `flutter_secure_storage`
**Talks to:** ASP.NET Core Web API (`/api/auth/...`) — see `ROADMAP_PROJECT.md` and `Smart_University_Handover_EN.md` for the backend.
**Status at this revision:** Module 1.5 — "Login screen & secure token storage" implemented AND the launch-flow UI (splash → role selection → login) added on top of it. Two backend-touching features remain in Module 1.5 (auth interceptor + post-login role picker/routing).

> This is a continuation snapshot for the **Flutter half** of the project, mirroring how `SmartUniversity_Session_Context_Phase1.md` documents the backend. It is written to be picked up cold: a new session or developer (human or AI) should be able to build the next screen from this file alone, without re-deriving conventions or asking what already exists.

It complements, does not replace:
- `Smart_University_Handover_EN.md` — *why* design decisions were made (auth flow, JWT strategy, multi-role rule).
- `ROADMAP_PROJECT.md` — the full task tree; Module 1.5 is the Flutter auth UX.
- `SmartUniversity_Session_Context_Phase1.md` (Updates 1–4) — backend implementation state and the API contract.

---

## Current Folder Layout

```
lib/
├── main.dart                          (app entry — runApp + MaterialApp; home: SplashScreen)
├── core/
│   ├── theme.dart                     (design tokens: AppColors, AppSpacing, AppRadius, AppTheme, Palette ext)
│   ├── api_config.dart                (base URL, endpoints, timeout)
│   ├── _platform_io.dart              (host resolver — native: Android/iOS/desktop)
│   └── _platform_web.dart             (host resolver — web stub, no dart:io)
├── data/
│   ├── models/
│   │   └── login_response.dart        (LoginResponse DTO ← maps server JSON)
│   └── services/
│       ├── auth_service.dart          (calls POST /api/auth/login, maps errors)
│       └── token_storage.dart         (flutter_secure_storage wrapper)
└── features/
    └── auth/
        ├── models/
        │   └── app_role.dart          (AppRole — UI-only role descriptor; shared by screens)
        └── screens/
            ├── splash_screen.dart     (brand splash; auto-advances after 2s)
            ├── role_selection_screen.dart  (Student/Lecturer cards + discreet staff access)
            └── login_screen.dart      (functional login UI, wired to AuthService)
```

**Changed since the previous revision of this doc:** added `features/auth/models/app_role.dart`, `features/auth/screens/splash_screen.dart`, and `features/auth/screens/role_selection_screen.dart`; `main.dart` now starts at `SplashScreen` instead of `LoginScreen`; `login_screen.dart` gained an optional `selectedRole` parameter and a `_RoleHint` widget.

---

## The Launch Flow (read this first if you're building UI)

The app no longer opens directly on login. The entry sequence is three screens:

```
SplashScreen ──(auto, 2s)──▶ RoleSelectionScreen ──(tap a role)──▶ LoginScreen
     │                              │                                    │
  brand only                 5 roles, 2 primary               selectedRole shown as a
  logo + name                + 3 behind "Staff access"        dismissable hint; login
  + tagline                  toggle                            works identically for all roles
```

Navigation mechanics, exactly as implemented:

- **Splash → Role Selection:** `pushReplacement` (splash is gone from the stack; back gesture won't return to it). Fires after a 2-second hold in `initState`.
- **Role Selection → Login:** `push` (NOT replacement). This is deliberate — it keeps role selection on the stack so the "· Change" affordance on the login screen can `maybePop()` back to re-pick a role without restarting the app.
- **Transitions:** a shared `_fade(...)` `PageRouteBuilder` defined at the bottom of `splash_screen.dart` and `role_selection_screen.dart`. The role-selection copy is a **slide-up + fade** (login slides up 6% of height, `easeOutCubic`, 340ms forward / 260ms reverse). The splash copy is a plain fade. They are independent copies; editing one does not change the other.

### The `selectedRole` contract (important, security-relevant)

`RoleSelectionScreen` passes the tapped `AppRole` into `LoginScreen(selectedRole: ...)`. This is **UX-only navigation state** — it exists so the login screen can show "Signing in as Student". It is:
- **never** sent to `AuthService.login()` or any API call,
- **never** used for authorization,
- purely a display hint + a back-navigation anchor.

The JWT's real roles (returned by the backend) are the only thing that decides what a signed-in user can do. Tapping "Administrator" on the role screen grants nothing unless the account actually carries that role. This mirrors handover §6.7 and the same rule already documented for the post-login role picker.

`LoginScreen`'s `selectedRole` is **optional and nullable** (`AppRole?`). When null (e.g. if some future flow opens login directly), the hint simply isn't rendered and login behaves normally. Don't make it required.

---

## The `AppRole` Model

`lib/features/auth/models/app_role.dart` — a small immutable descriptor used only by the UI:

```dart
class AppRole {
  const AppRole({required this.id, required this.label, required this.blurb, required this.icon});
  final String id;        // matches the seeded Roles table Name column EXACTLY
  final String label;     // human label shown on the card ("Department Staff")
  final String blurb;     // one-line description under the label
  final IconData icon;    // Material icon for the card
}
```

**Why it's in its own file (not inside a screen):** it was originally declared inside `role_selection_screen.dart`, which then created a **circular import** once `login_screen.dart` needed the type too (`role_selection` imports `login`, `login` imports `role_selection`). The analyzer resolved the cycle inconsistently and produced a spurious "The argument type 'AppRole' can't be assigned to the parameter type 'AppRole?'" error that survived hot reloads. Extracting `AppRole` to `models/app_role.dart` — which both screens import, and which imports neither — broke the cycle. **Keep shared types out of screen files for this reason.**

The five `AppRole` instances live as `const` lists at the top of `role_selection_screen.dart`: `_primaryRoles` (Student, Lecturer) and `_staffRoles` (DepartmentStaff, AcademicOffice, Admin). The `id` values are the canonical role names and must stay byte-identical to the backend's seeded `Roles.Name` values.

---

## What Each Layer Is For

The client uses a **layered structure** that deliberately mirrors the backend's `Controller → Service → DbContext` split, so both halves of the project feel consistent.

### `core/` — cross-cutting foundation
No feature logic. Theming, configuration, platform helpers. Backend counterpart: `Application/Common`.

- **`theme.dart`** — the entire design-token system: `AppColors` (palette), `AppSpacing` (xs→xxl), `AppRadius` (sm→xl), `AppTheme` (light/dark `ThemeData`), and the `Palette` extension on `BuildContext` (`context.canvas`, `context.panel`, `context.border`, `context.text`, `context.muted`, `context.faint`, `context.accentSoft`, `context.isDark`). Every screen reads colors and text styles from here; no hard-coded colors in feature code. The single accent is indigo `AppColors.accent` (`#5B5BD6`).
- **`api_config.dart`** — single source of truth for where the backend lives: base URL, the auth endpoint `Uri`s, request timeout. **Tune `_scheme` and `_port` here** to match how you launch `dotnet run` (read the "Now listening on" line in its console).
- **`_platform_io.dart` / `_platform_web.dart`** — conditional-import pair resolving the API host per platform. Underscore = internal; only `api_config.dart` references them. See "Host resolution" below.

### `data/` — the data layer
Backend counterpart: `Application/Common/Dtos` (models) + `Infrastructure/Security` (services).

- **`models/login_response.dart`** — the `LoginResponse` DTO (`accessToken`, `refreshToken`, `roles[]`, `requiresRoleSelection`). JSON mapping only, no logic.
- **`services/auth_service.dart`** — counterpart to the backend's `AuthService.cs`. Owns the login HTTP call, parses the response, persists tokens on success, maps every status code to a friendly message. Has a `dispose()`; screens that construct their own `AuthService` must dispose it (login screen does this — only when it created the service itself, not when one was injected for testing).
- **`services/token_storage.dart`** — wraps `flutter_secure_storage`. The ONLY place tokens are read/written. Surface: `saveTokens` / `readAccessToken` / `readRefreshToken` / `hasSession` / `clear`.

### `features/` — feature-grouped UI
Backend counterpart: `Application/Features/{FeatureName}`. Each feature owns its `models/` (UI descriptors) and `screens/` (and later its own widgets/controllers).

- **`auth/models/app_role.dart`** — see "The `AppRole` Model" above.
- **`auth/screens/splash_screen.dart`** — `StatefulWidget`. Logo + "Smart University" + tagline on `context.canvas`. Fades/scales in over ~720ms (respects `MediaQuery.disableAnimations` — when reduced motion is on, the brand just appears). Holds 2s, then `pushReplacement` to role selection. Has its own private `_Logo` (size 64) and `_fade` route builder.
- **`auth/screens/role_selection_screen.dart`** — `StatefulWidget`. Two big `_RoleCard`s for Student/Lecturer, then a discreet `_StaffToggle` (key icon + "Staff access" label) that expands via `AnimatedCrossFade` to reveal three compact `_RoleCard`s for the staff roles. Tapping any card `push`es `LoginScreen(selectedRole: role)`. Owns private widgets `_RoleCard`, `_StaffToggle`, `_Logo`, and the slide-up `_fade` builder.
- **`auth/screens/login_screen.dart`** — the functional login screen: controllers on both fields, loading state, inline error banner, real `AuthService.login()` call. Optional `selectedRole` renders a `_RoleHint` ("Signing in as X · Change") above the card; tapping it `maybePop()`s back to role selection. On success it currently routes to a temporary `_PostLoginPlaceholder` — that placeholder is what the upcoming "Role picker & routing" feature replaces.

---

## Backend ↔ Flutter Correspondence

| Concern | Backend (C# / ASP.NET Core) | Flutter (Dart) |
|---|---|---|
| Shared foundation | `Application/Common` | `lib/core/` |
| DTOs | `Application/Common/Dtos`, `Features/{X}/Dtos` | `lib/data/models/`, `lib/features/{x}/models/` |
| Service logic | `Infrastructure/Security/AuthService.cs` | `lib/data/services/auth_service.dart` |
| Feature grouping | `Application/Features/{FeatureName}` | `lib/features/{feature}/` |
| Entry / wiring | `Program.cs` | `lib/main.dart` |

**Canonical client data flow:**
`User → Screen → Service (auth_service) → secure storage / HTTP → API`

---

## Conventions (keep these as the client grows)

- **`package:` imports, not relative.** Every file imports via `package:smart_university_management_platform/...` (e.g. `package:smart_university_management_platform/core/theme.dart`). This is what the codebase actually uses and what the IDE auto-generates. *(Note: an earlier draft of this doc claimed relative imports were the convention — that was inaccurate; the code is and has been `package:`. If you ever see a relative import, normalize it to `package:`.)*
- **Shared types get their own file.** Anything imported by more than one screen (like `AppRole`) lives in a `models/` file, never inside a screen — see the circular-import story above. This is a hard rule, not a preference.
- **Tokens live in exactly one place.** Only `token_storage.dart` touches `flutter_secure_storage`.
- **No hard-coded colors or sizes.** Everything visual comes from `theme.dart` via the `Palette` extension or `Theme.of(context).textTheme`. New screens reuse `AppSpacing`/`AppRadius` constants, not magic numbers.
- **Selected role is UX-only.** (Repeated because it matters.) Never send a UI-picked role to the API for authorization.
- **Underscore-prefixed top-level files/widgets are internal.** `_platform_io.dart`/`_platform_web.dart` are private to `api_config.dart`. Private widget classes (`_RoleCard`, `_Logo`, etc.) stay in the file that uses them; if two screens need the same widget, promote it to a shared file first.
- **Errors are enumeration-resistant.** 400/401 both render one generic "invalid credentials" message, no hint about which field was wrong (mirrors handover §6.6).
- **Each screen carries its own `_fade`/`_Logo` copies today.** That's acceptable duplication for now. If a third screen needs the same transition, that's the trigger to extract a shared `core/transitions.dart` and `core/widgets/brand_logo.dart` — don't pre-extract before the third use.

---

## How To Add A New Screen (recipe for the next AI/dev)

1. Put it under `lib/features/{feature}/screens/{name}_screen.dart`. Reuse `auth/` only if it's genuinely auth; otherwise make a new feature folder.
2. Import `package:smart_university_management_platform/core/theme.dart` and pull all colors/spacing/text from it. Background is usually `context.panel` (role/login) or `context.canvas` (splash).
3. If it needs a type already used elsewhere, import it from that type's `models/` file — do not redeclare it.
4. To navigate to it, follow the `push` vs `pushReplacement` logic above: `push` when the user should be able to go back, `pushReplacement` when the previous screen should be gone (splash, post-login landing).
5. Match the existing visual language: a centered `ConstrainedBox(maxWidth: 400)` column, the gradient `_Logo` brand lockup at top, `AppRadius.lg`/`xl` cards with a 1px `context.border` and a soft shadow only in light mode.
6. Verify with `flutter analyze` (clean) before claiming it works, then run it — see the verification rule below.

---

## Host Resolution (the emulator gotcha)

Reaching a `localhost` backend depends on where the client runs:

- **Android emulator** → `10.0.2.2` is the host's loopback (`localhost` inside the emulator = the emulator itself).
- **iOS simulator / desktop / web** → `localhost` reaches the host directly.
- **Physical device** → use the dev machine's LAN IP (e.g. `192.168.1.20`); both on the same network.

Handled by the conditional-import pair: `api_config.dart` imports `_platform_io.dart` by default, swaps to `_platform_web.dart` on web (no `dart:io`). Host logic lives in those two; scheme and port live in `api_config.dart`.

---

## Dependencies

In `pubspec.yaml` under `dependencies:`, then `flutter pub get`:

```yaml
http: ^1.2.2                     # API calls
flutter_secure_storage: ^9.2.2  # Keychain / EncryptedSharedPreferences
```

Platform setup:
- **Android** — `minSdkVersion >= 18` (EncryptedSharedPreferences).
- **iOS** — works out of the box.
- **macOS desktop** — enable Keychain Sharing capability in Xcode, or secure-storage silently fails.
- **Web** — experimental WebCrypto-backed store; fine for dev.

---

## How This Maps To The Roadmap

This document covers **Module 1.5 → "Login screen & secure token storage"** plus the **launch-flow UI** (splash + role selection) layered on it. The layout absorbs the remaining two features without restructuring:

```
lib/
├── data/services/
│   └── auth_interceptor.dart          ← NEXT: "Auth interceptor & token refresh"
└── features/auth/screens/
    └── role_picker_screen.dart        ← NEXT: "Role picker & routing"
```

- **Auth interceptor & token refresh** — new service in `data/services/`: attaches the access token to every request; on 401 calls `/refresh`, retries, and on hard failure clears tokens (via `token_storage.dart`) and routes to login. Note the distinction from the launch-flow role selection: that is a *pre-login* convenience screen; the **role picker** below is a *post-login* screen driven by the JWT's real roles.
- **Role picker & routing** — new screen replacing the login screen's temporary `_PostLoginPlaceholder`: single-role users route straight to their workspace; multi-role users (`requiresRoleSelection == true`, e.g. `manager01`) see the picker.

---

## Verification Reminder (same discipline as the backend docs)

A roadmap checkbox is only `[x]` once there's **real evidence** — an actual HTTP response or observed app behavior, not just "it compiles." For the auth UI that means running against the live backend and confirming:

1. `student01` / `Test@123` (single role) → logs in, lands on the post-login screen showing the single-role path.
2. `manager01` / `Test@123` (multi-role) → logs in, `requiresRoleSelection` is true.
3. Wrong password → inline red error banner with the generic message.
4. After success, tokens are actually present in secure storage.

For the launch-flow UI specifically, also confirm: splash auto-advances after ~2s; the "Staff access" toggle reveals the three staff roles; tapping any role opens login with the correct "Signing in as X" hint; "· Change" returns to role selection. These are observable-behavior checks (no backend needed) but still must be *seen*, not assumed.

Until run, treat any feature as **written but unverified**.

---

*End of ARCHITECTURE.md — pair with `Smart_University_Handover_EN.md`, `ROADMAP_PROJECT.md`, and the Phase 1 session-context files for complete project understanding.*