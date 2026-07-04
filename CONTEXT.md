# Session Context — Smart University Management Platform

> Đọc hết file này trước khi bắt đầu bất kỳ việc gì. Tóm tắt toàn bộ việc đã xong và việc còn dở từ (các) phiên trước.

---

## 1. Project Overview

**Flutter frontend** — `c:\Users\littl\StudioProjects\Smart_University_Management_Platform`
**ASP.NET Core backend** — `C:\Users\littl\source\repos\SmartUniversity\SmartUniversity`

Hệ thống đăng ký học phần theo tín chỉ (sinh viên tự đăng ký vào các `CourseOffering` do staff tạo sẵn).

**Tiến độ tổng:** xem `ROADMAP_PROJECT.md` — hiện **61% (166/272 task)**. Phase 0-1 100%, Phase 2 63%, Phase 3 69%, Phase 4 69%, Phase 5-8 chưa bắt đầu (0%).

---

## 2. Trạng thái các Phase

| Phase | Trạng thái |
|---|---|
| Phase 0 — Foundation | ✅ 100% |
| Phase 1 — Auth | ✅ 100% |
| Phase 2 — Academic Structure | 🟡 63% — CRUD backend đủ 7 entity, Flutter admin UI đã xây xong hết (xem mục 3) |
| Phase 3 — Enrollment & Timetable | 🟡 69% — đăng ký/hủy môn + Timetable đã xong; còn thiếu Lecturer timetable (backend chỉ cho Student), import-based module 3.1 đã lỗi thời (bỏ qua, không làm theo) |
| Phase 4 — Attendance | 🟡 69% backend đã verify qua API đầy đủ; **Flutter UI (quét QR) CHƯA test tay** — đợi có điện thoại thật |
| Phase 5 — Documents | ⬜ 0% — **chưa bắt đầu, nên làm tiếp theo** |
| Phase 6 — Notification | ⬜ 0% |
| Phase 7 — Analytics | ⬜ 0% |
| Phase 8 — AI Assistant | ⬜ 0% — cố tình để cuối, cần đọc dữ liệu từ Phase 5-7 |

---

## 3. Việc đã làm trong (các) phiên gần đây — chi tiết

### 3.1 Backend — Phase 4 Attendance: verify qua API (PASS toàn bộ)
Test bằng PowerShell `Invoke-RestMethod`: mở session → lấy QR token → check-in trong 30s → xem records → xem lịch sử → đóng session → đổi giảng viên. Tất cả OK.

### 3.2 Backend + Flutter — Timetable (mới xây)
- Migration `Migrations/AddScheduleColumnsToOfferings.sql` — thêm 4 cột `DayOfWeek/StartTime/EndTime/Room` vào `CourseOfferings` (đã chạy, cột tồn tại trong DB).
- Endpoint mới `GET /api/me/timetable?termId=` (`EnrollmentsController.XemThoiKhoaBieu`, `EnrollmentService.LayThoiKhoaBieuAsync`) — chỉ role **Student**.
- Quy ước `DayOfWeek`: **1=Chủ nhật, 2=Thứ 2, ..., 7=Thứ 7** (chuẩn SQL Server). Công thức đổi từ `DateTime.weekday` của Dart (1=Thứ 2..7=CN): `backendDay = (dart.weekday % 7) + 1`.
- Flutter: `my_timetable_screen.dart`, model `TimetableEntry` (trong `enrollment.dart`), `EnrollmentService.layThoiKhoaBieu()`.

### 3.3 Flutter — Program browse screen (mới xây)
`program_list_screen.dart` + `program_detail_screen.dart` (xem curriculum), model/service `program.dart`/`program_service.dart`. Backend đã có sẵn từ trước (`ProgramsController`).

### 3.4 Backend + Flutter — Admin CRUD UI cho cả 7 entity (mới xây, khối lớn nhất)
Form tạo/sửa cho: **Faculty, Major, Program (+curriculum add/remove), Course, AcademicTerm, AdminClass (+gán sinh viên), CourseOffering (+đổi giảng viên/hủy lớp)**. Tất cả đã smoke-test qua API thật (PowerShell). `AdminDashboardScreen` — trang tổng hợp lối tắt tới cả 7 màn, thay placeholder cũ trong tab "Quản trị".

Pattern dùng chung: model (`XItem` + `CreateXRequest`/`UpdateXRequest`) → service (`layDanhSach/layChiTiet/taoMoi/capNhat/voHieuHoa`) → form screen (copy từ `department_form_screen.dart`) → list screen (FAB + PopupMenu Sửa/Vô hiệu hóa).

### 3.5 Bug fix — Hero tag trùng (crash khi mở app)
`IndexedStack` trong `AppShell` giữ tất cả tab sống cùng lúc → nhiều `FloatingActionButton` (Faculty/Major/Program/Course/AcademicTerm/AdminClass/CourseOffering) cùng có Hero tag mặc định giống nhau → `FlutterError`. **Đã sửa:** gán `heroTag` string riêng cho mọi `FloatingActionButton.extended` trong 9 file.

### 3.6 Bug fix — Thiếu nút quay về (back button)
`FacultyListScreen`, `ProgramListScreen`, `AcademicTermListScreen`, `CourseListScreen` vốn thiết kế chỉ để nhúng trong tab `AppShell` (không có AppBar riêng — AppShell tự có AppBar). Nhưng `AdminDashboardScreen` và `CourseCatalogHomeScreen` lại `Navigator.push` các màn này như màn độc lập → không có nút back.
**Đã sửa:** thêm param `laManHinhDoc` (mặc định `false`) vào cả 4 file + `CourseOfferingListScreen` (kết hợp với `termId != null` sẵn có). Khi `laManHinhDoc == true` → hiện AppBar riêng có nút back. Mọi nơi gọi từ `AdminDashboardScreen`/`CourseCatalogHomeScreen` đều truyền `laManHinhDoc: true`.

### 3.7 Tái cấu trúc "Danh mục môn học"
Trước: liệt kê phẳng TẤT CẢ môn học toàn trường (dễ quá tải nếu nhiều khoa). Sau khi bàn bạc UX:
- File mới `course_catalog_home_screen.dart` — hiện danh sách **Khoa** trước, có mục **"Tất cả môn học"** ghim đầu (để không mất khả năng xem môn đại cương không gán khoa). Tap 1 khoa → `CourseListScreen(facultyId:...)`.
- Tab "Danh mục môn học" trong `AppShell` giờ trỏ vào `CourseCatalogHomeScreen` thay vì `CourseListScreen` trực tiếp.
- **Quyết định KHÔNG làm:** không lọc Course theo Học kỳ (Course là danh mục không gắn kỳ, khác với CourseOffering — tránh nhầm 2 khái niệm).

### 3.8 Dashboard redesign (lấy tinh thần OneUni, giữ bản sắc riêng)
File mới `dashboard_screen.dart`, gắn làm tab đầu tiên trong `AppShell` (tab "Trang chủ").
- Header gradient indigo/tím (không copy màu xanh của OneUni) — avatar chữ cái đầu + lời chào + vai trò.
- **Thẻ "Lịch học hôm nay"** — chỉ hiện với **Student** (backend Timetable chỉ mở role này). Dữ liệu **thật**: tự tìm học kỳ hiện tại (so ngày với StartDate/EndDate của `AcademicTerm`), gọi Timetable API, lọc đúng thứ hôm nay.
- Lưới "Danh mục" nhiều màu (dùng token màu có sẵn: `AppColors.blue/purple/teal/amber`), responsive 3-5 cột theo bề rộng (`LayoutBuilder`).
- Tile "Tất cả" cuối lưới → mở `_AllFeaturesScreen` liệt kê tính năng ít dùng.
- ⚠️ **2 tile "Quản lý giảng viên" / "Quản lý sinh viên" (role Admin) hiện chỉ là `_ComingSoonScreen` placeholder — CHƯA có chức năng thật.** Backend Module 2.3 (Profiles) mới chỉ có endpoint tạo/xem 1 profile theo ID, **chưa có endpoint list/search tất cả giảng viên/sinh viên** — cần xây mới nếu muốn làm thật 2 tính năng này (xem mục 5).
- **Quyết định KHÔNG làm:** không đổi sang Bottom Navigation Bar kiểu OneUni (app chạy cả Windows desktop, bottom nav không hợp màn rộng) — giữ nguyên Drawer.

### 3.9 Dialog phản hồi dùng chung (mới, MỚI CHỈ NỐI VÀO FACULTY)
File mới `lib/features/academic/screens/widgets/submit_status_dialog.dart` — dialog xoay tròn khi submit → tick xanh (thành công, tự đóng sau 0.7s) / dấu ⚠ cam (trùng dữ liệu, HTTP 409) / dấu ✗ đỏ (lỗi khác) kèm nút "Đóng".
- Đã nối vào **`faculty_form_screen.dart`** (kèm thêm field `isConflict` vào `FacultyService.taoMoi/capNhat` để phân biệt lỗi trùng vs lỗi khác).
- ⚠️ **CHƯA nối vào 6 form còn lại** (Major, Program, Course, AcademicTerm, AdminClass, CourseOffering) — việc lặp lại cơ học, làm sau nếu duyệt pattern ở Faculty ổn.

---

## 4. Sự thật cần sửa so với context cũ (đã kiểm chứng lại)

- **Mật khẩu test đúng là `Test@123`** (không phải `Abc@12345` như context cũ ghi — lấy từ `Seeding/DbSeeder.cs`).
- **`student02` KHÔNG tồn tại** trong DB — seed chỉ tạo `student01`. Đừng dùng tài khoản này.
- ROADMAP_PROJECT.md từng ghi sai % (Phase 1 ghi 77% dù thực tế 100%) — đã sửa lại đúng.

---

## 5. Đề xuất việc tiếp theo — **mục tiêu phiên tới: backend**

Thứ tự ưu tiên đề xuất:

1. **Phase 5 — Documents (backend, đúng thứ tự roadmap):** thiết kế bảng `Documents` (owner, scope theo Course/CourseOffering, file metadata), quyết định lưu file ở đâu (file system/blob — không lưu bytes trong SQL), viết migration, endpoint upload (validate loại/kích thước file) + download (access-scoped) + list + soft-delete.
2. **Endpoint list/search giảng viên + sinh viên (backend, ngắn hạn, thay placeholder ở Dashboard):**
   - `GET /api/lecturers` — danh sách + tìm kiếm (lọc theo Khoa/Bộ môn), dùng để thay `_ComingSoonScreen` ở tile "Quản lý giảng viên".
   - `GET /api/students` — danh sách + tìm kiếm (lọc theo AdminClass), dùng để thay `_ComingSoonScreen` ở tile "Quản lý sinh viên".
   - Cả 2 chưa tồn tại — Module 2.3 hiện tại chỉ có endpoint tạo/xem theo ID, không có list toàn bộ.
3. **(Frontend, làm sau nếu còn thời gian)** Nhân rộng `submit_status_dialog.dart` từ Faculty sang 6 form CRUD còn lại.
4. **(Đợi điều kiện)** Test luồng QR điểm danh thật trên điện thoại khi có máy.

### Gợi ý prompt để mở phiên mới

```
Đọc CONTEXT.md và ROADMAP_PROJECT.md, sau đó bắt đầu Phase 5 (Documents) ở backend —
thiết kế bảng Documents + endpoint upload/download, theo đúng pattern
Controller → Service → DTO đã dùng cho các entity khác.
```

hoặc:

```
Đọc CONTEXT.md. Hãy xây 2 endpoint GET /api/lecturers và GET /api/students
(danh sách + tìm kiếm, có phân trang) để thay 2 màn "Quản lý giảng viên"/
"Quản lý sinh viên" đang là placeholder ComingSoon trên Dashboard.
```

---

## 6. Current Tech Setup

### Backend run command (LUÔN dùng lệnh này)
```powershell
dotnet run --urls "http://0.0.0.0:5102" --project "C:\Users\littl\source\repos\SmartUniversity\SmartUniversity"
```
- HTTP (không phải HTTPS) — Android/Windows dev không cần cert
- `0.0.0.0` — cho phép cả emulator/điện thoại/LAN kết nối
- Port 5102

### Chạy Flutter trên Windows desktop (đang dùng để test)
```powershell
flutter run -d windows
```
`lib/core/_platform_io.dart` tự resolve `localhost` cho Windows (chỉ Android mới cần `10.0.2.2`).

### Kiểm tra backend đang chạy
```powershell
netstat -ano | findstr :5102
```

### API docs (Scalar)
```
http://localhost:5102/scalar/v1
```

### Test accounts (ĐÃ SỬA — xem mục 4)
| Account | Password | Role |
|---|---|---|
| `admin01` | `Test@123` | Admin |
| `lecturer01` | `Test@123` | Lecturer (dạy offering ID 4 — Nhập môn Lập trình) |
| `student01` | `Test@123` | Student |

---

## 7. Known Issues / Warnings

- Backend: `warn: Failed to determine the https port for redirect` — vô hại.
- Backend: CS0436 warnings trùng `LoginRequest`/`LoginResponse` — có từ trước, không phải do phiên này.
- Flutter: 2 warning vô hại từ `flutter analyze` (`unused_element_parameter` trong `academic_term_form_screen.dart` và `faculty_form_screen.dart` — do dùng chung widget `_Field` có param không phải form nào cũng cần).
- 2 tile Dashboard "Quản lý giảng viên"/"Quản lý sinh viên" chỉ là placeholder (xem mục 3.8, 5).
- `submit_status_dialog.dart` mới chỉ áp dụng cho Faculty (xem mục 3.9).

---

## 8. Code Conventions (xem thêm `BACKEND_DESIGN_RULES.md`)

**Backend:** Chỉ `/// <summary>` XML doc đầu method, không comment từng dòng. Kiến trúc Controller → Service → DbContext, không lẫn business logic vào Controller. DTO property tiếng Anh; biến local/tham số/tên method service dùng tiếng Việt + hậu tố `Async`.
**Frontend:** Biến tiếng Việt xuyên suốt. Dùng `session` + `authenticatedClient` global từ `main.dart`. Service trả về Dart record `({T? data, String? error, ...})`, không dùng class `Result` riêng.
**Result pattern (backend):** `Result<T>` dùng `kq.Succeeded`/`kq.Value` (KHÔNG phải `IsSuccess`/`Data`).
**JWT UserId claim:** `"uid"` → `int.TryParse(User.FindFirst("uid")?.Value, ...)`.
**EF Core:** Dùng `FirstOrDefaultAsync` thay `FindAsync` trong Update/Deactivate (FindAsync bỏ qua global query filter). Mọi query `CourseOffering` phải `.IgnoreQueryFilters()` (dùng `Status` byte thay vì `IsActive`).
**Soft delete:** `IsActive = false`, chặn deactivate nếu còn con đang active. Ngoại lệ: `CourseOffering` dùng `Status`.

**WORKFLOW RULE:** Luôn trình bày plan và xin duyệt trước khi viết code.
