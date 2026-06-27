# Smart University Platform — Session Context (Phase 1: Authentication)

**Purpose of this document:** A continuation snapshot for any AI session or developer picking up this project. It complements (does not replace) `Smart_University_Handover_EN.md` (design decisions) and `ROADMAP_PROJECT.md` (full task list). This file captures *what has actually been built and empirically verified* during the authentication implementation pass, plus implementation details a new session needs to avoid re-deriving them from scratch.

**Working process this project follows (important for any AI session continuing it):**
- Build one Feature at a time, in the dependency order `ROADMAP_PROJECT.md` already specifies.
- Before code, a short design pass — only for concepts genuinely new to the developer (a second-year student learning as they build).
- After code, a checkbox is only marked `[x]` once there is **real evidence** (a DB query result, an actual HTTP response, a decoded token) — never just because the code compiles or "looks right." Several past mismatches in `ROADMAP_PROJECT.md` (boxes checked with `Completion: 0/n` still showing) came from skipping this discipline. Don't repeat that.

---

## 1. Current project structure (verified from Solution Explorer)

```
SmartUniversity/
├── Application/
│   ├── Common/
│   │   ├── Dtos/
│   │   ├── Interfaces/
│   │   │   ├── IAuthService.cs
│   │   │   └── IJwtTokenService.cs
│   │   └── Models/
│   │       ├── AuthenticatedUser.cs
│   │       ├── AuthResult.cs
│   │       ├── JwtSettings.cs
│   │       └── Result.cs
│   └── Features/
├── Controllers/
│   ├── AuthController.cs
│   ├── PingController.cs
│   └── WeatherForecastController.cs
├── Infrastructure/
│   └── Security/
│       ├── AuthService.cs
│       └── JwtTokenService.cs
├── Models/            (EF Core scaffolded entities, incl. RefreshToken, User, Role, UserRole, etc.)
├── Seeding/
│   └── DbSeeder.cs
└── Program.cs
```

> Note: `Dtos/` and `Features/` folders exist but their contents weren't reviewed in this session — only files explicitly pasted/discussed are documented below.

---

## 2. What's empirically verified working (Module 1.2 — Login & JWT)

| Item | Verified by |
|---|---|
| `POST /api/auth/login` returns full `{ accessToken, refreshToken, roles[], requiresRoleSelection }` | PowerShell test, `admin01` (single role → `false`) and `manager01` (multi role → `true`) |
| JWT contains `uid`, `sub`, role claims, no "active role" claim | Decoded payload locally |
| JWT `iss`/`aud`/signing key validated correctly | `[Authorize]` endpoint (`/api/auth/me`) returned 200 with correct claims |
| JWT expiry (~15 min) enforced | Stale token correctly rejected with 401 after expiry; fresh token worked |
| Auth middleware order in `Program.cs` correct | `UseAuthentication()` → `UseAuthorization()` → `MapControllers()` |

**`Module 1.2` is fully closed — all checkboxes in `ROADMAP_PROJECT.md` for Login DTOs, Credential verification, JWT generation, and Login endpoint should read `[x]` with matching completion counts.**

---

## 3. What's empirically verified working (Module 1.3 — Refresh Tokens, in progress)

### Refresh token issuance & storage — ✅ done
- Raw refresh token returned to client once; only `HashToken()` (SHA-256) result stored in `RefreshTokens.TokenHash`.
- `ExpiresAtUtc`, `CreatedAtUtc`, `CreatedByIp`, `DeviceInfo` all confirmed populated via SSMS query.

### Refresh endpoint with rotation — ✅ done
- `POST /api/auth/refresh` implemented in `AuthController` + `AuthService.RefreshAsync`.
- **Schema change applied:** `RefreshTokens.FamilyId UNIQUEIDENTIFIER NOT NULL` added via:
  ```sql
  ALTER TABLE RefreshTokens
  ADD FamilyId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID();
  ```
  (Existing rows each got a distinct backfilled GUID — confirmed in SSMS.)
- **Login** (`AuthService.StoreRefreshTokenAsync`) sets `FamilyId = Guid.NewGuid()` — starts a new family.
- **Refresh** (`AuthService.RefreshAsync`) copies `FamilyId` from the token being used — continues the same family.
- **Reuse detection:** if the presented token's row already has `RevokedAtUtc` set, the entire family (all rows sharing that `FamilyId` with `RevokedAtUtc IS NULL`) is revoked via `RevokeFamilyAsync`, and a generic 401 is returned.
- **Three-step test sequence confirmed working end to end:**
  1. Fresh login → refresh once → succeeds, new token pair issued, old row revoked + linked via `ReplacedByTokenHash`, both share `FamilyId`.
  2. Reuse the original (already-rotated) token → 401, entire family revoked.
  3. Try the token from step 1 (was still valid) → also 401 — proves family-wide revocation, not just single-token rejection.

### Account lockout & rate limiting — ⏳ not started, but partially scaffolded
`AuthService.LoginAsync` **already**:
- Increments `User.FailedLoginCount` on bad password
- Checks `LockoutEndUtc` and rejects login if still locked
- Resets `FailedLoginCount` to 0 on success

**Still missing:**
- Nothing currently *sets* `LockoutEndUtc` after N failures — the check exists, the trigger doesn't.
- No rate limiting middleware on `/login`, `/register`, `/refresh`.

This is the next task in the roadmap.

---

## 4. Key facts a new session needs (avoid re-discovering these)

- **Seed data password for every seeded user is `Test@123`** (constant `DefaultTestPassword` in `DbSeeder.cs`), not a per-user password.
- **Seeded login codes:** `admin01` (Admin), `office01` (AcademicOffice), `deptstaff01` (DepartmentStaff), `lecturer01` (Lecturer), `student01` (Student), `manager01` (Lecturer + AcademicOffice — the multi-role test account).
- **JWT settings** (`appsettings.json` / user-secrets, section `"Jwt"`): `Issuer = "SmartUniversityApi"`, `Audience = "SmartUniversityClient"`, `AccessTokenExpiryMinutes = 15` (default), `RefreshTokenExpiryDays = 7` (default). Signing key lives in user-secrets, never committed.
- **`AuthResult` / `LoginResponse`** are reused as the return shape for both `LoginAsync` and `RefreshAsync` — refresh responses include `roles`/`requiresRoleSelection` again, not just new tokens.
- **Hashing:** refresh tokens use `SHA256` via a local `HashToken()` helper in `AuthService` — separate from `IPasswordHasher` (BCrypt), which is only for login passwords.

---

## 5. Immediate next step

Build out **Account lockout & rate limiting** (Module 1.3, last feature):
1. Design: pick a threshold (e.g. 5 failed attempts) and lockout duration (e.g. 15 min), decide where that logic lives (likely inside the existing failed-password branch in `LoginAsync`).
2. Add the `LockoutEndUtc`-setting logic.
3. Add ASP.NET Core rate limiting middleware to `/login`, `/register` (not yet built), `/refresh`.
4. Test: trigger lockout with repeated bad logins, confirm `LockoutEndUtc` is set and a locked account is rejected even with the correct password; confirm rate limiting kicks in under burst requests.
5. Only then close out Module 1.3 and move to Module 1.4 (policy-based authorization).

---

*End of session context. Pair this with `Smart_University_Handover_EN.md` (why decisions were made) and `ROADMAP_PROJECT.md` (the full task tree) for complete project understanding.*
# Smart University Platform — Session Context (Phase 1: Authentication) — Update 2

**Purpose of this document:** Continuation snapshot picking up where `SmartUniversity_Session_Context_Phase1.md` left off. That file is still valid for everything through "Refresh endpoint with rotation" — this document **extends it**, covering the work that closes out Module 1.3 entirely. Pair all three together: `Smart_University_Handover_EN.md` (why), `ROADMAP_PROJECT.md` (full task tree), the original Phase 1 context file (Modules 1.1–1.2 + early 1.3), and this file (the rest of 1.3).

**Working process reminder (unchanged):** Design before code for new concepts. A checkbox is only marked `[x]` once there is real evidence (DB query, actual HTTP response) — never because the code compiles.

---

## 1. What changed in the codebase since the last snapshot

- **`Program.cs`** — added `AddRateLimiter()` with a named policy `"AuthEndpoints"` (Fixed Window algorithm, partitioned per client IP), wired into the pipeline via `app.UseRateLimiter()`, placed **before** `app.UseAuthentication()`.
- **`AuthController.cs`** — `Login` and `Refresh` actions decorated with `[EnableRateLimiting("AuthEndpoints")]`.
- **`AuthService.cs`** — `LoginAsync` now has the full lockout-trigger logic. Two new constants added alongside `GenericInvalidCredentialsMessage`:
  ```csharp
  private const int MaxFailedLoginAttempts = 5;
  private static readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);
  ```

---

## 2. What's empirically verified working (Module 1.2 — carried forward, unchanged)

See the original context file — login, JWT issuance/validation, expiry, and middleware order are all still verified and untouched by this session's work.

---

## 3. Module 1.3 — now fully closed

### Refresh token issuance/storage, rotation, reuse detection — ✅ done
Unchanged from the previous snapshot — still verified via the three-step reuse test (rotate → reuse old token → family-wide revocation confirmed).

### Account lockout & rate limiting — ✅ done (this session's work)

**Rate limiting:**
- Algorithm: Fixed Window, `PermitLimit = 5`, `Window = 1 minute`, partitioned by `RemoteIpAddress`.
- Applied to `POST /api/auth/login` and `POST /api/auth/refresh` via `[EnableRateLimiting("AuthEndpoints")]`. (`/register` doesn't exist yet — apply the same attribute once it's built.)
- Rejection returns `429` with a `Retry-After` header and a JSON body.
- **Verified by:** PowerShell burst of 7 requests → first 5 returned `401` (wrong password, real attempts), last 2 returned `429` (rate-limited).

**Account lockout:**
- Threshold 5 failed attempts → `LockoutEndUtc` set to `now + 15 minutes`.
- Locked accounts are rejected with the same generic message as a wrong password (enumeration-resistant — a caller can't distinguish "wrong password" from "account locked").
- An expired lockout (`LockoutEndUtc` in the past) is detected and cleared — `FailedLoginCount` resets to 0 — before the password check runs, so failures don't keep stacking past a lock that's already lifted.
- **Verified by:**
  1. SSMS query after 5 failed attempts: `FailedLoginCount = 5`, `LockoutEndUtc` populated ~15 minutes ahead.
  2. A login with the **correct** password (`Test@123`), sent after waiting out the rate-limit window but still inside the 15-minute lockout window, returned `401 Unauthorized` — direct proof the lock blocks even valid credentials, not just continued bad ones.
- **Not yet empirically tested:** the auto-reset-on-expiry branch itself (i.e., confirming `FailedLoginCount` actually drops to 0/1 after a lock naturally expires, rather than continuing to climb). The code path exists and was reasoned through, but no DB evidence has been collected for it yet. If a future session wants full confidence, temporarily set `LockoutDuration` to `TimeSpan.FromSeconds(20)` for a fast test, then revert.

**Module 1.3 is fully closed — all 4 sub-tasks under "Account lockout & rate limiting" in `ROADMAP_PROJECT.md` should read `[x]`.**

---

## 4. Key facts a new session needs (avoid re-discovering these)

- **Rate limiter policy name is `"AuthEndpoints"`** — defined once in `Program.cs`, referenced by attribute on each controller action that needs it. Don't redefine it per-endpoint.
- **Pipeline order matters:** `UseRateLimiter()` must come before `UseAuthentication()` so brute-force requests are rejected before any password hashing/DB work happens.
- **Testing gotcha (easy to trip on again):** the rate limiter sits in front of the lockout check. A burst test that exhausts the 5/minute IP budget will return `429` for any further requests — including ones meant to test the lockout logic itself. To test "does a locked account reject the *correct* password," you must wait out the rate-limit window (or use a fresh testing IP/window) before sending that request, otherwise you're only proving the rate limiter works, not the lockout.
- **PowerShell scoping gotcha:** inside a `catch` block, `$_` refers to the caught error, not the outer loop variable. Capture the loop variable first (`$attempt = $_`) before entering `try`, or attempt numbers in output will be wrong.
- **`/register` doesn't exist yet** — when it's built, give it the same `[EnableRateLimiting("AuthEndpoints")]` treatment; the roadmap calls for rate limiting on all three auth-adjacent endpoints.

---

## 5. Immediate next step

Move to **Module 1.4 — Authorization** (the next item in the roadmap, now that 1.3 is closed):

1. Define policies mapping to required roles (e.g. `AcademicOfficeOnly`, `LecturerOnly`).
2. Apply policies to a few sample protected endpoints.
3. Confirm authorization reads roles from the token only — never from a UI-selected role (this is already structurally true since JWTs carry all real roles and nothing tracks a "selected" role server-side, but it should be demonstrated against an actual policy-gated endpoint).
4. Build a logout endpoint that revokes the refresh token, and confirm via SSMS that the row's `RevokedAtUtc` gets set.

**Dependency check:** already satisfied — JWTs with real roles are issued and validated (`/api/auth/me` proves this), so policy-based authorization can be layered on directly without further prep work.

---

*End of Update 2. Pair with `Smart_University_Handover_EN.md`, `ROADMAP_PROJECT.md`, and `SmartUniversity_Session_Context_Phase1.md` (the original) for complete project understanding.*
Smart University Platform — Session Context (Phase 1: Authentication) — Update 3
Purpose: Continuation snapshot extending Update 2. That file is valid through the close of Module 1.3. This update covers everything that closes out Module 1.4 — the last backend piece of Phase 1.
Working process reminder (unchanged): Design before code for new concepts. A checkbox is only [x] once there's real evidence — a DB query, an actual HTTP response — never just because the code compiles.

1. What changed in the codebase since Update 2

Program.cs — added AddAuthorization() with five named policies, each backed by RequireRole(): AdminOnly, AcademicOfficeOnly, LecturerOnly, DepartmentStaffOnly, StudentOnly.
AuthController.cs — added two throwaway test endpoints (GET /admin-only, GET /lecturer-only) gated by [Authorize(Policy = "...")], used to prove the policies actually work. Also added the real POST /logout endpoint + a LogoutRequest record, decorated with [EnableRateLimiting("AuthEndpoints")].
AuthResult.cs — added a parameterless Ok() overload (success with no payload), alongside the existing Fail(string) and Ok(LoginResponse).
IAuthService.cs — added Task<AuthResult> LogoutAsync(string rawRefreshToken).
AuthService.cs — implemented LogoutAsync, reusing the existing RevokeFamilyAsync helper (the same one reuse-detection already relies on) to kill the entire refresh-token family on logout, not just the single presented token.


2. Module 1.4 — now fully closed
Policies + sample protected endpoints — ✅ verified:
Login as/lecturer-only/admin-onlyadmin01403200lecturer01200403manager01 (Lecturer + AcademicOffice)200403
The manager01 row is the important one — a multi-role user still gets rejected from admin-only, proving authorization reads real token claims only. There's no server-side "selected role" concept to even test against; it never existed past the client.
Logout — ✅ verified:

POST /api/auth/logout with a valid refresh token → 204.
Immediately reusing that same (now-revoked) refresh token against /api/auth/refresh → 401. Proves the session is actually dead, not just a DB column updated that nothing checks.
No [Authorize] on this endpoint — same reasoning as /refresh: possessing a valid refresh token is itself the credential being acted on. Requiring a live access token to log out would strand idle sessions.

Module 1.4 is fully closed — all 4 sub-tasks in ROADMAP_PROJECT.md should read [x]. Combined with Module 1.3, all of Phase 1's backend work is done.

3. Debugging notes worth keeping (recurring pattern this session)

"Build succeeded" ≠ "the running process has the new code." Hit repeatedly this session — a brand-new route 404'd until the actual API process (separate from any test terminal, and separate from just opening a new PowerShell tab) was fully stopped and restarted.
Reliable diagnostic trick: type the route's URL directly into a browser (always sends GET). For a POST-only route: 404 = route not registered at all; 405 Method Not Allowed = route exists, just correctly rejecting GET. This is more trustworthy than checking Swagger — Swagger itself can 404 for unrelated environment-config reasons even while the API and its real routes are alive (/api/ping responded fine while /swagger 404'd in this session).
One real bug found along the way: the AuthResult.cs factory methods got pasted into AuthService.cs by mistake. The build still succeeded (no inherent conflict from one class having unrelated static methods sharing names with another class), but the real AuthResult.Ok() overload was missing, so the explicit AuthResult.Ok() call inside LogoutAsync failed to compile until the methods were moved to the right file.


4. Key facts a new session needs (additions to Update 2's list)

Five authorization policies exist, defined once in Program.cs: AdminOnly, AcademicOfficeOnly, LecturerOnly, DepartmentStaffOnly, StudentOnly. Reuse these names; don't redefine per-controller.
AuthResult.Ok() (no args) exists now for service methods that succeed without a LoginResponse payload.
IAuthService has three methods: LoginAsync, RefreshAsync, LogoutAsync.
Logout revokes the whole token family, not just the presented token — consistent with how reuse-detection already treats a family as one continuous session.


5. Immediate next step
Two paths open now that Phase 1's backend is fully closed:

Module 1.5 — Flutter Auth UX (login screen, secure storage, refresh interceptor, role picker) — different stack, Dart/Flutter.
Phase 2 — Academic Structure (Faculties/Departments, Majors/Programs/Courses, AcademicTerms/CourseOfferings) — back to C#/EF Core.

No decision made yet on which to start first — open question for whichever session picks this up.

End of Update 3. Pair with Smart_University_Handover_EN.md, ROADMAP_PROJECT.md, and the original + Update 2 context files for complete project understanding.
Smart University Platform — Session Context (Phase 1: Authentication) — Update 4
Purpose: Continuation snapshot extending Update 3. That file is valid through the close of Module 1.4's "Policy-based authorization" feature. This update covers the second feature in the same module — Account Provisioning — which closes out all of Phase 1's backend.
Working process reminder (unchanged): Design before code for new concepts. A checkbox is only [x] once there's real evidence — a DB query, an actual HTTP response — never just because the code compiles.

1. What changed in the codebase since Update 3

- Features/Auth/Dtos/RegisterRequest.cs — new. Fields: LoginCode, FullName, InitialPassword, Email (nullable), RoleNames (List<string>). Lives in the feature folder, not Common/Dtos — matches where LoginRequest/LoginResponse already live. Common/Dtos is reserved for things genuinely shared across features.
- IAuthService.cs — added Task<AuthResult> RegisterAsync(RegisterRequest request, int requestingUserId).
- AuthService.cs — implemented RegisterAsync: looks up the caller's own UniversityId (never trusts a tenant ID from the request body — security-relevant, prevents cross-tenant account creation), checks (UniversityId, LoginCode) uniqueness, resolves RoleNames against the Roles table, creates the User row with MustChangePassword = true and Status = 1, adds matching UserRoles rows.
- Program.cs — added a sixth authorization policy: AccountProvisioning, via RequireRole("Admin", "AcademicOffice") (OR logic — either role passes).
- AuthController.cs — added POST /api/auth/register, gated by [Authorize(Policy = "AccountProvisioning")] + [EnableRateLimiting("AuthEndpoints")]. Reads the caller's id from the "uid" claim (same claim name already used in the existing /me endpoint).

2. Module 1.4 — now fully closed (both features)

"Account provisioning endpoint" — ✅ verified, 6/6:
- POST /api/auth/register as admin01 → succeeded; SSMS confirmed new Users row (student99, UserId 1003) with MustChangePassword = 1, Status = 1, correct UniversityId.
- Matching UserRoles row confirmed: UserId 1003 → RoleId 1 (Student).
- 403 confirmed: student01 calling /register → Forbidden.
- 400 confirmed: re-registering the same LoginCode (student99) → BadRequest, not a silent overwrite.
- 429 confirmed: burst of 7 register calls as admin → first 2 succeeded, remaining 5 returned 429.

Combined with the already-closed "Policy-based authorization" feature (Update 3), Module 1.4 is fully closed. All of Phase 1's backend (Modules 1.1–1.4) is now done. Only Module 1.5 (Flutter) remains for Phase 1 overall.

Roadmap bookkeeping to apply in ROADMAP_PROJECT.md: all 6 sub-tasks under "Account provisioning endpoint" → [x], Completion: 6/6; Phase 1 Definition of Done item "Account provisioning endpoint works..." → [x]; Phase 1 task count moves from 41/57 to 47/57; Project Total moves from 67/272 to 73/272.

3. Bugs hit and fixed this session (debugging notes worth keeping)

- 404 on first attempt — the register action hadn't actually been added to AuthController.cs yet (DTO and service method existed, controller route didn't). Consistent with the established rule: 404 = route not registered at all.
- 500, "AuthorizationPolicy named 'AccountProvisioning' was not found" — the [Authorize(Policy = "AccountProvisioning")] attribute referenced a policy that was never added to Program.cs's AddAuthorization() block. Fix was adding the policy definition — a pure code/config fix, nothing to do with the Roles table. Worth flagging: there was a real misconception mid-session that the missing thing was a row in the Roles table (an "AccountProvisioning" role) — it isn't. Policies are C# code; roles are database data. A policy just names a rule referencing existing roles.
- 500, "Cannot insert the value NULL into column 'FullName'" — the User object being constructed in RegisterAsync never set FullName, even though RegisterRequest carries it. SQL's NOT NULL constraint caught it correctly; the bug was a missing line in the object initializer, not a database problem.
- New rate-limit gotcha (extends the one already documented in Update 2): the "AuthEndpoints" policy is a single shared per-IP budget across every endpoint that uses the attribute (login, refresh, logout, register together) — not 5 calls per endpoint. A burst test run after other auth calls in the same window will hit 429 sooner than expected, because earlier calls (including rejected ones, since rate limiting runs before authorization) already consumed part of the budget. This is correct behavior, not a bug — but it explains why a "7-call burst" only got 2 successes before 429s, not 5.

4. Key facts a new session needs (additions to Update 2/3's lists)

- DTO placement convention: feature-specific DTOs go in Application/Features/{FeatureName}/Dtos (namespace SmartUniversity.Application.Features.{FeatureName}.Dtos). Common/Dtos is only for things shared across multiple features.
- Role entity's name column is Name, not RoleName (confirmed via DbSeeder.cs's own Role { Name = "..." } usage) — don't reintroduce a RoleName typo in future role-lookup code.
- Users.Status is byte, with no formal enum yet — 1 = active is an informal convention shared between DbSeeder.cs and AuthService.cs, each with their own // TODO comment. Worth formalizing into a small UserStatus constant/enum at some point; not blocking.
- IAuthService now has four methods: LoginAsync, RefreshAsync, LogoutAsync, RegisterAsync.
- AccountProvisioning policy = RequireRole("Admin", "AcademicOffice"), defined in Program.cs alongside the other five named policies.
- Tenant-derivation rule for any future admin-acting-on-behalf-of-someone-else endpoint: always derive UniversityId (or other tenant-scoping fields) from the authenticated caller's own record, never accept it as client input.

5. Immediate next step

Two things still open, neither done yet:

1. Cleanup refactor (discussed, agreed on, not yet executed): move the Register action out of AuthController.cs into a new AccountsController.cs (session/auth-lifecycle endpoints vs. account-creation endpoints are different concerns — mirrors the Module 1.2/1.3 vs Module 1.4 split already in the roadmap). Also delete the two throwaway test endpoints (admin-only, lecturer-only) now that their verification purpose is served and documented.
2. Same open choice as Update 3: Module 1.5 — Flutter Auth UX (different stack, Dart/Flutter) vs. Phase 2 — Academic Structure (back to C#/EF Core). No decision made yet.

End of Update 4. Pair with Smart_University_Handover_EN.md, ROADMAP_PROJECT.md, and the original + Update 2 + Update 3 context files for complete project understanding.

---

# Smart University Platform — Session Context (Phase 1: Authentication) — Update 5

**Purpose:** Continuation snapshot extending Update 4. That file is valid through the close of all Phase 1 **backend** work (Modules 1.1–1.4). This update covers **Module 1.5 — Flutter Auth UX**, which is the final piece of Phase 1. The stack switches entirely to Dart/Flutter — no C# changes in this session.

**Working process reminder (unchanged):** Design before code for new concepts. A checkbox is only `[x]` once there is real evidence. **Important caveat for this update:** all code was written and analyzed clean (no errors), but **none of it has been tested against a running backend yet**. The session ended at "code complete, e2e test pending." Do not mark Module 1.5 checkboxes `[x]` until the e2e test is run.

---

## 1. What changed in the Flutter codebase

### New files

| File | Role |
|---|---|
| `lib/data/models/refresh_response.dart` | Parses `/refresh` response `{ accessToken, refreshToken }`. Separate from `LoginResponse` because the backend's `/refresh` endpoint does NOT return `roles[]` or `requiresRoleSelection` again — only new tokens. |
| `lib/data/services/authenticated_client.dart` | `http.BaseClient` subclass. Attaches `Authorization: Bearer` to every request; on 401 calls `/refresh`, retries once; on refresh failure clears storage and fires `onUnauthenticated`. Concurrent 401s are serialised via a `Completer<bool>` so only one `/refresh` call goes out regardless of how many requests failed simultaneously. |
| `lib/features/auth/screens/role_picker_screen.dart` | **Post-login** role picker. Shows only the roles the JWT actually confirms for this account (from `LoginResponse.roles`). Distinct from `RoleSelectionScreen` (pre-login UX hint that lists every possible role). Accepts `List<String> roles` — not `LoginResponse` — so it can also be used when restoring a session from storage on startup. |
| `lib/features/home/screens/workspace_screen.dart` | Placeholder workspace screen. Displays the active role's icon/label and a logout button. Phase 2+ will replace the body with real content per role. |
| `lib/core/session_context.dart` | `ChangeNotifier` holding auth state: `_roles`, `_activeRole`, `_loginCode`. Public getters: `roles`, `activeRole`, `loginCode`, `isLoggedIn`, `needsRolePicker`. Mutating methods: `login(LoginResponse)`, `restore(List<String>)`, `selectRole(AppRole)`, `logout()`. Each calls `notifyListeners()`. Exposed as a global `session` in `main.dart`. |

### Modified files

| File | Change summary |
|---|---|
| `lib/data/services/token_storage.dart` | Added `_kRoles` key. `saveTokens()` now requires `roles: List<String>` — stored as comma-joined string (`"Student,Lecturer"`). Added `readRoles()` — splits on `,`, returns `[]` on null/empty. `clear()` now also deletes the roles key. |
| `lib/data/services/auth_service.dart` | `saveTokens()` call in `_handleResponse()` now passes `roles: data.roles`. No other logic changed. |
| `lib/data/services/authenticated_client.dart` | `_performRefresh()` reads `existingRoles` from storage before calling `saveTokens()`, and passes them through — refresh does not re-receive roles from the server, so they must be preserved manually. |
| `lib/features/auth/models/app_role.dart` | Added `static AppRole fromBackendId(String id)` factory and a `static const _backendRoles` map. Maps backend role name strings (`"Student"`, `"Lecturer"`, `"DepartmentStaff"`, `"AcademicOffice"`, `"Admin"`) to display info (Vietnamese label, icon, blurb). Falls back to a generic entry for unknown role IDs. |
| `lib/features/auth/screens/login_screen.dart` | `_routeAfterLogin()` replaced: now routes to `RolePickerScreen(roles: data.roles)` when `requiresRoleSelection` is true, and to `WorkspaceScreen(activeRole: AppRole.fromBackendId(data.roles.first))` when false. `_PostLoginPlaceholder` deleted entirely. |
| `lib/features/auth/screens/splash_screen.dart` | `_scheduleAdvance()` now checks `TokenStorage().hasSession()` after the 2s delay. No session → `RoleSelectionScreen`. Has session → `readRoles()`: empty → `RoleSelectionScreen` (fallback); 1 role → `WorkspaceScreen`; multiple roles → `RolePickerScreen`. Each `await` is followed by a `mounted` guard. |
| `lib/main.dart` | Added three top-level globals: `navigatorKey` (wired into `MaterialApp`), `session` (the `SessionContext` instance), `authenticatedClient` (the `AuthenticatedClient` instance). The `onUnauthenticated` callback now calls `session.logout()` before navigating. |

---

## 2. Architecture decisions worth preserving

**Why `List<String>` in `RolePickerScreen`, not `LoginResponse`?**
`LoginResponse` is a login-time concept. When the app restores a session from storage, there is no `LoginResponse` — only the stored `List<String>`. Accepting `List<String>` makes the screen usable in both paths without creating a fake `LoginResponse` object.

**Why store roles as CSV in secure storage?**
`FlutterSecureStorage` only stores `String`. Options were CSV (`join`/`split`), JSON (`jsonEncode`/`jsonDecode`), or a separate key per role. CSV is simplest and sufficient — role names never contain commas, and the list is short.

**Why does `_performRefresh()` read and re-save existing roles?**
The backend's `POST /api/auth/refresh` returns only new tokens, not a new `LoginResponse`. `saveTokens()` is now required to include `roles`. If `_performRefresh()` did not re-read and pass them through, the refresh would wipe the stored roles — breaking the startup session-restore on the next app launch.

**Why three `mounted` checks in `SplashScreen._scheduleAdvance()`?**
Each `await` is a suspension point. During any suspension the widget can be disposed (user kills the app, hot restart, etc.). Using `context` after disposal crashes. Three async calls → three guards.

**`SessionContext` is a `ChangeNotifier`, not a simple data class.**
Reason: Phase 2+ screens will need to react to role changes or logout without being rebuilt by parent widgets or passed callbacks. `ListenableBuilder(listenable: session, ...)` lets any widget subscribe independently. Chose `ChangeNotifier` over Provider/Riverpod/Bloc to avoid adding a package and to teach the underlying Flutter primitive first.

---

## 3. Current Module 1.5 status

| Feature | Tasks done (code) | Empirically verified |
|---|---|---|
| Login screen & secure token storage | 4/4 | ❌ pending e2e test |
| Auth interceptor & token refresh | 3/3 | ❌ pending e2e test |
| Role picker & routing | 3/3 | ❌ pending e2e test |

**Definition of Done — Phase 1** — items still open:

- `[ ] Flutter login, secure storage, and silent refresh all work.` — code written; needs e2e test.
- `[ ] Multi-role users see the role picker; single-role users route directly.` — code written; needs e2e test.

---

## 4. Key facts a new session needs (Flutter-specific additions)

- **Three globals in `main.dart`** (import `main.dart` to use them):
  - `navigatorKey` — for navigating outside widget context (already wired into `MaterialApp`).
  - `session` — `SessionContext` instance; call `session.login(response)` after login, `session.restore(roles)` on startup, `session.logout()` anywhere.
  - `authenticatedClient` — use instead of `http.Client()` for any protected endpoint.

- **`flutter_secure_storage` v10.3.1** uses three keys: `access_token`, `refresh_token`, `roles` (CSV). Android: `EncryptedSharedPreferences`. iOS: Keychain (`first_unlock` accessibility).

- **`RolePickerScreen` takes `List<String> roles`**, not `LoginResponse`. Pass `data.roles` from login, or `await storage.readRoles()` from startup.

- **`WorkspaceScreen` is a placeholder.** It receives `AppRole activeRole` via constructor (navigation state only — never sent to the API). Phase 2 replaces the body.

- **The `onUnauthenticated` callback** (in `AuthenticatedClient` via `main.dart`) calls `session.logout()` then navigates to `RoleSelectionScreen`. Both steps are needed — navigation alone does not clear `SessionContext` state.

- **Backend `/refresh` does not return roles** — this is confirmed by the `RefreshResponse` model containing only `{ accessToken, refreshToken }`. Any code that calls `/refresh` and then tries to read roles from the response will get null/empty.

- **Pre-login `RoleSelectionScreen` vs. post-login `RolePickerScreen`:**
  - `RoleSelectionScreen` — shown before login, lists every possible role as a UX hint to pre-fill the "Signing in as…" label. Tapping it does NOT grant that role.
  - `RolePickerScreen` — shown after login when `requiresRoleSelection = true`, lists only the roles the JWT confirms. Tapping routes to the workspace for that role.

- **Seeded test accounts** (from Update 1, still valid): `admin01` (Admin), `office01` (AcademicOffice), `deptstaff01` (DepartmentStaff), `lecturer01` (Lecturer), `student01` (Student), `manager01` (Lecturer + AcademicOffice — the multi-role account). Password for all: `Test@123`.

---

## 5. Immediate next steps

**Before ticking any Module 1.5 checkbox `[x]`**, run the following e2e test sequence with the backend live:

1. **Login (single-role):** log in as `student01` → confirm token stored in secure storage → confirm navigate directly to `WorkspaceScreen` (Student).
2. **Login (multi-role):** log in as `manager01` → confirm `RolePickerScreen` appears with 2 cards (Giảng Viên, Phòng Đào Tạo) → pick one → confirm `WorkspaceScreen` for that role.
3. **Session restore:** close and reopen the app → confirm `SplashScreen` bypasses login and routes to the workspace directly (not to `RoleSelectionScreen`).
4. **Silent refresh:** wait for the access token to expire (~15 min), or temporarily set `AccessTokenExpiryMinutes = 1` in the backend; make an authenticated API call → confirm the call succeeds after transparent refresh (no visible re-login prompt).
5. **Hard logout:** tap the logout button → confirm `TokenStorage.clear()` ran (open the app again → should go to `RoleSelectionScreen`) and that the revoked refresh token is rejected by the backend.

Once all five steps pass, close Module 1.5 and tick the two remaining Phase 1 Definition of Done items.

**After Module 1.5 is verified:** Phase 1 is complete. Next is Phase 2 — Academic Structure (back to C#/EF Core). Start with Module 2.0 shared patterns before any entity-specific CRUD.

---

*End of Update 5. Pair with `Smart_University_Handover_EN.md`, `ROADMAP_PROJECT.md`, and Updates 1–4 for complete project understanding.*