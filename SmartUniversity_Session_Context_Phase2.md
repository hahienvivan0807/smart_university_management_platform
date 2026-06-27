# Smart University Platform — Session Context (Phase 2: Academic Structure)

**Purpose of this document:** Continuation snapshot cho bất kỳ AI session hoặc developer nào tiếp tục dự án này. Bổ sung cho `Smart_University_Handover_EN.md` (quyết định thiết kế), `ROADMAP_PROJECT.md` (danh sách task), và `SmartUniversity_Session_Context_Phase1.md` (Phase 1 Auth). File này ghi lại *những gì đã được xây dựng thực tế trong Phase 2*, cùng các quy ước và quyết định kỹ thuật để session mới không cần suy luận lại từ đầu.

---

## 1. Cấu trúc dự án hiện tại (sau Phase 2)

```
SmartUniversity/
├── Controllers/
│   ├── Auth/
│   │   └── AuthController.cs                  (namespace SmartUniversity.Controllers.Auth)
│   ├── Academic/
│   │   ├── FacultiesController.cs
│   │   ├── DepartmentsController.cs
│   │   ├── MajorsController.cs
│   │   ├── ProgramsController.cs
│   │   ├── CoursesController.cs
│   │   ├── AcademicTermsController.cs
│   │   ├── AdminClassesController.cs
│   │   ├── CourseOfferingsController.cs
│   │   └── ProfilesController.cs              (namespace SmartUniversity.Controllers.Academic)
│   └── System/
│       ├── PingController.cs
│       └── WeatherForecastController.cs        (file mẫu .NET, có thể xóa)
├── Application/
│   ├── Common/
│   │   ├── Interfaces/    (IAuthService, IJwtTokenService, IPasswordHasher)
│   │   └── Models/        (PagedResult<T>, Result<T>, ErrorResponse, AuthResult, JwtSettings)
│   └── Features/
│       ├── Auth/Dtos/     (LoginRequest, LoginResponse, RegisterRequest)
│       └── Academic/
│           ├── Dtos/
│           │   ├── FacultyDtos.cs      (FacultyListDto, FacultyDetailDto, Create/UpdateFacultyRequest)
│           │   ├── DepartmentDtos.cs   (DepartmentListDto, DepartmentDetailDto, Create/UpdateDepartmentRequest)
│           │   ├── MajorDtos.cs        (MajorListDto, MajorDetailDto, Create/UpdateMajorRequest)
│           │   ├── ProgramDtos.cs      (ProgramListDto, ProgramDetailDto, AddCourseToProgramRequest, ...)
│           │   ├── CourseDtos.cs       (CourseListDto, CourseDetailDto, AddPrerequisiteRequest, ...)
│           │   ├── AcademicTermDtos.cs (AcademicTermListDto, AcademicTermDetailDto, Create/UpdateAcademicTermRequest)
│           │   ├── AdminClassDtos.cs   (AdminClassListDto, AdminClassDetailDto, GanSinhVienVaoLopRequest, ...)
│           │   ├── CourseOfferingDtos.cs (CourseOfferingListDto, CourseOfferingDetailDto, DoiGiangVienRequest, ...)
│           │   └── ProfileDtos.cs      (StudentProfileDto, LecturerProfileDto, Create/UpdateRequest cho cả hai)
│           ├── FacultyService.cs
│           ├── DepartmentService.cs
│           ├── MajorService.cs
│           ├── ProgramService.cs
│           ├── CourseService.cs
│           ├── AcademicTermService.cs
│           ├── AdminClassService.cs
│           ├── CourseOfferingService.cs
│           └── ProfileService.cs
├── Infrastructure/Security/   (AuthService, JwtTokenService, BcryptPasswordHasher)
├── Models/                    (EF Core scaffold — KHÔNG sửa tay)
├── Seeding/
│   └── DbSeeder.cs            (Phase 1 + Phase 2 seed đều ở đây)
└── Program.cs
```

---

## 2. Quy ước đặt tên (bắt buộc cho toàn dự án)

Quy ước này được thiết lập từ Phase 2 và áp dụng cho tất cả code phía sau.

| Phần | Quy tắc | Ví dụ |
|---|---|---|
| DTO properties | Tiếng Anh (JSON contract) | `CourseOfferingId`, `FullName` |
| Biến local / tham số | Tiếng Việt, ngắn | `ketQua`, `yeuCau`, `lopHC`, `tongSo` |
| Tên phương thức service | Tiếng Việt + Async | `LayDanhSachAsync`, `TaoMoiAsync`, `VoHieuHoaAsync` |
| Tên action controller | Tiếng Việt | `LayDanhSach`, `TaoMoi`, `CapNhat`, `VoHieuHoa` |
| Tên field service trong controller | Tiếng Việt | `_dichVuLHP`, `_dichVuLop`, `_dichVuHK` |

---

## 3. Các lỗi kỹ thuật quan trọng & cách sửa (đã xác nhận)

### 3.1 `FindAsync` bỏ qua Global Query Filter
**Vấn đề:** `await _db.Faculties.FindAsync(id)` trả về entity ngay cả khi `IsActive = false`.  
**Nguyên nhân:** `FindAsync` dùng primary key cache, không qua LINQ pipeline nên bỏ qua filter.  
**Cách sửa (áp dụng cho toàn dự án):**
```csharp
// SAI
var entity = await _db.SomeEntities.FindAsync(id);

// ĐÚNG — trong UpdateAsync và DeactivateAsync
var entity = await _db.SomeEntities.FirstOrDefaultAsync(e => e.Id == id);
```

### 3.2 Kiểm tra trùng khi tạo mới
**Vấn đề:** `AnyAsync(e => e.Code == code)` không tìm thấy bản ghi đã bị deactivate do global filter.  
**Kết quả:** Có thể tạo code trùng với record cũ đã bị vô hiệu hóa.  
**Cách sửa:**
```csharp
// Trong CreateAsync — luôn IgnoreQueryFilters khi check trùng
var exists = await _db.SomeEntities
    .IgnoreQueryFilters()
    .AnyAsync(e => e.UniversityId == uid && e.Code == code);
```

### 3.3 CourseOffering KHÔNG có IsActive
**Vấn đề:** `CourseOffering` dùng `Status` byte (1=Đang mở, 2=Đã hủy) thay cho `IsActive`.  
**Hệ quả:** Không được đưa vào global query filter; mọi query CourseOffering phải `.IgnoreQueryFilters()`.
```csharp
// Mọi query CourseOffering đều phải có IgnoreQueryFilters
var lhp = await _db.CourseOfferings
    .IgnoreQueryFilters()
    .FirstOrDefaultAsync(x => x.CourseOfferingId == id);
```
**Hủy lớp học phần:** Đổi `Status = 2`, KHÔNG soft delete.

### 3.4 DepartmentListDto khai báo 2 lần
**Vấn đề:** `DepartmentListDto` từng được thêm vào cuối `FacultyDtos.cs` rồi sau đó tạo `DepartmentDtos.cs` riêng → build lỗi `CS0101`.  
**Đã sửa:** Xóa bản trùng ở `FacultyDtos.cs`, giữ lại trong `DepartmentDtos.cs`.

---

## 4. Khái niệm domain quan trọng

### AdminClass vs CourseOffering
Hai khái niệm KHÁC NHAU, thường bị nhầm lẫn:

| | AdminClass (Lớp hành chính) | CourseOffering (Lớp học phần) |
|---|---|---|
| Tiếng Việt | Lớp hành chính | Lớp học phần |
| Vòng đời | 4 năm (cố định theo khóa) | 1 học kỳ (tạo lại mỗi kỳ) |
| Thuộc về | Program (chương trình đào tạo) | Course + AcademicTerm |
| Quan hệ sinh viên | Sinh viên thuộc đúng 1 lớp HC | Nhiều sinh viên từ nhiều lớp HC đăng ký |
| Ví dụ | KTPM2023A | IT002-01 (HK1 2024-2025) |

**Lý do CourseOffering không có FK về AdminClass:** Một lớp học phần có thể có sinh viên từ nhiều lớp hành chính khác nhau (sinh viên học lại, sinh viên trao đổi...). Quan hệ là qua bảng `Enrollments`.

### Hàng đợi đăng ký (Phase 3)
Kế hoạch dùng `System.Threading.Channels` + atomic DB check để xử lý đăng ký học phần ồ ạt. Đây là lý do giữ cả hai khái niệm AdminClass và CourseOffering — bài toán hàng đợi hoạt động trên CourseOffering enrollment, không ảnh hưởng AdminClass.

---

## 5. Global Query Filters (SmartUniversityContext.cs)

Đặt ở cuối `OnModelCreating`, trước `OnModelCreatingPartial`:
```csharp
modelBuilder.Entity<Faculty>().HasQueryFilter(f => f.IsActive);
modelBuilder.Entity<Department>().HasQueryFilter(d => d.IsActive);
modelBuilder.Entity<Major>().HasQueryFilter(m => m.IsActive);
modelBuilder.Entity<Program>().HasQueryFilter(p => p.IsActive);
modelBuilder.Entity<Course>().HasQueryFilter(c => c.IsActive);
modelBuilder.Entity<AdminClass>().HasQueryFilter(a => a.IsActive);
// CourseOffering — KHÔNG có filter, dùng Status thay thế
```

---

## 6. Authorization

```csharp
// Đọc: tất cả user đã đăng nhập
[Authorize]

// Ghi/Xóa: chỉ Admin hoặc AcademicOffice
[Authorize(Policy = "AccountProvisioning")]
```

Toàn bộ academic CRUD (tạo/sửa/vô hiệu hóa) đều dùng `"AccountProvisioning"`.

---

## 7. Seeding Phase 2 (DbSeeder.cs)

Method `SeedAcademicStructureAsync` — idempotent, chạy sau Phase 1 seed.

| Thứ tự | Loại | Dữ liệu |
|---|---|---|
| 1 | Faculty | Khoa CNTT (`Code = "CNTT"`) |
| 2 | Department | Bộ môn KTPM, Bộ môn KHMT (thuộc Khoa CNTT) |
| 3 | Major | Kỹ thuật Phần mềm (`Code = "7480103"`) |
| 4 | Program | KTPM2023 — 140 tín chỉ, năm 2023 |
| 5 | Courses | IT001~IT005 (3 tín chỉ/môn) — owned bởi KTPM hoặc KHMT |
| 6 | AcademicTerm | HK1 2024-2025 (`TermType=1`, 02/09/2024–10/01/2025) |
| 7 | AdminClass | KTPM2023A (thuộc Program KTPM2023, IntakeYear=2023) |
| 8 | LecturerProfile | `lecturer01` → Bộ môn KTPM, FacultyId CNTT, `AcademicTitle="Thạc sĩ"` |
| 9 | StudentProfile | `student01` → AdminClass KTPM2023A, IntakeYear=2023, `StudentStatus=1` (Đang học) |

---

## 8. API Endpoints Phase 2

### Academic Controllers (tất cả trong `/api/`)

| Route | GET list | GET detail | POST create | PUT update | DELETE/Cancel |
|---|---|---|---|---|---|
| `/faculties` | ✓ | ✓`/{id}` | Staff | Staff | Staff (soft) |
| `/departments` | ✓ `?facultyId` | ✓`/{id}` | Staff | Staff | Staff (soft) |
| `/majors` | ✓ `?facultyId` | ✓`/{id}` | Staff | Staff | Staff (soft) |
| `/programs` | ✓ `?majorId` | ✓`/{id}` | Staff | Staff | Staff (soft) |
| `/courses` | ✓ | ✓`/{id}` | Staff | Staff | Staff (soft) |
| `/academic-terms` | ✓ | ✓`/{id}` | Staff | Staff | — |
| `/admin-classes` | ✓ `?programId` | ✓`/{id}` | Staff | Staff | Staff (soft) |
| `/course-offerings` | ✓ `?academicTermId` | ✓`/{id}` | Staff | Staff | `POST /{id}/cancel` |
| `/profiles/students/{userId}` | — | ✓ | Staff | — | — |
| `/profiles/students/{userId}/status` | — | — | — | Staff | — |
| `/profiles/lecturers/{userId}` | — | ✓ | Staff | Staff | — |

### Endpoints phụ
```
POST   /programs/{id}/courses               → thêm môn vào chương trình
GET    /programs/{id}/courses               → danh sách môn của chương trình
DELETE /programs/{id}/courses/{courseId}    → xóa môn khỏi chương trình
POST   /courses/{id}/prerequisites          → thêm môn tiên quyết (có BFS cycle check)
GET    /courses/{id}/prerequisites          → danh sách môn tiên quyết
DELETE /courses/{id}/prerequisites/{preId}  → xóa môn tiên quyết
POST   /admin-classes/{id}/students         → gán sinh viên vào lớp hành chính
PUT    /course-offerings/{id}/lecturer      → đổi giảng viên phụ trách
```

---

## 9. Trạng thái Phase 2

### Backend — HOÀN THÀNH ✅
- [x] 9 Services: FacultyService, DepartmentService, MajorService, ProgramService, CourseService, AcademicTermService, AdminClassService, CourseOfferingService, ProfileService
- [x] 9 Controllers (thư mục `Controllers/Academic/`) — tên biến tiếng Việt
- [x] Controllers tổ chức theo thư mục: `Auth/`, `Academic/`, `System/`
- [x] DbSeeder cập nhật seed data Phase 2
- [x] Program.cs đăng ký đủ 9 service
- [x] Build 0 lỗi

### Còn lại — CHƯA LÀM ⏳
- [ ] Flutter Module 2.5: màn hình browse (Faculty/Department, Program+Curriculum, Course catalog, Offerings-by-term)
- [ ] Flutter Module 2.5: form admin (tạo/sửa Faculty, Major, Program, Course, Term, AdminClass, Offering)
- [ ] ROADMAP_PROJECT.md: cập nhật checkbox cho tất cả task đã làm trong Phase 2
- [ ] Soft-delete convention: document trong ROADMAP conventions section (1 task còn thiếu)
- [ ] Xóa `WeatherForecastController.cs` (file mẫu, không dùng)

---

## 10. Những gì KHÔNG làm trong Phase 2 (đẩy sang Phase 3)

- **Enrollment engine**: đăng ký học phần (queue-based, atomic check, waitlist) → Phase 3
- **Capacity enforcement**: kiểm tra `SeatsTaken >= Capacity` khi đăng ký → Phase 3
- **Prerequisite enforcement khi đăng ký**: chỉ model prerequisite, chưa enforce → Phase 3
- **Conflict check (trùng lịch)**: chưa có bảng timetable → Phase 3/4

---

*Cập nhật: Phase 2 backend hoàn thành. Session tiếp theo bắt đầu từ Flutter browse screens (Module 2.5) hoặc cập nhật ROADMAP checkboxes.*
