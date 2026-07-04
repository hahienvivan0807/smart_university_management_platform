# Smart University Management Platform — Project Handover Document (English)

**Document type:** Official project handover / technical design record
**Audience:** A new AI session or development team continuing this project
**Status of project:** Foundation (Identity + Organizational/Academic Structure) designed and expressed as a runnable SQL Server schema. No application code yet (EF Core, DTOs, services, controllers, Flutter).
**Most important design update:** **Enrollment moved from "import" to "Student self-service Course Registration"** with a **queue + database-level integrity guarantee + waitlist**. See [Section 11.2](#112-course-registration-decided) and [Section 16](#16-registration--concurrency-design-decided).

---

## Table of Contents

1. [How to Use This Document](#1-how-to-use-this-document)
2. [Project Objectives](#2-project-objectives)
3. [System Scope](#3-system-scope)
4. [Overall Architecture](#4-overall-architecture)
5. [Decision Status Legend](#5-decision-status-legend)
6. [Authentication & Authorization Design](#6-authentication--authorization-design)
7. [Organizational & Academic Structure](#7-organizational--academic-structure)
8. [Database Design Decisions](#8-database-design-decisions)
9. [Complete Table Catalog](#9-complete-table-catalog)
10. [Key Business Rules](#10-key-business-rules)
11. [Attendance & Registration/Schedule Design](#11-attendance--registrationschedule-design)
12. [Other Planned Modules](#12-other-planned-modules)
13. [Open Questions / Under Consideration](#13-open-questions--under-consideration)
14. [Context For New AI Session](#14-context-for-new-ai-session)
15. [Next Recommended Development Steps](#15-next-recommended-development-steps)
16. [Registration & Concurrency Design](#16-registration--concurrency-design-decided)
17. [Appendix A: Working Process Agreement](#appendix-a-working-process-agreement)

---

## 1. How to Use This Document

This is a self-contained technical record. A new AI session or developer can read it and continue building without prior conversation history. Sections 2–13 describe reasoning and decisions. **Section 14 ("Context For New AI Session") is a condensed, code-ready specification** — if you read only one section before coding, read that. Section 15 says what to build next and in what order. **Section 16 is new** and fully specifies the course-registration engine and concurrency handling.

Each design point is tagged DECIDED, UNDER CONSIDERATION, or NOT YET DESIGNED (see [Section 5](#5-decision-status-legend)).

---

## 2. Project Objectives

The **Smart University Management Platform** is a Smart Campus management system whose purpose is to manage and support all academic activity on one platform.

**Target users:** Students, Lecturers, Departments, Academic offices, Administrators.

**Primary goal:** centralize and support academic activity — scheduling, **course registration**, attendance, documents, notifications, analytics, and an AI assistant — in one coherent platform.

**Secondary goal (owner's personal goal):** the owner uses AI both to accelerate development and to learn software-engineering best practices. The working method therefore **prioritizes system design and data-flow understanding over fast code generation**. Every feature is fully analyzed (goal, user flow, data flow, entities, tables, normalization, dependencies, security, edge cases, future growth) **before** code is written. See [Appendix A](#appendix-a-working-process-agreement).

---

## 3. System Scope

### Planned modules

1. **Authentication** — Account provisioning (Admin/AcademicOffice only — no public self-registration), Login, Authorization.
2. **Course Registration** — students self-register into course offerings each term, with capacity control and concurrency handling. **(NEW — DECIDED)**
3. **Todo & Schedule** — personal tasks, study/teaching schedules, deadline reminders.
4. **Attendance** — dynamic QR codes, GPS verification, per-faculty/major/class policies.
5. **AI Assistant** — answer university questions, search schedules/exams/materials, chat with PDFs and university documents.
6. **Document Management** — store/share slides, PDFs, exams, materials.
7. **Notification System** — schedule changes, events, tuition, deadlines.
8. **Analytics** — attendance statistics, performance analysis, reporting.

### Technology stack (DECIDED)

- **Backend:** ASP.NET Core Web API, C#, Entity Framework Core, SQL Server.
- **Frontend:** Flutter.
- **DB tooling:** SSMS. Foundation schema authored as raw SQL DDL, run first; EF Core models written to match.

### Tenancy scope (DECIDED)

- Serves **one university** now. A `UniversityId` column is present from day one on tenant-relevant tables so a future multi-tenant SaaS migration needs no structural redesign.

---

## 4. Overall Architecture

**Pattern (DECIDED in principle):** Layered, idiomatic ASP.NET Core:

```
Flutter client
      │  (HTTPS, JWT in Authorization header)
      ▼
Controller  (HTTP boundary, model binding, returns DTOs)
      ▼
Service     (business logic, validation, authorization policies)
      ▼
DbContext / Repository (EF Core)
      ▼
SQL Server  (system of record for this platform's data)
```

**Canonical data flow:** `User → Screen (Flutter) → API (Controller) → Service → Database`.

**Architectural principle (UPDATED — DECIDED):** distinguish a *system of record* from a *system of engagement*. **For course registration, the platform is now a system of record** — it owns the registration engine, capacity, and concurrency logic, rather than merely reading registration data from an external system as originally leaned. This is the central architectural change of this update.

---

## 5. Decision Status Legend

| Tag | Meaning |
|---|---|
| **DECIDED** | Agreed and stable. Safe to build against. |
| **UNDER CONSIDERATION** | Discussed; a leaning exists, not finalized. Do not hard-code irreversibly. |
| **NOT YET DESIGNED** | Needed but not yet analyzed. Requires a design pass first. |

---

## 6. Authentication & Authorization Design

### 6.1 Identity model (DECIDED)
- **One `User` per person**, across roles. Role-specific data lives in 1:1 profile tables (`StudentProfiles`, `LecturerProfiles`).

### 6.2 Login identifier (DECIDED)
- Login by institutional **`LoginCode`**, not email. Email optional (recovery/notifications). `UNIQUE (UniversityId, LoginCode)`. Never derive role by parsing the code.

### 6.3 Roles & authorization (DECIDED)
- Roles: `Student`, `Lecturer`, `DepartmentStaff`, `AcademicOffice`, `Admin`. `UserRoles` is M:N. Authorization always reads real roles via policy-based authorization; never the UI's selected role.

### 6.4 Password security (DECIDED)
- Salted slow hash (PBKDF2/BCrypt/Argon2). `MustChangePassword`, `FailedLoginCount`, `LockoutEndUtc`.

### 6.5 JWT strategy (DECIDED — "B1")
- Short-lived access token carrying `UserId` + **all real roles**; no single active-role claim. Refresh token stored as hash, rotated on use, family-revoked on reuse, multi-device allowed.

### 6.6 Login flow (DECIDED)
```
User → Login (Flutter): LoginCode + password
  → POST /api/auth/login → AuthController → AuthService
  → verify credentials/hash, load roles from UserRoles
  → issue JWT (all real roles) + refresh token; persist hashed refresh token
  → { accessToken, refreshToken, roles[], requiresRoleSelection = roles.Count > 1 }
```
- Enumeration-resistant generic failures.

### 6.7 Multi-role flow (DECIDED)
- Single-role → routed directly. Multi-role → role picker. **Selected role is UX context only**, never authorization. *Selecting a role is a UX step, not a security boundary.*

### 6.8 Auth security requirements (DECIDED)
- Policy-based authorization, JWT handling, password hashing, input/DTO validation, rate limiting on `/login` `/register` `/refresh` (per IP and per account), audit logging, HTTPS, hashes never returned, enumeration resistance.

### 6.9 Account provisioning (DECIDED)
- Accounts are **provisioned, not self-registered**. Students and lecturers cannot create their own login. Only `Admin`/`AcademicOffice` roles may create an account, via `POST /api/auth/register`, gated by policy-based authorization — this endpoint is never public.
- A provisioned account gets an institution-issued `LoginCode` (never user-chosen) and a temporary password; `MustChangePassword = true` is set so the first login forces a change.
- Two creation paths share this rule: bulk seed/import (Module 1.1, e.g. onboarding a new cohort) and one-off API provisioning (this endpoint, e.g. a late add). Same constraint either way — no path lets a user create their own login.
- **Naming clash to be aware of:** "registration" means two unrelated things in this document — *account* registration (closed, admin-only, this section) and *course* registration (open, student self-service, §16). Do not conflate them; they have opposite access models.

### 6.10 Bulk account provisioning via Excel import (UNDER CONSIDERATION)
- **Problem:** onboarding an incoming cohort (hundreds of students per intake) one account at a time through the single-record provisioning form (§6.9) does not scale operationally.
- **Proposed mechanism:** staff uploads a spreadsheet (MSSV/LoginCode, full name, date of birth, major/admin-class code, optional email); the system parses and validates every row (required columns, MSSV format, referenced major/admin-class exists, no duplicate LoginCode) and shows a **preview with per-row errors before committing anything** — no silent partial imports. On confirmation, each valid row goes through the *same* account-creation + student-profile-creation path already used for a single student (§6.9's `RegisterAsync`, plus `ProfileService`'s student-profile creation), just looped, with a per-row success/fail report at the end.
- **Default password = date of birth** (fixed format, e.g. `ddMMyyyy`). This is a knowingly guessable default — it is only acceptable *because* it is paired with the existing `MustChangePassword = true` forced-change-on-first-login mechanism (§6.9). Do not reuse this default-password pattern anywhere `MustChangePassword` is not also enforced.
- **Why "under consideration" and not "decided":** the column layout, the exact library/approach for parsing the spreadsheet, and where the endpoint lives (a dedicated API endpoint vs. calling the same services directly from the Blazor admin portal, which already has direct DI access to `IAuthService`/`ProfileService`) are not yet finalized. See `ROADMAP_PROJECT.md` Module 1.4 for the task breakdown.
- **Relationship to existing decisions:** this is additive to §6.9, not a replacement — it is the "bulk seed/import" path already named in §6.9's third bullet, now specified concretely (Excel-driven, staff-triggered, not the DB-seed-script bootstrap of Module 1.1).

---

## 7. Organizational & Academic Structure

The **backbone**. Central philosophy: **THREE SEPARATE TREES**, never conflated.

### 7.1 The three trees (DECIDED)

- **Tree A — Institutional:** `University → Faculty → Department` (Department optional, nullable FK + faculty fallback).
- **Tree B — Catalog (stable, reusable, term-independent):** `Major → Program → Course` + `ProgramCourses`, `CoursePrerequisites` (self-ref).
- **Tree C — Time-based offerings (high volume, per term):** `AcademicTerm → CourseOffering`; `AdminClass`; `Enrollment`.

### 7.2 Two resolved ambiguities (DECIDED)

1. **Catalog vs. offering.** A `Course` is defined once, offered many times as `CourseOffering`.
2. **Administrative class vs. course section.** `AdminClass` (durable cohort, e.g. "DH21IT01") and `CourseOffering` (per-term teaching group) are separate tables. **IMPORTANT for this change:** moving to student self-registration does **not** remove `AdminClass`. AdminClass remains the management cohort; students self-register into `CourseOffering`s, producing `Enrollment` rows. The two concepts are independent and complementary.

### 7.3 Entity decisions (all DECIDED)
- University (tenant root); Faculty; Department (optional); Major; Program (curriculum-versioning mechanism); Course (reusable, credit count); ProgramCourses; CoursePrerequisites (CK: not self); AcademicTerm; AdminClass (cohort under a Program); **CourseOffering** (one Course in one Term, exactly one lecturer, with `Capacity` and `Status`; the unit students register into and attendance/schedule attach to); **Enrollment** (a student's registration in a CourseOffering; grades/attendance attach here, never to AdminClass).

### 7.4 Profile links (DECIDED)
- `StudentProfiles.AdminClassId` → AdminClass (required). `LecturerProfiles.DepartmentId` → Department (nullable; `FacultyId` fallback).

### 7.5 Lecturer assignment (DECIDED)
- Exactly one main lecturer per offering (`CourseOfferings.LecturerUserId`). A lecturer may own many offerings. Future: promote to `OfferingInstructors` if team teaching is needed.

### 7.6 Retake logic (DECIDED — critical)
- Retake the same subject in different terms while preserving full history, enforced by `UNIQUE (StudentUserId, CourseOfferingId)` — uniqueness on **(Student, Offering)**, NOT (Student, Course). Prevents duplicate registration in the same offering; allows different offerings of the same course to coexist. **For the new registration engine:** this constraint is the final database-level guard against duplicate registration and must never be weakened.

---

## 8. Database Design Decisions

### 8.1 PK strategy (DECIDED)
- `INT IDENTITY` for stable tables; `BIGINT IDENTITY` for **Enrollments**, **RefreshTokens** (and future audit logs).

### 8.2 1:1 profiles (DECIDED)
- `StudentProfiles`/`LecturerProfiles` use a shared PK: `UserId` is both PK and FK to `Users`.

### 8.3 Soft delete (UNDER CONSIDERATION → partially DECIDED in principle)
- `IsActive` flags exist; prefer soft delete/archive for structural/history-bearing data. System-wide convention not yet finalized.

### 8.4 Audit (NOT YET DESIGNED — deferred)
- High-value targets: auth events, role/token changes, structural changes (offerings, lecturer reassignment, **capacity changes**). **Added for registration:** also audit register/drop events. No `AuditLogs` table yet; use `BIGINT` when designed.

### 8.5 Normalization & reuse (DECIDED)
- Roles separated from Users; catalog separated from per-term offerings; AdminClass separate from CourseOffering. **The new `SeatsTaken` column on `CourseOfferings` (see Section 16) is a deliberate denormalization** — to enable atomic seat counting without a `COUNT(*)` per registration.

---

## 9. Complete Table Catalog

> 18 foundation tables retained. Registration-related changes marked **[UPDATED]**.

### 9.1 Identity & sessions
- **`Users`** — PK `UserId` (INT). `LoginCode`, `PasswordHash`, `Email` (nullable), `MustChangePassword`, `FailedLoginCount`, `LockoutEndUtc`, `Status`, `LastActiveRoleId` (nullable). FK → `Universities`. UQ `(UniversityId, LoginCode)`.
- **`Roles`** — PK `RoleId` (INT).
- **`UserRoles`** — composite PK `(UserId, RoleId)`.
- **`RefreshTokens`** — PK `RefreshTokenId` (**BIGINT**). FK `UserId` → `Users` (CASCADE).

### 9.2 Institutional hierarchy
- **`Faculties`** — PK `FacultyId` (INT). FK → `Universities`. UQ `(UniversityId, Code)`.
- **`Departments`** — PK `DepartmentId` (INT). FK → `Faculties`. UQ `(FacultyId, Code)`.

### 9.3 Academic catalog
- **`Majors`** — PK `MajorId` (INT). FK → `Faculties`.
- **`Programs`** — PK `ProgramId` (INT). FK → `Majors`. `CurriculumYear`, `TotalCredits`.
- **`Courses`** — PK `CourseId` (INT). FK → `Universities`, `OwnerDepartmentId` (nullable), `OwnerFacultyId` (nullable). UQ `(UniversityId, Code)`. CK `Credits > 0`.
- **`ProgramCourses`** — composite PK `(ProgramId, CourseId)`.
- **`CoursePrerequisites`** — composite PK `(CourseId, PrerequisiteCourseId)`. CK `CourseId <> PrerequisiteCourseId`.

### 9.4 Profiles
- **`StudentProfiles`** — PK/FK `UserId`. FK `AdminClassId`. `IntakeYear`, `StudentStatus`.
- **`LecturerProfiles`** — PK/FK `UserId`. FK `DepartmentId` (nullable), `FacultyId` (fallback). `AcademicTitle`.

### 9.5 Time-based offerings
- **`AcademicTerms`** — PK `AcademicTermId` (INT). FK → `Universities`. UQ `(UniversityId, AcademicYear, TermNumber)`. CK `StartDate < EndDate`.
- **`AdminClasses`** — PK `AdminClassId` (INT). FK `ProgramId`, `AdvisorUserId` (nullable). UQ `(ProgramId, Code)`.
- **`CourseOfferings`** — **[UPDATED]** PK `CourseOfferingId` (INT). FK `CourseId`, `AcademicTermId`, `LecturerUserId`. UQ `(AcademicTermId, Code)`.
  - Existing: `Code`, `Capacity`, `Status` (1=Open, 2=Closed, 3=Cancelled).
  - **New `SeatsTaken` (INT NOT NULL DEFAULT 0)** — seats granted, for atomic capacity checks. Proposed CK: `SeatsTaken >= 0 AND (Capacity IS NULL OR SeatsTaken <= Capacity)`.
  - **New optional `RowVersion` (`rowversion`)** — optimistic concurrency fallback.
  - **New `RegistrationOpenAtUtc`, `RegistrationCloseAtUtc` (datetime2, nullable)** — registration time window.
- **`Enrollments`** — **[UPDATED]** PK `EnrollmentId` (**BIGINT**). FK `StudentUserId` → `StudentProfiles`, `CourseOfferingId` → `CourseOfferings`. **UQ `(StudentUserId, CourseOfferingId)`.**
  - `EnrolledAtUtc`, `Status`.
  - **Extended Status:** 1=Enrolled, 2=Dropped, 3=Completed, 4=Failed, **5=Pending (queued for processing), 6=Waitlisted**.
  - **New optional `WaitlistPosition` (INT, nullable)**.

### 9.6 Textual ER summary
```
Universities 1───* Faculties 1───* Departments
Faculties 1───* Majors 1───* Programs
Programs *───* Courses           (via ProgramCourses)
Courses  *───* Courses           (via CoursePrerequisites, self-ref)
Programs 1───* AdminClasses
Courses 1───* CourseOfferings *──1 AcademicTerms
LecturerProfiles 1───* CourseOfferings
StudentProfiles *───* CourseOfferings   (via Enrollments; UNIQUE per (student, offering))
```

---

## 10. Key Business Rules

1. One identity per person; roles via `UserRoles`; authorization from real roles. (DECIDED)
2. One lecturer, many offerings. (DECIDED)
3. Retake: re-register in a different `CourseOffering` of the same `Course` in a later term. (DECIDED)
4. Academic history = all `Enrollment`s whose offering's `CourseId` matches, ordered by term. (DECIDED)
5. AdminClass ≠ CourseOffering. (DECIDED)
6. Enrollment uniqueness `(StudentUserId, CourseOfferingId)` — the final guard against duplicate registration. (DECIDED)
7. **[NEW] No overselling.** An offering is never granted beyond `Capacity`, guaranteed by an atomic DB check under concurrency (Section 16). (DECIDED)
8. **[NEW] Registration time gate.** Registration accepted only when `Status = Open` and now is within `[RegistrationOpenAtUtc, RegistrationCloseAtUtc]` if configured. (DECIDED)
9. **[NEW] No public account self-registration.** Login credentials are provisioned only by `Admin`/`AcademicOffice` (seed or `POST /api/auth/register`, both admin-gated). The only thing a student self-registers for is *course enrollment* — never their own account. (DECIDED)

---

## 11. Attendance & Registration/Schedule Design

### 11.1 Attendance (NOT YET DESIGNED, direction set)
- Sessions belong to a `CourseOffering`; records ultimately tie to `Enrollment`. Security noted: GPS spoofing prevention, dynamic QR expiry, audit logging. No attendance tables yet.

### 11.2 Course Registration (DECIDED)

> **This is the central architectural change.** The earlier lean ("platform only reads registration data from the university's system") is **replaced**.

- **Decision:** the platform **implements its own course-registration engine**. Students self-register into `CourseOffering`s each term. The API enforces capacity and duplicate rules.
- **Concurrency problem:** when registration opens, many requests contend for the last seats. To guarantee integrity (no overselling), registration requests are **queued and processed serially per offering**, combined with an **atomic DB check** as the final guarantee.
- **Waitlist:** when an offering is full, a student may join the waitlist (Enrollment `Status = Waitlisted`). On a drop, the freed seat is granted to the next waitlisted student.
- **v1 scope:** enforce **capacity + duplicate protection + time gate** only. **No** prerequisite or schedule-conflict checks in v1 (deferred — see Section 13).
- The `Enrollments` table and its uniqueness/retake rules **remain valid** — only how rows are created changes (self-registration instead of import), plus waitlist statuses.

Full technical detail in [Section 16](#16-registration--concurrency-design-decided).

---

## 12. Other Planned Modules

| Module | Status | Notes |
|---|---|---|
| AI Assistant | NOT YET DESIGNED | Sits on top; queries schedules/exams/materials; PDF chat. |
| Document Management | NOT YET DESIGNED | Upload validation, permissions, scoped to course/offering. |
| Notification System | NOT YET DESIGNED | **Consumes registration/waitlist events** ("a seat is now yours"). |
| Analytics | NOT YET DESIGNED | Read-only over enrollment/attendance; dual aggregation. |
| Todo & Schedule | NOT YET DESIGNED | Personal tasks + schedules + reminders. |

---

## 13. Open Questions / Under Consideration

1. ~~Does the university expose registration/timetable data via API/export?~~ **RESOLVED:** the platform owns the registration engine (self-register + queue). External SIS sync is a future, non-breaking extension.
2. System-wide soft-delete convention (UNDER CONSIDERATION).
3. Audit log design (NOT YET DESIGNED) — should include registration and capacity-change events.
4. Role seed-data localization (minor).
5. Grade model (NOT YET DESIGNED).
6. Rooms/Buildings (NOT YET DESIGNED).
7. Fine-grained permissions (FUTURE).
8. **[NEW] Multi-instance concurrency scale-out** (UNDER CONSIDERATION). v1 uses an in-process `Channel` queue — correct only for a single API instance. Scaling out requires a **distributed lock (Redis RedLock)** or **message broker (RabbitMQ/Azure Service Bus)**, while keeping the atomic DB check as the integrity floor. Decide before multi-instance deployment.
9. **[NEW] Detailed waitlist policy** (UNDER CONSIDERATION). Seat-hold timeout when offered from waitlist; auto-expiry; ordering (FIFO vs. academic priority).
10. **[NEW] Bulk account provisioning via Excel import** (UNDER CONSIDERATION) — see §6.10. Column layout and exact endpoint shape not finalized; default-password-by-birthdate mechanism only acceptable paired with the existing forced-change-on-first-login rule.

---

## 14. Context For New AI Session

> **Self-contained, code-ready specification of the current design state.**

### 14.1 What to build
ASP.NET Core Web API (C#, EF Core, SQL Server) + Flutter client. Foundation schema exists (18 tables, schema `dbo`). Scaffold EF Core entities + DbContext to match exactly. Layered architecture; controllers return DTOs.

### 14.2 Identity & auth
Per Section 6: login by `LoginCode`, JWT carries all real roles, refresh token rotation/revocation, policy-based authorization. **Accounts are admin-provisioned only — no public signup (§6.9).**

### 14.3 Structural model
Per Section 7: three separate trees; AdminClass and CourseOffering distinct; 1:1 profiles via shared PK.

### 14.4 Invariants the code must preserve
- **Enrollment uniqueness `(StudentUserId, CourseOfferingId)`** — never weaken to (student, course).
- **One lecturer per CourseOffering.**
- **AdminClass and CourseOffering distinct;** grades/attendance attach to `Enrollment`.
- **Authorization from real roles only.**
- **PK types:** INT for stable; **BIGINT for Enrollments and RefreshTokens.**
- **`UniversityId`** present on tenant-relevant tables.
- **Soft delete in spirit.**
- **[NEW] Capacity enforced under concurrency** — never oversell the last seat; serialize contending registrations; atomic DB check.

### 14.5 Things NOT to do yet
- **[REVERSED]** ~~Do not build a registration engine.~~ → **Do build a registration engine**, limited to **capacity + duplicate protection + time gate + waitlist** with queue-based concurrency. **No** prerequisite or schedule-conflict checks in v1.
- Do not add grade columns to `Enrollments` (grade model pending).
- Do not add `AuditLogs` yet, but make registration events easy to emit later.
- Do not implement multi-instructor, `UserIdentifiers`, `Permissions`/`RolePermissions`, `Rooms`.

### 14.6 Foundation table list (authoritative)
`Universities, Roles, Users, UserRoles, RefreshTokens, Faculties, Departments, Majors, Programs, Courses, ProgramCourses, CoursePrerequisites, StudentProfiles, LecturerProfiles, AcademicTerms, AdminClasses, CourseOfferings, Enrollments`.
*(`CourseOfferings` and `Enrollments` are column-extended per Sections 9.5 and 16.)*

---

## 15. Next Recommended Development Steps

### 15.1 Completed (design-level)
- Auth & Identity; Organizational & Academic Structure; 18 foundation tables; INT/BIGINT strategy; JWT/refresh; multi-role login; retake/uniqueness; lecturer-assignment.
- **[NEW]** Registration + concurrency + waitlist design (Section 16).

### 15.2 Not yet designed
- Soft-delete convention; audit log; grade model; attendance; Documents, Notifications, Analytics, AI Assistant, Todo; Rooms/Buildings; fine-grained permissions.

### 15.3 Recommended coding order
1. Run/confirm the foundation SQL schema in SSMS.
2. Scaffold EF Core entities + DbContext to match exactly. **Add a migration for `SeatsTaken`, `RowVersion`, registration time window, and waitlist statuses.**
3. **Authentication first** (DTO → AuthService → AuthController).
4. **Structure management endpoints** (Academic-office/Admin): CRUD; assign students to AdminClasses; assign lecturers to offerings.
5. **[REPLACES the old import step] Registration engine:** self-register endpoint + queue (Channel) + atomic DB check + waitlist; read-only timetable endpoints. **This is the new core — see Section 16.**
6. **Audit log:** short design pass, add table, emit from auth + structure + **registration**.
7. **Attendance module:** design then build.
8. **Schedule/Todo, Notifications, Documents, Analytics, AI Assistant** in dependency order.

---

## 16. Registration & Concurrency Design (DECIDED)

> Full specification of the registration engine and concurrent-request handling. This is the core technical content of the update.

### 16.1 The problem
When registration opens, thousands of students may register simultaneously for popular offerings. A naive read-check-write (read seats → check availability → write) lets two requests both read "1 seat left" and both write → **overselling**. This is a classic race condition on a finite resource.

### 16.2 Chosen solution: Coordination queue + atomic DB guarantee
Two complementary layers:

**Layer 1 — Coordination queue (in-process):**
- Use `System.Threading.Channels` (`Channel<RegistrationRequest>`) as an in-process queue.
- One or more `BackgroundService` workers consume the queue and **process requests serially per `CourseOfferingId`** (partition/lock by offering). Serialization ensures only one request per offering is processed at a time.
- `POST /api/me/enrollments` enqueues a request and returns `202 Accepted` with a tracking id; the client polls for the result (or waits, if designed synchronously). The interim Enrollment status is `Pending`.

**Layer 2 — Atomic DB guarantee (the correctness floor):**
Even if the queue fails or the API later runs multiple instances, the DB must protect itself. Inside a transaction:

```sql
-- Atomically grant one seat; succeeds only if space remains
UPDATE CourseOfferings
SET SeatsTaken = SeatsTaken + 1
WHERE CourseOfferingId = @offeringId
  AND Status = 1                 -- Open
  AND SeatsTaken < Capacity;

-- If @@ROWCOUNT = 1 → seat granted → INSERT Enrollment (Status = 1 Enrolled)
-- If @@ROWCOUNT = 0 → full → INSERT Enrollment (Status = 6 Waitlisted) or reject
```

`UPDATE ... WHERE SeatsTaken < Capacity` is **row-level atomic** in SQL Server, so two requests can never both win the last seat. The `INSERT` relies on `UNIQUE (StudentUserId, CourseOfferingId)` to block duplicate registration (catch the unique violation and return "already registered").

> **Why both layers?** Layer 1 gives a clear "queue" concept to demonstrate and smooths the load spike. Layer 2 is the mathematical guarantee that data is never wrong, even if Layer 1 is bypassed. In a correct architecture, **integrity never depends on the queue alone** — it is anchored at the data layer.

### 16.3 Registration flow (happy path + waitlist)
```
Student → "Course Registration" screen (Flutter): pick offering, tap Register
  → POST /api/me/enrollments { courseOfferingId }
  → Controller verifies JWT (Student role), validates input
  → Service: pre-check (offering Open? within time gate? not already registered?)
  → Enqueue RegistrationRequest; create Enrollment Status = Pending; return 202 + trackingId
  → Worker (BackgroundService) takes request per offering, opens a transaction:
       • atomic UPDATE SeatsTaken
       • @@ROWCOUNT = 1 → Enrollment.Status = Enrolled
       • @@ROWCOUNT = 0 → Enrollment.Status = Waitlisted, set WaitlistPosition
       • commit
  → Client polls GET /api/me/enrollments/{trackingId} for the final result
```

**Drop / release a seat:**
```
Student → POST /api/me/enrollments/{id}/drop
  → transaction: Enrollment.Status = Dropped; UPDATE SeatsTaken = SeatsTaken - 1
  → if any Waitlisted: grant the seat to the first in line (Status → Enrolled),
    emit an event for Notification ("a seat is now yours")
```

### 16.4 Options considered (and why)

| Option | Description | Verdict |
|---|---|---|
| **DB conditional UPDATE** | `UPDATE ... WHERE SeatsTaken < Capacity` in a transaction | Simple, correct, no extra infra. **Chosen as the guarantee (Layer 2).** |
| **Optimistic concurrency (`rowversion`)** | EF Core throws `DbUpdateConcurrencyException`; retry | Good when conflicts are rare; kept as fallback. |
| **In-process queue (`Channel` + `BackgroundService`)** | Serialize per offering in-process | **Chosen as the coordinator (Layer 1).** Correct only for a single instance. |
| **Distributed lock / Message Queue** | Redis RedLock, RabbitMQ, Azure Service Bus | Right for multi-instance production. **Too heavy for v1** → future direction (13.8). |

### 16.5 Edge cases to handle
- **Duplicate in same offering** → `UNIQUE` violation → clear "already registered".
- **Retake** → registering in a *different* offering of the same course is allowed (no unique violation).
- **Offering closed/cancelled mid-flight** → checked via `Status = Open` inside the atomic UPDATE.
- **Outside the time gate** → rejected at pre-check and re-checked in the transaction.
- **Drop then grant to waitlist** → must be atomic so one seat isn't granted to two people.
- **`Capacity = NULL`** (unlimited) → skip the `SeatsTaken < Capacity` check, always grant.

### 16.6 Required schema changes (summary)
On `CourseOfferings`: add `SeatsTaken INT NOT NULL DEFAULT 0`, optional `RowVersion rowversion`, `RegistrationOpenAtUtc`/`RegistrationCloseAtUtc datetime2 NULL`, CK `SeatsTaken >= 0 AND (Capacity IS NULL OR SeatsTaken <= Capacity)`.
On `Enrollments`: extend `Status` (add 5=Pending, 6=Waitlisted), add `WaitlistPosition INT NULL`.
**All existing table structures, keys, FKs, and unique constraints are preserved.**

---

## Appendix A: Working Process Agreement

- Prioritize **design and data-flow understanding over fast code generation**. Analyze each feature fully before coding.
- Tag every decision DECIDED / UNDER CONSIDERATION / NOT YET DESIGNED.
- Make schema changes via controlled migrations that do not break the invariants in Section 14.4.

---

*End of Smart_University_Handover_EN.md*
