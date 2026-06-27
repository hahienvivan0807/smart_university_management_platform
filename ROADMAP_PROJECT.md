# ROADMAP_PROJECT.md — Smart University Management Platform

**Document type:** Project roadmap & progress-management document
**Project:** Smart University Management Platform (Smart Campus)
**Stack:** ASP.NET Core Web API · C# · Entity Framework Core · SQL Server · Flutter
**Architecture:** Layered — Controller → Service → EF Core DbContext → SQL Server
**Tenancy:** Single university now; `UniversityId` present on tenant-relevant tables for future multi-tenant SaaS.
**Status at creation:** Foundation SQL schema (16 tables) designed and runnable. No application code written yet. All tasks below start unchecked.

---

## How To Use This Document

This file is both a **plan** and a **tracker**. As you finish each task, change `* [ ]` to `* [x]` and update the `Completion: x/n` line under that feature. At the end of each phase, confirm every item in **Definition of Done** is true before moving on. Update the **Progress Tracking** section at the bottom as phases complete.

**Build the phases strictly in order.** Each phase depends on the ones before it. Skipping ahead causes the failures noted in each phase's dependency notes.

### Document structure

```
# Phase        → a major stage of the project
## Module      → a coherent area of work inside a phase
### Feature    → a deliverable unit; broken into one-day-or-less tasks
#### / * [ ]   → individual checkbox tasks
```

Each feature lists its **Objective**, **Expected outcome**, **Knowledge to learn**, and **Dependency**. Each phase ends with a **Definition of Done**.

### Conventions decided for the whole project

- **DTOs only at the API boundary.** Controllers never return EF entities; never return password or token hashes.
- **Authorization uses the JWT's real roles only** — never the role selected in the UI.
- **Account creation is closed, not self-service.** Students/lecturers never create their own login. Accounts are provisioned only by `Admin`/`AcademicOffice`, via seed/bulk import (Module 1.1) or the `POST /api/auth/register` endpoint (Module 1.4) — both admin-gated. **This resolves an earlier ambiguity:** §3 of the handover doc listed "Register" under Authentication, and this file's own rate-limiting notes referenced an undefined `/register` endpoint — both read as if they implied public signup. They don't. See `Smart_University_Handover_EN.md` §6.9 for the decision. *Course* registration (§16 of the handover) is the opposite — open, student self-service — do not confuse the two.
- **Soft delete in spirit.** Structural/history-bearing rows are deactivated (`IsActive`), not hard-deleted. Block deleting a parent that still has active children.
- **Enrollment is imported, not interactively registered** (until the data-source question is resolved). Do **not** build a registration engine (capacity/prerequisite/conflict logic). **⚠️ STALE — see `Smart_University_Handover_EN.md` §14.5 and §16: this was explicitly REVERSED. The platform now builds its own registration engine (queue + atomic DB check + waitlist). Phase 3 below still describes the old import-based design and needs a rewrite when Phase 3 starts — do not build Phase 3 as currently written.**
- **PK types:** `INT` for stable tables; `BIGINT` for `Enrollments`, `RefreshTokens`, and future audit/attendance high-volume tables.

---

# Phase 0 — Project Foundation

> **Goal:** A running, correct backend wired to the existing SQL Server schema, plus a Flutter app that can call one endpoint. Prove the full pipe `Flutter → API → Service → EF Core → SQL Server` before building any feature.

## Module 0.1 — Backend Setup

### Feature: ASP.NET Core solution & Web API project

* [x] Install .NET SDK and verify `dotnet --version`
* [x] Create the solution file (`SmartUniversity.sln`)
* [x] Create the Web API project inside the solution
* [x] Create empty class-library projects for layering (e.g. `Domain`, `Application`, `Infrastructure`) and reference them
* [x] Run the API and confirm the default endpoint responds in a browser/Swagger

Completion: 5/5

- **Objective:** Stand up an empty but correctly structured ASP.NET Core Web API solution.
- **Expected outcome:** `dotnet run` launches the API and Swagger UI loads.
- **Knowledge to learn:** .NET SDK + CLI, solution vs. project, ASP.NET Core project layout (`Program.cs`, dependency injection container), Swagger/OpenAPI.
- **Dependency:** None. This is the first work in the project.

### Feature: Configuration & SQL Server connection

* [x] Add the connection string to `appsettings.json` (and a local secrets file for credentials)
* [x] Confirm SQL Server is reachable (SSMS connects to the instance)
* [x] Add a startup check or log line confirming the app reads the connection string
* [x] Document how to set the connection string for a fresh machine (in a README note)

Completion: 4/4

- **Objective:** The API knows how to reach the database and keeps secrets out of source control.
- **Expected outcome:** App starts and can read the configured connection string; credentials are not committed to Git.
- **Knowledge to learn:** `appsettings.json` vs. user-secrets/environment variables, configuration binding, connection-string format for SQL Server.
- **Dependency:** ASP.NET Core solution must exist first.

## Module 0.2 — Database Wiring (Database-First)

### Feature: Run and verify the foundation schema

* [x] Run the existing foundation DDL script in SSMS
* [x] Confirm all 16 foundation tables are created in schema `dbo`
* [x] Generate the SSMS database diagram and check it against the documented ER summary
* [x] Verify the key constraints exist (the `(StudentUserId, CourseOfferingId)` unique index; shared-PK profiles; `CHECK` constraints)

Completion: 4/4

- **Objective:** Have a verified, correct database to build against.
- **Expected outcome:** The schema matches the handover document exactly, with all PKs, FKs, unique and check constraints present.
- **Knowledge to learn:** Running DDL in SSMS, reading an ER diagram, what unique/check constraints enforce.
- **Dependency:** SQL Server connection (0.1) confirmed.

### Feature: Scaffold EF Core entities & DbContext

* [x] Install EF Core + SQL Server provider + design-time packages
* [x] Scaffold entities and `DbContext` from the existing database (`Scaffold-DbContext`)
* [x] Review generated entities; confirm relationships, keys, and types are correct
* [x] Move the `DbContext` registration into `Program.cs` dependency injection
* [x] Write a tiny test query (e.g. count rows in `Roles`) and run it successfully

Completion: 5/5

- **Objective:** Get a C# object model that exactly matches the existing schema.
- **Expected outcome:** EF Core can connect and run a query against the real database.
- **Knowledge to learn:** Database-first scaffolding, `DbContext` and `DbSet`, registering services in DI, EF Core providers.
- **Dependency:** Foundation schema must exist and be verified first.

## Module 0.3 — Flutter Setup & End-to-End Proof

### Feature: Health-check endpoint

* [x] Create a `PingController` returning `{ "status": "ok" }`
* [x] Confirm it responds via Swagger
* [x] Enable CORS so the Flutter app can call it during development

Completion: 3/3

- **Objective:** Provide one trivial endpoint to prove connectivity.
- **Expected outcome:** `GET /api/ping` returns a 200 with the status payload.
- **Knowledge to learn:** Controllers, routing/attributes, CORS basics.
- **Dependency:** DbContext wiring (0.2) done (so the app boots cleanly).

### Feature: Flutter app calls the API

* [x] Install Flutter; verify with `flutter doctor`
* [x] Create the Flutter project and run it on an emulator/device
* [x] Add an HTTP client package (`http` or `dio`)
* [x] Build one screen with a button that calls `GET /api/ping`
* [x] Display the response on screen

Completion: 5/5

- **Objective:** Prove the whole pipeline end to end from a real client.
- **Expected outcome:** Tapping the button shows `ok` from the live backend.
- **Knowledge to learn:** Flutter project structure, widgets/state basics, making HTTP requests, talking to `localhost` from an emulator (host IP nuance).
- **Dependency:** Health-check endpoint must be live.

## Definition of Done — Phase 0

* [x] Solution runs with a layered project structure.
* [x] Connection string configured; secrets not in source control.
* [x] All 16 foundation tables exist and match the ER diagram.
* [x] EF Core scaffolded; a test query against the real DB succeeds.
* [x] `GET /api/ping` returns `ok`.
* [x] Flutter app calls the endpoint and displays the result.
* [x] The full path Flutter → API → Service → EF Core → SQL Server is proven working.

---

# Phase 1 — Authentication & Authorization

> **Goal:** A user logs in with `LoginCode` + password, receives a JWT carrying all real roles, and every later endpoint can identify the caller and enforce permissions. Auth is the gatekeeper for every other phase — build it before any feature so you never retrofit security.

## Module 1.1 — Password & Identity Core

### Feature: Password hashing service

* [x] Choose and add a slow-hash library (ASP.NET Core Identity PBKDF2, or BCrypt/Argon2)
* [x] Write a `HashPassword(plain)` method
* [x] Write a `VerifyPassword(plain, hash)` method
* [x] Write a quick throwaway test proving hash + verify round-trips

Completion: 4/4

- **Objective:** Store and check passwords securely.
- **Expected outcome:** Passwords are stored only as salted slow hashes; verification works.
- **Knowledge to learn:** Why slow salted hashes (never MD5/plain SHA-256), salting, the hash-verify pattern.
- **Dependency:** Phase 0 complete (EF Core can read `Users`).

### Feature: Seed initial users & roles

* [x] Confirm the 5 roles are seeded (Student, Lecturer, DepartmentStaff, AcademicOffice, Admin)
* [x] Write a seed script/endpoint that creates a few test users with hashed passwords
* [x] Assign roles to test users via `UserRoles`
* [x] Create at least one multi-role user (to test the role picker later)

Completion: 4/4

- **Objective:** Have real accounts to log in with (accounts are provisioned, not self-registered).
- **Expected outcome:** Test users exist with hashed passwords and assigned roles.
- **Knowledge to learn:** Seeding data, the many-to-many `UserRoles` join, one-user-many-roles model.
- **Dependency:** Password hashing service must exist.
- **Note:** This covers DB-seeded bootstrap accounts. For the equivalent admin-facing API endpoint (so staff can provision accounts after launch without touching the DB directly), see Module 1.4's "Account provisioning endpoint" feature.

## Module 1.2 — Login & JWT Issuance

### Feature: Login DTOs and AuthService skeleton

* [x] Create `LoginRequest` DTO (`LoginCode`, `Password`)
* [x] Create `LoginResponse` DTO (`accessToken`, `refreshToken`, `roles[]`, `requiresRoleSelection`)
* [x] Create `AuthService` class registered in DI
* [x] Add input validation on the login DTO

Completion: 4/4

- **Objective:** Define the login contract and the service that will own auth logic.
- **Expected outcome:** DTOs compile and `AuthService` is injectable.
- **Knowledge to learn:** DTO pattern, model validation, service registration.
- **Dependency:** Phase 0 layering + EF Core.

### Feature: Credential verification & role loading

* [x] Look up user by `(UniversityId, LoginCode)`
* [x] Verify the password hash
* [x] Return a generic "invalid credentials" on any failure (enumeration resistance)
* [x] Load the user's real roles from `UserRoles`

Completion: 4/4

- **Objective:** Validate who the user is and what roles they truly hold.
- **Expected outcome:** Correct credentials resolve to a user + role list; wrong ones give a generic error.
- **Knowledge to learn:** Tenant-scoped lookup, enumeration-resistant error messages, loading related data in EF Core.
- **Dependency:** Password hashing + seeded users.

### Feature: JWT generation

* [x] Store the signing key in configuration/secret manager (not in code)
* [x] Generate a short-lived (~15 min) access token
* [x] Put `UserId` and all real roles into the token claims (no "active role" claim)
* [x] Configure JWT authentication middleware in `Program.cs`
* [x] Confirm a protected test endpoint accepts the token

Completion: 5/5

- **Objective:** Issue a signed token that proves identity and capability.
- **Expected outcome:** A valid login returns a working JWT; a protected endpoint accepts it.
- **Knowledge to learn:** JWT structure (header/claims/signature), signing keys, token expiry, authentication middleware.
- **Dependency:** Credential verification must work.

### Feature: Login endpoint

* [x] Create `POST /api/auth/login` calling `AuthService`
* [x] Compute `requiresRoleSelection = roles.Count > 1`
* [x] Return the full `LoginResponse`
* [x] Test single-role and multi-role logins (verified via PowerShell, not Swagger: `admin01` single-role → `requiresRoleSelection=false`, `manager01` multi-role → `true`)

Completion: 4/4

- **Objective:** Expose login over HTTP.
- **Expected outcome:** Login returns tokens, role list, and the role-selection hint.
- **Knowledge to learn:** Controller-to-service wiring, derived response fields.
- **Dependency:** JWT generation complete.

## Module 1.3 — Refresh Tokens & Account Protection

### Feature: Refresh token issuance & storage

* [x] Generate a refresh token and store only its **hash** in `RefreshTokens`
* [x] Record `ExpiresAtUtc`, `CreatedByIp`, `DeviceInfo`
* [x] Return the raw refresh token to the client once (never store raw)

Completion: 3/3

- **Objective:** Enable long-lived, revocable sessions safely.
- **Expected outcome:** Each login persists a hashed refresh token row.
- **Knowledge to learn:** Why hash tokens at rest, session rows per device.
- **Dependency:** Login endpoint working.

### Feature: Refresh endpoint with rotation

* [x] Create `POST /api/auth/refresh`
* [x] Validate the incoming refresh token against its stored hash
* [x] Rotate: issue a new pair, invalidate the old (`ReplacedByTokenHash`)
* [x] Detect reuse of a rotated token → revoke the whole token family
* [x] Return a new access + refresh token

Completion: 5/5

- **Objective:** Keep sessions alive without re-login, and detect token theft.
- **Expected outcome:** Refresh returns new tokens; reusing an old token revokes the family.
- **Knowledge to learn:** Refresh-token rotation, token families/reuse detection, revocation.
- **Dependency:** Refresh token issuance/storage done.

### Feature: Account lockout & rate limiting

* [x] Increment `FailedLoginCount` on failed attempts
* [x] Set `LockoutEndUtc` after a threshold; block login while locked
* [x] Reset the counter on success
* [x] Add rate limiting to `/login`, `/register`, `/refresh` (per IP and per account)

Completion: 4/4

- **Objective:** Resist brute-force and credential-stuffing attacks.
- **Expected outcome:** Repeated failures lock the account; endpoints are rate-limited.
- **Knowledge to learn:** Lockout strategy, ASP.NET Core rate limiting middleware.
- **Dependency:** Login + refresh endpoints exist.

## Module 1.4 — Authorization & Account Provisioning

### Feature: Policy-based authorization

* [x] Define policies mapping to required roles (e.g. `AcademicOfficeOnly`, `LecturerOnly`)
* [x] Apply policies to a few sample protected endpoints
* [x] Confirm authorization reads roles from the token, never a UI selection
* [x] Confirm a logout endpoint revokes the refresh token (`POST /api/auth/logout` → 204; reusing the same refresh token afterward → 401)

Completion: 4/4

- **Objective:** Gate endpoints by the caller's real roles.
- **Expected outcome:** Endpoints reject callers lacking the required role; logout revokes the session.
- **Knowledge to learn:** Policy-based authorization, claims-based identity, the principle that role selection is UX not security.
- **Dependency:** JWT with roles is issued and validated.

### Feature: Account provisioning endpoint (Admin/AcademicOffice only)

* [x] Create `RegisterRequest` DTO (`LoginCode`, temp/initial password, optional `Email`, target role(s))
* [x] `POST /api/auth/register` gated by `[Authorize(Policy = "AdminOnly")]` or `"AcademicOfficeOnly"` — never public, never anonymous
* [x] Validate `(UniversityId, LoginCode)` uniqueness; assign role(s) via `UserRoles`
* [x] Set `MustChangePassword = true` on the created account
* [x] Apply `[EnableRateLimiting("AuthEndpoints")]` (same policy as login/refresh)
* [x] Test: AcademicOffice/Admin can provision an account; a `Student`/`Lecturer` caller gets `403`

Completion: 6/6

- **Objective:** Give staff an API-driven way to create accounts instead of only DB seeding — closes a real gap (this endpoint was referenced in rate-limiting notes throughout Phase 1 but never actually specified).
- **Expected outcome:** An authorized, rate-limited endpoint creates `LoginCode`-based accounts. No public signup path exists anywhere in the API.
- **Knowledge to learn:** Reusing existing policies on a new endpoint; the provisioned-account pattern (temp password + forced change on first login) vs. self-signup.
- **Dependency:** Policy-based authorization (this module, above) — already satisfied.

## Module 1.5 — Flutter Auth UX

### Feature: Login screen & secure token storage

* [x] Build the login screen (LoginCode + password)
* [x] Call `POST /api/auth/login`
* [x] Store tokens with `flutter_secure_storage`
* [x] Show a friendly error on invalid credentials

Completion: 4/4

- **Objective:** Let users authenticate from the app.
- **Expected outcome:** Valid login stores tokens; invalid login shows an error.
- **Knowledge to learn:** Flutter forms, secure storage, handling API responses.
- **Dependency:** Login endpoint live.

### Feature: Auth interceptor & token refresh

* [x] Add an HTTP interceptor that attaches the access token to every request
* [x] On 401, call `/refresh` and retry the original request
* [x] On refresh failure, clear tokens and route to login

Completion: 3/3

- **Objective:** Keep the user signed in seamlessly.
- **Expected outcome:** Expired access tokens refresh transparently; hard failures force re-login.
- **Knowledge to learn:** HTTP interceptors, silent refresh pattern, app-wide auth state.
- **Dependency:** Refresh endpoint working; secure storage done.

### Feature: Role picker & routing

* [x] If `requiresRoleSelection` is true, show a role-picker screen
* [x] Single-role users route directly to their workspace
* [x] Store the chosen role as client-side navigation state only

Completion: 0/3

- **Objective:** Route multi-role users without affecting security.
- **Expected outcome:** Multi-role users pick a workspace; single-role users skip the picker.
- **Knowledge to learn:** Conditional navigation, the difference between UX role and authorization.
- **Dependency:** Login + interceptor done.

## Definition of Done — Phase 1

* [x] Login with `LoginCode` + password returns a JWT.
* [x] JWT carries `UserId` + all real roles.
* [x] Refresh token works, is stored hashed, and rotates on use.
* [x] Token-reuse revokes the family; logout revokes the session.
* [x] Account lockout and rate limiting active on auth endpoints.
* [x] Policy-based authorization enforces roles from the token only.
* [x] Account provisioning endpoint works (Admin/AcademicOffice only; no public signup path exists).
* [x] Flutter login, secure storage, and silent refresh all work.
* [x] Multi-role users see the role picker; single-role users route directly.

---

# Phase 2 — Academic Structure

> **Goal:** Make the backbone data manageable and viewable — the three trees: Institutional (University → Faculty → Department), Catalog (Major → Program → Course), and Offerings (AcademicTerm → CourseOffering), plus profiles. Almost every later module references this. Build read endpoints + a seed script first (fast demo), then admin CRUD.

## Module 2.0 — Shared Patterns

### Feature: DTO + service layer conventions

* [x] Create a base pattern for list/detail DTOs (no entities exposed)
* [x] Create a reusable service base or convention (Controller → Service → DbContext)
* [x] Standardize a paged list response shape
* [x] Add consistent validation + error responses

Completion: 4/4

- **Objective:** Avoid writing each entity's plumbing ten different ways.
- **Expected outcome:** A repeatable DTO/service pattern reused by every entity below.
- **Knowledge to learn:** DTO projection, mapping (manual or AutoMapper), pagination, the layered pattern.
- **Dependency:** Phase 1 done (endpoints need authorization).

### Feature: Soft-delete convention

* [x] Add an EF Core global query filter on `IsActive`
* [x] Implement a rule blocking deletion of a parent with active children
* [x] Provide a deactivate (soft-delete) service method
* [ ] Document the convention in this file's conventions section

Completion: 3/4

- **Objective:** Ratify one soft-delete approach before bulk CRUD.
- **Expected outcome:** Soft delete works uniformly; structural rows are never hard-deleted.
- **Knowledge to learn:** EF Core global query filters, cascade/block rules.
- **Dependency:** Shared DTO/service pattern.

## Module 2.1 — Institutional Hierarchy

### Feature: Faculty read + seed

* [ ] Seed sample faculties
* [x] `GET /api/faculties` (list) and `GET /api/faculties/{id}` (detail)
* [x] Return DTOs only

Completion: 2/3

- **Objective:** View faculties.
- **Expected outcome:** Faculty list/detail endpoints return data.
- **Knowledge to learn:** Read endpoints, projection to DTOs.
- **Dependency:** Shared patterns (2.0).

### Feature: Faculty admin CRUD

* [x] `POST /api/faculties` (create) — AcademicOffice/Admin only
* [x] `PUT /api/faculties/{id}` (edit)
* [x] Soft-delete (deactivate) endpoint
* [x] Validate unique `(UniversityId, Code)`

Completion: 4/4

- **Objective:** Manage faculties.
- **Expected outcome:** Staff can create/edit/deactivate faculties; duplicates rejected.
- **Knowledge to learn:** Authorized writes, unique-constraint handling.
- **Dependency:** Faculty read + soft-delete convention.

### Feature: Department read + CRUD

* [ ] Seed sample departments under faculties
* [ ] List/detail endpoints (filter by faculty)
* [ ] Create/edit/soft-delete (staff only)
* [ ] Validate unique `(FacultyId, Code)`

Completion: 0/4

- **Objective:** Manage departments (optional org level under faculty).
- **Expected outcome:** Department endpoints work and respect the optional-level design.
- **Knowledge to learn:** Nullable parent relationships, filtered queries.
- **Dependency:** Faculty CRUD done.

## Module 2.2 — Academic Catalog

### Feature: Major read + CRUD

* [ ] Seed majors under faculties
* [x] List/detail (filter by faculty)
* [x] Create/edit/soft-delete (staff only)
* [x] Validate unique `(FacultyId, Code)`

Completion: 3/4

- **Objective:** Manage fields of study.
- **Expected outcome:** Major endpoints work.
- **Knowledge to learn:** Catalog vs. offering separation (concept).
- **Dependency:** Faculty exists.

### Feature: Program read + CRUD

* [ ] Seed programs (curriculum versions) under majors
* [x] List/detail (filter by major)
* [x] Create/edit/soft-delete (staff only)
* [x] Validate `CurriculumYear` range and unique `(MajorId, Code)`

Completion: 3/4

- **Objective:** Manage curriculum versions (Program = curriculum version of a Major).
- **Expected outcome:** Programs can be created without altering existing cohorts' programs.
- **Knowledge to learn:** Curriculum versioning (new curriculum = new Program), check constraints.
- **Dependency:** Major CRUD done.

### Feature: Course read + CRUD

* [ ] Seed reusable catalog courses (with credits)
* [x] List/detail (filter by owner department/faculty)
* [x] Create/edit/soft-delete (staff only)
* [x] Validate `Credits > 0` and unique `(UniversityId, Code)`

Completion: 3/4

- **Objective:** Manage the reusable, term-independent course catalog.
- **Expected outcome:** Courses defined once, ready to be offered many times.
- **Knowledge to learn:** Why courses are catalog (not per-term), nullable owner with faculty fallback.
- **Dependency:** Faculty/Department exist.

### Feature: ProgramCourses (curriculum mapping)

* [x] Endpoint to add a course to a program's curriculum
* [x] Set `RecommendedSemester` and `IsRequired`
* [x] List a program's curriculum
* [x] Remove a course from a curriculum

Completion: 4/4

- **Objective:** Define which courses belong to which program.
- **Expected outcome:** A program's curriculum can be assembled and viewed.
- **Knowledge to learn:** Many-to-many join with payload columns.
- **Dependency:** Program + Course CRUD done.

### Feature: CoursePrerequisites

* [x] Endpoint to add a prerequisite (Course ↔ Course)
* [x] Enforce the `CourseId <> PrerequisiteCourseId` check
* [x] Validate against deeper cycles in the service layer
* [x] List a course's prerequisites

Completion: 4/4

- **Objective:** Model prerequisite relationships.
- **Expected outcome:** Prerequisites can be set; self- and cycle-prerequisites are rejected.
- **Knowledge to learn:** Self-referencing many-to-many, cycle detection in the service layer.
- **Dependency:** Course CRUD done.

## Module 2.3 — Profiles

### Feature: StudentProfiles

* [ ] Endpoint to create/link a student profile (shared PK with `Users`)
* [ ] Set `AdminClassId` (required), `IntakeYear`, `StudentStatus`
* [ ] Read a student's profile

Completion: 0/3

- **Objective:** Attach student-specific data to a user.
- **Expected outcome:** Student profiles exist with a required AdminClass link.
- **Knowledge to learn:** 1:1 shared-PK modeling, required FKs.
- **Dependency:** AdminClass (2.4) must exist before a student profile can be linked.

### Feature: LecturerProfiles

* [ ] Endpoint to create/link a lecturer profile (shared PK with `Users`)
* [ ] Set `DepartmentId` (nullable) / `FacultyId` fallback, `AcademicTitle`
* [ ] Read a lecturer's profile

Completion: 0/3

- **Objective:** Attach lecturer-specific data to a user.
- **Expected outcome:** Lecturer profiles exist; a lecturer can later own offerings.
- **Knowledge to learn:** Nullable department with faculty fallback.
- **Dependency:** Faculty/Department exist.

## Module 2.4 — Time-Based Offerings

### Feature: AcademicTerm read + CRUD

* [ ] Seed terms (with date range, term type)
* [ ] List/detail
* [ ] Create/edit (staff only)
* [ ] Validate `StartDate < EndDate` and unique `(UniversityId, AcademicYear, TermNumber)`

Completion: 0/4

- **Objective:** Manage semesters.
- **Expected outcome:** Terms exist for offerings to attach to.
- **Knowledge to learn:** Date-range validation, composite unique keys.
- **Dependency:** Phase 0 schema.

### Feature: AdminClass read + CRUD

* [ ] Seed admin classes under programs
* [ ] List/detail (filter by program)
* [ ] Create/edit/soft-delete (staff only)
* [ ] Optional advisor link; validate unique `(ProgramId, Code)`

Completion: 0/4

- **Objective:** Manage durable student cohorts (lớp hành chính).
- **Expected outcome:** Admin classes exist for students to belong to.
- **Knowledge to learn:** AdminClass vs. CourseOffering distinction (cohort vs. teaching group).
- **Dependency:** Program CRUD done.

### Feature: CourseOffering read + CRUD

* [ ] Create an offering (one Course, one Term, exactly one Lecturer)
* [ ] List offerings by term; detail view
* [ ] Edit capacity/status; soft-cancel
* [ ] Validate `Capacity >= 0` and unique `(AcademicTermId, Code)`

Completion: 0/4

- **Objective:** Manage per-term teaching groups (lớp học phần).
- **Expected outcome:** Offerings exist, each with one assigned lecturer.
- **Knowledge to learn:** One-lecturer-per-offering rule, the unit attendance/enrollment attach to.
- **Dependency:** Course + AcademicTerm + LecturerProfile must exist.

### Feature: Assign students to AdminClass & lecturers to offerings

* [ ] Endpoint to assign a student to an AdminClass
* [ ] Endpoint to assign/reassign a lecturer to an offering
* [ ] Authorization: staff only
* [ ] Validate referential integrity

Completion: 0/4

- **Objective:** Wire people into the structure.
- **Expected outcome:** Students belong to cohorts; offerings have lecturers.
- **Knowledge to learn:** Assignment endpoints, integrity checks.
- **Dependency:** AdminClass, CourseOffering, profiles exist.

## Module 2.5 — Flutter Browse Screens

### Feature: Structure browsing UI

* [ ] Faculty/Department browse screen
* [ ] Program + curriculum browse screen
* [ ] Course catalog screen
* [ ] Offerings-by-term screen

Completion: 0/4

- **Objective:** Let users view the academic structure.
- **Expected outcome:** Read screens display live data from the API.
- **Knowledge to learn:** Flutter lists, navigation, calling authorized endpoints.
- **Dependency:** Read endpoints (2.1–2.4) exist; auth interceptor done.

### Feature: Admin management UI (staff)

* [ ] Forms to create/edit faculties, majors, programs, courses
* [ ] Forms to create terms, admin classes, offerings
* [ ] Assignment screens (student→class, lecturer→offering)

Completion: 0/3

- **Objective:** Let staff manage structure from the app.
- **Expected outcome:** Staff can perform CRUD through Flutter.
- **Knowledge to learn:** Flutter forms, role-gated UI.
- **Dependency:** CRUD endpoints + role picker done.

## Definition of Done — Phase 2

* [ ] All three trees have working read endpoints and seed data.
* [ ] CRUD works for Faculty, Department, Major, Program, Course, AcademicTerm, AdminClass, CourseOffering.
* [ ] ProgramCourses and CoursePrerequisites manageable; self/cycle prerequisites blocked.
* [ ] Student and Lecturer profiles can be created and linked.
* [ ] Students assignable to AdminClasses; lecturers assignable to offerings (one per offering).
* [ ] Soft-delete convention applied uniformly; parents with active children can't be deleted.
* [ ] Flutter can browse the structure and (for staff) manage it.

---

# Phase 3 — Enrollment & Timetable

> **Goal:** Students see the classes they're enrolled in for a term, with that data living locally. This is the join connecting students to offerings — every later module (attendance, analytics, AI) needs it. **No registration engine:** enrollments are imported. This is your first real student-facing product milestone.
>
> **⚠️ This entire phase description is OUTDATED.** Per `Smart_University_Handover_EN.md` §16, the import-based design was reversed — the platform now owns a self-service registration engine (queue + atomic DB capacity check + waitlist, v1 scope = capacity + duplicate protection + time gate only, no prerequisite/conflict checks). Rewrite this phase's features against §16 before starting Phase 3; do not build the import-endpoint tasks below as written.

## Module 3.0 — Resolve the Data-Source Question

### Feature: Decide how enrollment data arrives

* [ ] Find out whether the university exposes enrollment/timetable via API or export
* [ ] Decide: import/sync (leaning), live read-through, or manual import
* [ ] Document the decision and the chosen source format in this file
* [ ] Confirm the `Enrollments` schema is unaffected by the choice

Completion: 0/4

- **Objective:** Unblock the ingestion design before coding it.
- **Expected outcome:** A documented decision on the enrollment data source.
- **Knowledge to learn:** System-of-record vs. system-of-engagement, import vs. live read trade-offs.
- **Dependency:** Phase 2 (offerings exist to enroll into).

## Module 3.1 — Enrollment Ingestion

### Feature: Import format & parser

* [ ] Define the import file/record shape (CSV/JSON)
* [ ] Write a parser that maps rows to students + offerings
* [ ] Validate that referenced students and offerings exist
* [ ] Report rows that fail validation

Completion: 0/4

- **Objective:** Turn an external file into validated enrollment records.
- **Expected outcome:** A file parses into candidate enrollment rows with errors reported.
- **Knowledge to learn:** File parsing, validation, mapping external IDs to internal keys.
- **Dependency:** Data-source decision made.

### Feature: Import endpoint & uniqueness handling

* [ ] `POST /api/admin/enrollments/import` (staff only)
* [ ] Insert valid `Enrollments` respecting `(StudentUserId, CourseOfferingId)` uniqueness
* [ ] Skip/flag duplicates (same student + same offering)
* [ ] Allow the same course across different offerings (retake) to coexist

Completion: 0/4

- **Objective:** Populate `Enrollments` safely.
- **Expected outcome:** Importing twice doesn't duplicate; retakes across offerings coexist.
- **Knowledge to learn:** The retake-enabling unique constraint and why it must never weaken to (student, course).
- **Dependency:** Import parser done.

## Module 3.2 — Student-Facing Reads

### Feature: My enrollments endpoint

* [ ] `GET /api/me/enrollments?termId=` scoped to the caller's `UserId`
* [ ] Return offering + course + term details as DTOs
* [ ] Ensure a student can only see their own enrollments

Completion: 0/3

- **Objective:** Let a student fetch their own classes.
- **Expected outcome:** The endpoint returns only the caller's enrollments.
- **Knowledge to learn:** Scoping queries to the JWT's user, joins to offering/course/term.
- **Dependency:** Enrollments populated.

### Feature: Timetable endpoint

* [ ] `GET /api/me/timetable?termId=` returning a schedule-shaped view
* [ ] Group by day/time (use offering metadata available now)
* [ ] Return DTOs only

Completion: 0/3

- **Objective:** Provide a read-only timetable.
- **Expected outcome:** A student's term schedule is returned.
- **Knowledge to learn:** Shaping data for a timetable view.
- **Dependency:** My-enrollments endpoint done.

### Feature: Lecturer roster endpoint

* [ ] `GET /api/offerings/{id}/enrollments` for the assigned lecturer
* [ ] Authorize: only the offering's lecturer (or staff) may view
* [ ] Return enrolled students as DTOs

Completion: 0/3

- **Objective:** Let a lecturer see who is in their offering.
- **Expected outcome:** The assigned lecturer sees the roster; others are rejected.
- **Knowledge to learn:** Resource-based authorization (caller owns the offering).
- **Dependency:** Enrollments populated; lecturer assignment (2.4) done.

## Module 3.3 — Flutter Screens

### Feature: My Courses & Timetable UI

* [ ] "My Courses" list screen for the term
* [ ] "My Timetable" schedule screen
* [ ] Term selector

Completion: 0/3

- **Objective:** Show students their classes and schedule.
- **Expected outcome:** A logged-in student sees their courses and timetable.
- **Knowledge to learn:** Flutter list/calendar layouts, query parameters.
- **Dependency:** Student-facing endpoints done.

### Feature: Lecturer roster UI

* [ ] Offering list for the lecturer
* [ ] Roster screen per offering

Completion: 0/2

- **Objective:** Show lecturers their offerings and rosters.
- **Expected outcome:** A lecturer can open an offering and see its students.
- **Knowledge to learn:** Role-gated screens.
- **Dependency:** Roster endpoint done.

## Definition of Done — Phase 3

* [ ] Enrollment data source decided and documented.
* [ ] Import populates `Enrollments` with duplicate protection and retake support.
* [ ] A student sees only their own enrollments and timetable.
* [ ] The assigned lecturer sees their offering rosters; others are blocked.
* [ ] Flutter shows "My Courses", "My Timetable", and lecturer rosters.
* [ ] **Milestone: a real student-facing product (log in → see my classes) works end to end.**

---

# Phase 4 — Attendance

> **Goal:** A lecturer opens an attendance session for an offering; students check in via a short-lived QR code with GPS verification; records attach to the student's `Enrollment` so attendance becomes part of academic history. **Design pass first** (this module was not yet designed). Build the happy path before policy variations.

## Module 4.0 — Design Pass (no code)

### Feature: Attendance design document

* [ ] Define `AttendanceSessions` (belongs to a CourseOffering) columns
* [ ] Define `AttendanceRecords` (ties to an Enrollment) columns + status values
* [ ] Define the QR token lifecycle (issue, rotate, expire)
* [ ] Define GPS verification rules (allowed radius, what to store)
* [ ] Note future `AttendancePolicies` (per faculty/major/class) — not built in v1

Completion: 0/5

- **Objective:** Analyze before coding, per the project's working method.
- **Expected outcome:** An agreed mini-design for attendance tables and flows.
- **Knowledge to learn:** Designing a feature end to end (entities, flow, security, edge cases).
- **Dependency:** Phase 3 (records attach to enrollments).

### Feature: Add attendance tables to a migration

* [ ] Add `AttendanceSessions` (BIGINT key) referencing `CourseOfferings`
* [ ] Add `AttendanceRecords` (BIGINT key) referencing `Enrollments`
* [ ] Create and apply the EF Core migration
* [ ] Verify the schema in SSMS

Completion: 0/4

- **Objective:** Extend the database for attendance.
- **Expected outcome:** New tables exist with correct keys and FKs.
- **Knowledge to learn:** EF Core migrations (code-first additions to an existing DB).
- **Dependency:** Attendance design done.

## Module 4.1 — Session Management (Lecturer)

### Feature: Open/close attendance session

* [ ] `POST /api/offerings/{id}/sessions` (assigned lecturer only)
* [ ] `POST /api/sessions/{id}/close`
* [ ] Store session start/end and the offering link

Completion: 0/3

- **Objective:** Let a lecturer start and stop attendance for a class meeting.
- **Expected outcome:** Sessions open/close and are tied to the offering.
- **Knowledge to learn:** Resource-based authorization, session lifecycle.
- **Dependency:** Attendance tables exist; lecturer assignment done.

### Feature: Rotating QR token

* [ ] Generate a short-lived signed token for the active session
* [ ] Rotate the token on a short interval (e.g. every few seconds)
* [ ] Endpoint for the lecturer screen to fetch the current token
* [ ] Reject expired tokens server-side

Completion: 0/4

- **Objective:** Defeat screenshot-sharing of a static QR.
- **Expected outcome:** The QR changes frequently; stale tokens are rejected.
- **Knowledge to learn:** Time-limited signed tokens, why rotation beats a static code.
- **Dependency:** Session open/close done.

## Module 4.2 — Check-In (Student)

### Feature: Check-in endpoint with GPS

* [ ] `POST /api/sessions/{id}/checkin` with QR token + GPS coordinates
* [ ] Validate the token is current and the session is open
* [ ] Validate the student is enrolled in the offering
* [ ] Validate GPS within the allowed radius (server-side)
* [ ] Create an `AttendanceRecord` tied to the `Enrollment`

Completion: 0/5

- **Objective:** Record a verified, present check-in.
- **Expected outcome:** Only enrolled, in-range students with a valid token are marked present.
- **Knowledge to learn:** Server-side GPS distance checks, anti-spoof basics, linking records to enrollment.
- **Dependency:** Rotating QR token + check that enrollment exists.

### Feature: Duplicate & edge handling

* [ ] Prevent double check-in for the same session
* [ ] Handle "session closed" and "not enrolled" gracefully
* [ ] Record late vs. on-time status if in scope

Completion: 0/3

- **Objective:** Make check-in robust to abuse and edge cases.
- **Expected outcome:** No duplicate records; clear errors for invalid attempts.
- **Knowledge to learn:** Idempotency, edge-case handling.
- **Dependency:** Check-in endpoint working.

## Module 4.3 — Attendance Views

### Feature: Roster attendance view (lecturer)

* [ ] `GET /api/sessions/{id}/roster` showing present/absent per enrolled student
* [ ] Authorize to the offering's lecturer/staff

Completion: 0/2

- **Objective:** Let lecturers see live attendance.
- **Expected outcome:** The lecturer sees who has checked in.
- **Knowledge to learn:** Joining enrollments with attendance records.
- **Dependency:** Check-in records exist.

## Module 4.4 — Flutter Screens

### Feature: Lecturer session + QR display

* [ ] Start/stop session screen
* [ ] Display the rotating QR (auto-refresh)
* [ ] Live roster view

Completion: 0/3

- **Objective:** Run a session from the app.
- **Expected outcome:** Lecturer opens a session and shows a refreshing QR.
- **Knowledge to learn:** QR rendering, periodic refresh, role-gated screens.
- **Dependency:** Session + QR endpoints done.

### Feature: Student scan & check-in

* [ ] Camera/QR scan screen (request camera permission)
* [ ] Capture GPS (request location permission)
* [ ] Submit check-in and show confirmation

Completion: 0/3

- **Objective:** Let students check in by scanning.
- **Expected outcome:** Scanning a valid QR in range marks the student present.
- **Knowledge to learn:** Flutter camera + location permissions, QR scanning packages.
- **Dependency:** Check-in endpoint done.

## Definition of Done — Phase 4

* [ ] Attendance design documented; tables added via migration.
* [ ] Lecturer can open/close sessions for their own offerings.
* [ ] QR rotates and expires; stale tokens rejected.
* [ ] Student check-in validates token, enrollment, and GPS, and creates a record tied to the enrollment.
* [ ] Duplicate check-ins prevented; edge cases handled.
* [ ] Lecturer sees a live attendance roster.
* [ ] Flutter supports lecturer QR display and student scan check-in.
* [ ] **Milestone: the flagship feature works end to end.**

---

# Phase 5 — Documents

> **Goal:** Store and share slides, PDFs, exams, and learning materials between students and lecturers, scoped to courses/offerings, with upload validation and access control.

## Module 5.0 — Design & Tables

### Feature: Document design + table migration

* [ ] Define a `Documents` table (owner, scope to course/offering, file metadata)
* [ ] Decide storage location (file system / blob storage) and store a path/reference, not the bytes, in SQL
* [ ] Create and apply the migration
* [ ] Verify schema in SSMS

Completion: 0/4

- **Objective:** Model documents and their scope.
- **Expected outcome:** A `Documents` table exists with scope and metadata.
- **Knowledge to learn:** Storing files outside the DB, metadata modeling.
- **Dependency:** Phase 2 (courses/offerings to scope to); Phase 1 (ownership/auth).

## Module 5.1 — Upload & Download

### Feature: Upload endpoint with validation

* [ ] `POST /api/documents` accepting a file + scope
* [ ] Validate file type and size (allowlist)
* [ ] Store the file; persist metadata
* [ ] Authorize: lecturers/staff upload to their offerings

Completion: 0/4

- **Objective:** Safely accept uploads.
- **Expected outcome:** Valid files upload; disallowed types/sizes rejected.
- **Knowledge to learn:** File-upload handling, validation allowlists, security of uploads.
- **Dependency:** Documents table exists.

### Feature: Download / access-controlled fetch

* [ ] `GET /api/documents/{id}` enforcing access scope
* [ ] Only users in the document's course/offering scope may fetch
* [ ] Stream the file to the client

Completion: 0/3

- **Objective:** Serve documents to authorized users only.
- **Expected outcome:** In-scope users download; others are blocked.
- **Knowledge to learn:** Access-scoped authorization, file streaming.
- **Dependency:** Upload endpoint done.

### Feature: List & manage documents

* [ ] List documents by course/offering
* [ ] Soft-delete a document (owner/staff)

Completion: 0/2

- **Objective:** Browse and manage materials.
- **Expected outcome:** Documents listed per scope; removable by owner/staff.
- **Knowledge to learn:** Scoped listing, ownership checks.
- **Dependency:** Upload/download done.

## Module 5.2 — Flutter Screens

### Feature: Documents UI

* [ ] Document list per course/offering
* [ ] Upload screen (lecturer/staff)
* [ ] Open/download a document

Completion: 0/3

- **Objective:** Manage documents from the app.
- **Expected outcome:** Users browse, upload (if permitted), and open documents.
- **Knowledge to learn:** Flutter file picking, downloads, role-gated UI.
- **Dependency:** Document endpoints done.

## Definition of Done — Phase 5

* [ ] Documents table exists; files stored outside SQL with metadata persisted.
* [ ] Upload validates type/size and is authorized by scope.
* [ ] Download enforces access scope.
* [ ] Documents listable per course/offering and soft-deletable by owner/staff.
* [ ] Flutter supports browse, upload, and open.

---

# Phase 6 — Notification

> **Goal:** Notify users of schedule changes, events, tuition, and deadlines. A cross-cutting consumer of events from other modules. Build storage + a "my notifications" feed first; real-time push later.

## Module 6.0 — Design & Tables

### Feature: Notification design + migration

* [ ] Define a `Notifications` table (recipient, type, payload, read flag, timestamp)
* [ ] Decide notification types (schedule change, deadline, event, tuition)
* [ ] Create and apply the migration
* [ ] Verify schema in SSMS

Completion: 0/4

- **Objective:** Model stored notifications.
- **Expected outcome:** A `Notifications` table exists.
- **Knowledge to learn:** Event/notification modeling, read-state tracking.
- **Dependency:** Phase 1 (recipients/auth); later phases emit events.

## Module 6.1 — Create & Read

### Feature: Emit notifications from services

* [ ] A reusable `NotificationService.Create(...)` method
* [ ] Call it from at least one real event (e.g. offering change)
* [ ] Store per-recipient rows

Completion: 0/3

- **Objective:** Generate notifications from real events.
- **Expected outcome:** Actions in other modules produce notification rows.
- **Knowledge to learn:** Cross-cutting service usage, decoupling producers from delivery.
- **Dependency:** Notifications table exists.

### Feature: Notification feed endpoints

* [ ] `GET /api/me/notifications` (caller's own, paged)
* [ ] `POST /api/me/notifications/{id}/read` (mark read)
* [ ] Unread count endpoint

Completion: 0/3

- **Objective:** Let users read and manage notifications.
- **Expected outcome:** Users fetch their feed and mark items read.
- **Knowledge to learn:** Per-user scoping, read-state updates, pagination.
- **Dependency:** Emit-notifications done.

## Module 6.2 — Flutter & (Optional) Push

### Feature: Notification UI

* [ ] Notification list screen with read/unread state
* [ ] Unread badge
* [ ] Mark-as-read interaction

Completion: 0/3

- **Objective:** Surface notifications in the app.
- **Expected outcome:** Users see and manage notifications.
- **Knowledge to learn:** Flutter list state, badges.
- **Dependency:** Feed endpoints done.

### Feature: Real-time/push (optional, later)

* [ ] Evaluate push (e.g. Firebase Cloud Messaging) or polling
* [ ] Implement the chosen delivery channel
* [ ] Handle device token registration if using push

Completion: 0/3

- **Objective:** Deliver notifications proactively (optional enhancement).
- **Expected outcome:** Users receive notifications without manual refresh.
- **Knowledge to learn:** Push messaging or polling strategies.
- **Dependency:** Notification feed working.

## Definition of Done — Phase 6

* [ ] Notifications table exists; recipients and read-state modeled.
* [ ] At least one real event emits notifications.
* [ ] Users fetch their feed, see unread counts, and mark items read.
* [ ] Flutter shows the feed with unread state.
* [ ] (Optional) A real-time/push channel is evaluated or implemented.

---

# Phase 7 — Analytics

> **Goal:** A read-only layer over enrollments and attendance — attendance statistics and academic-performance reporting for lecturers and departments. The schema already supports aggregating by AdminClass or by CourseOffering.

## Module 7.0 — Define Metrics

### Feature: Metric definitions

* [ ] List target metrics (attendance rate by offering, by admin class, by student)
* [ ] Define how each is computed from existing tables
* [ ] Decide aggregation grouping options
* [ ] Document the definitions

Completion: 0/4

- **Objective:** Agree what to measure before building queries.
- **Expected outcome:** A clear list of metrics and their formulas.
- **Knowledge to learn:** Turning questions into aggregate queries.
- **Dependency:** Phases 3 & 4 (enrollment + attendance data exist).

## Module 7.1 — Aggregation Endpoints

### Feature: Attendance statistics

* [ ] Attendance rate per offering
* [ ] Attendance rate per admin class (join Enrollment → StudentProfile → AdminClass)
* [ ] Per-student attendance summary
* [ ] Authorize by role/scope (lecturer sees own; staff sees department)

Completion: 0/4

- **Objective:** Compute attendance analytics.
- **Expected outcome:** Endpoints return correct attendance aggregates.
- **Knowledge to learn:** GROUP BY aggregation in EF Core, dual aggregation paths.
- **Dependency:** Attendance records exist; metrics defined.

### Feature: Performance/reporting endpoints

* [ ] Enrollment/completion summaries per offering or class
* [ ] Department-level rollups
* [ ] Export-friendly response shape (for later CSV/report use)

Completion: 0/3

- **Objective:** Provide reporting aggregates.
- **Expected outcome:** Reporting endpoints return rollups by the chosen groupings.
- **Knowledge to learn:** Multi-level aggregation, report-shaped DTOs.
- **Dependency:** Attendance statistics done.

## Module 7.2 — Flutter Dashboards

### Feature: Analytics UI

* [ ] Attendance dashboard (charts) for lecturers
* [ ] Department/class rollup view for staff
* [ ] Filters by term/offering/class

Completion: 0/3

- **Objective:** Visualize analytics.
- **Expected outcome:** Lecturers/staff see attendance and reporting charts.
- **Knowledge to learn:** Flutter charting, dashboard layout, role-gated views.
- **Dependency:** Aggregation endpoints done.

## Definition of Done — Phase 7

* [ ] Metrics defined and documented.
* [ ] Attendance aggregates correct by offering, admin class, and student.
* [ ] Reporting rollups available at department/class level.
* [ ] Endpoints authorized by role/scope.
* [ ] Flutter dashboards display the analytics.

---

# Phase 8 — AI Assistant

> **Goal:** An assistant that answers questions about the university, searches schedules/exams/materials, and chats with PDFs and university documents. It sits on top of everything else and consumes data that must already exist locally — so it is built last.

## Module 8.0 — Scope & Design

### Feature: Assistant scope definition

* [ ] List supported question types (schedule, exams, materials, documents, general info)
* [ ] Decide the AI provider/integration approach
* [ ] Define which local data the assistant may read and the access rules
* [ ] Document privacy/security constraints (no leaking other users' data)

Completion: 0/4

- **Objective:** Bound the assistant before building it.
- **Expected outcome:** A documented scope and integration plan.
- **Knowledge to learn:** LLM integration basics, retrieval over your own data, privacy scoping.
- **Dependency:** Phases 2–7 (the data it answers over must exist).

## Module 8.1 — Retrieval Layer

### Feature: Query the platform's own data

* [ ] Build internal query functions the assistant can call (my schedule, my exams, materials)
* [ ] Enforce that results are scoped to the requesting user
* [ ] Return structured results the assistant can phrase

Completion: 0/3

- **Objective:** Let the assistant fetch real, user-scoped data.
- **Expected outcome:** The assistant can retrieve a user's schedule/exams/materials safely.
- **Knowledge to learn:** Tool/function-style retrieval, strict per-user scoping.
- **Dependency:** Schedule/document/analytics endpoints exist.

### Feature: Chat with PDFs/documents

* [ ] Extract text from in-scope documents
* [ ] Index/prepare documents for question answering
* [ ] Answer questions grounded in the document, respecting access scope

Completion: 0/3

- **Objective:** Enable document Q&A.
- **Expected outcome:** Users can ask questions about documents they may access.
- **Knowledge to learn:** Text extraction, retrieval-augmented answering, grounding.
- **Dependency:** Documents (Phase 5) exist; retrieval layer done.

## Module 8.2 — Assistant Endpoint & UI

### Feature: Assistant API

* [ ] `POST /api/assistant/ask` taking a question + user context
* [ ] Route to retrieval + the AI provider
* [ ] Enforce access scope on every answer
* [ ] Return the answer with any source references

Completion: 0/4

- **Objective:** Expose the assistant over HTTP.
- **Expected outcome:** Authorized users get scoped, grounded answers.
- **Knowledge to learn:** Orchestrating retrieval + generation, safe responses.
- **Dependency:** Retrieval + document Q&A done.

### Feature: Assistant chat UI

* [ ] Chat screen in Flutter
* [ ] Send questions, render answers
* [ ] Show sources/links where available

Completion: 0/3

- **Objective:** Let users chat with the assistant.
- **Expected outcome:** A working in-app chat against the assistant API.
- **Knowledge to learn:** Flutter chat UI, streaming or request/response handling.
- **Dependency:** Assistant API done.

## Definition of Done — Phase 8

* [ ] Assistant scope, provider, and privacy rules documented.
* [ ] Retrieval functions return strictly user-scoped data.
* [ ] Document Q&A works within access scope.
* [ ] Assistant endpoint enforces scope and returns grounded answers.
* [ ] Flutter chat UI works end to end.

---

# Progress Tracking

> Update this section as you complete tasks. "Tasks" below counts the **feature tasks** (the `* [ ]` items under each Feature), not the Definition-of-Done checklist items. Recompute the percentage as `completed / total`.

## Task Counts Per Phase

| Phase | Total Tasks | Completed | % |
|---|---|---|---|
| Phase 0 — Project Foundation | 26 | 26 | 100% |
| Phase 1 — Authentication | 57 | 41 | 72% |
| Phase 2 — Academic Structure | 68 | 30 | 44% |
| Phase 3 — Enrollment & Timetable | 26 | 0 | 0% |
| Phase 4 — Attendance | 32 | 0 | 0% |
| Phase 5 — Documents | 16 | 0 | 0% |
| Phase 6 — Notification | 16 | 0 | 0% |
| Phase 7 — Analytics | 14 | 0 | 0% |
| Phase 8 — AI Assistant | 17 | 0 | 0% |
| **Project Total** | **272** | **97** | **36%** |

## Overall Progress

```
Phase 0: 100% (26/26)
Phase 1: 72%  (41/57)
Phase 2: 44%  (30/68)
Phase 3: 0%   (0/26)
Phase 4: 0%   (0/32)
Phase 5: 0%   (0/16)
Phase 6: 0%   (0/16)
Phase 7: 0%   (0/14)
Phase 8: 0%   (0/17)
Project Total: 36%   (97/272)
```

## Milestones

- **End of Phase 0** — Full pipeline proven (Flutter → API → SQL Server).
- **End of Phase 1** — Secure login, JWT, refresh, and role-based access working.
- **End of Phase 3** — First shippable product: log in and see your classes/timetable.
- **End of Phase 4** — Flagship feature: QR + GPS attendance working.
- **End of Phase 8** — Full platform with AI assistant.

## How To Update Progress

1. When you finish a task, change `* [ ]` to `* [x]`.
2. Update that feature's `Completion: x/n` line.
3. When a phase's feature tasks are all done, set its row in the table and the Overall Progress block.
4. Recompute `Project Total` as completed ÷ 272.
5. Only tick a **Definition of Done** item when its condition is genuinely true — that is the gate for moving to the next phase.

---

## Dependency Summary (Build Order)

```
Phase 0 (Foundation)
   └─ gates everything
Phase 1 (Authentication)
   └─ gates every feature endpoint
Phase 2 (Academic Structure)
   ├─ AcademicTerm ← University
   ├─ Major ← Faculty ← University
   ├─ Program ← Major
   ├─ Course ← University (owner: Department/Faculty)
   ├─ AdminClass ← Program
   ├─ StudentProfile ← AdminClass
   ├─ LecturerProfile ← Department/Faculty
   └─ CourseOffering ← Course + AcademicTerm + LecturerProfile
Phase 3 (Enrollment)
   └─ Enrollment ← CourseOffering (student ↔ offering)
Phase 4 (Attendance)
   ├─ AttendanceSession ← CourseOffering
   └─ AttendanceRecord ← Enrollment
Phase 5 (Documents)        ← scoped to Course/Offering
Phase 6 (Notification)     ← consumes events from other phases
Phase 7 (Analytics)        ← reads Enrollment + Attendance
Phase 8 (AI Assistant)     ← reads everything; built last
```

**Why order matters:** building a phase before its dependency means foreign keys can't resolve (you literally can't insert valid rows), or you retrofit security/joins into code not built for them, or you build query layers over empty tables. Follow the order top to bottom.

---

*End of ROADMAP_PROJECT.md*
