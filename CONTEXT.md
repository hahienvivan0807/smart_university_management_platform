# Session Context — Smart University Management Platform

> Đọc hết file này trước khi bắt đầu bất kỳ việc gì. Tóm tắt toàn bộ việc đã xong và việc còn dở từ (các) phiên trước.

---

## 1. Project Overview

**Flutter frontend** (Student/Lecturer, mobile+desktop) — `c:\Users\littl\StudioProjects\Smart_University_Management_Platform`
**ASP.NET Core backend** — `C:\Users\littl\source\repos\SmartUniversity\SmartUniversity`
**Blazor Server admin** (mới, Admin/AcademicOffice, chạy chung project với backend) — cùng thư mục backend ở trên, xem mục 3.12.

Hệ thống đăng ký học phần theo tín chỉ (sinh viên tự đăng ký vào các `CourseOffering` do staff tạo sẵn).

**Tiến độ tổng:** xem `ROADMAP_PROJECT.md` — hiện **68% (191/280 task)**. Phase 0-1 gần xong, Phase 2 63% (backend+Blazor CRUD nay đã phủ đủ cả 7 entity + curriculum/prerequisite, xem mục 3.19), Phase 3 69%, Phase 4 97% (gần như xong, chỉ thiếu click-test tay trên điện thoại thật), Phase 5 **100%** (backend + Blazor + Flutter UI đều xong, xem mục 3.19–3.21), Phase 6-8 chưa bắt đầu (0%).

---

## 2. Trạng thái các Phase

| Phase | Trạng thái |
|---|---|
| Phase 0 — Foundation | ✅ 100% |
| Phase 1 — Auth | ✅ 100% |
| Phase 2 — Academic Structure | 🟡 63% — CRUD backend + Blazor UI nay phủ đủ cả 7 entity (Khoa/Bộ môn/Ngành/CTĐT/Môn học/Học kỳ/Lớp hành chính/Lớp học phần) kèm curriculum + prerequisite management, tìm kiếm tức thời, xem chi tiết (mục 3.19) |
| Phase 3 — Enrollment & Timetable | 🟡 69% — đăng ký/hủy môn + Timetable đã xong; còn thiếu Lecturer timetable (backend chỉ cho Student), import-based module 3.1 đã lỗi thời (bỏ qua, không làm theo) |
| Phase 4 — Attendance | 🟢 97% — backend + edge case (trùng/đóng lớp/không enroll) + trễ giờ đã verify qua API; 4 màn Flutter đã xây + `flutter analyze` sạch; **CHƯA test tay** trên điện thoại thật (máy dev không có camera) |
| Phase 5 — Documents | ✅ 100% — backend + Blazor (theo Course lẫn CourseOffering) + Flutter UI (browse/upload/download) đều xong (mục 3.20–3.21); ⚠️ Flutter UI chưa click-test tay |
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

### 3.10 Backend — Phase 5 Documents (mới xây, verify qua API PASS toàn bộ 2026-07-04)
- Bảng `Documents` (`Migrations/AddDocumentsTable.sql`, đã chạy) — scope đúng 1 trong 2 (`CourseId` XOR `CourseOfferingId`, CHECK constraint `CK_Documents_ExactlyOneScope`): tài liệu chung môn học (catalog) vs. tài liệu riêng 1 lớp học phần theo kỳ.
- File lưu trên đĩa `App_Data/Documents/` (tên GUID, tránh trùng/path traversal), DB chỉ lưu `StoredFileName` + metadata. Cấu hình `appsettings.json` mục `DocumentStorage` (`RootPath`, `MaxUploadSizeMb=20`, `AllowedExtensions`).
- `DocumentService.cs` + `DocumentsController.cs` (`Application/Features/Academic/`, `Controllers/Academic/`) — theo đúng pattern Controller → Service → DbContext có sẵn:
  - `POST /api/documents` (multipart) — Lecturer chỉ upload vào `CourseOfferingId` mình phụ trách; Admin/AcademicOffice mới được upload vào `CourseId` (tài liệu chung) hoặc bất kỳ offering nào.
  - `GET /api/documents?courseId=&courseOfferingId=` — doc theo `CourseOfferingId` chỉ SV đã enroll (Status=1)/GV phụ trách/staff xem được; doc theo `CourseId` ai đăng nhập cũng xem được.
  - `GET /api/documents/{id}/download` — stream file, áp cùng rule quyền như list.
  - `PUT /api/documents/{id}/deactivate` — soft-delete (`IsActive=false`, giữ nguyên file vật lý), chỉ người upload hoặc staff.
- Đã test qua `curl` thật (không phải giả lập): upload lecturer→offering đúng lớp OK, sai lớp/role Student bị chặn; upload CourseId chỉ staff; đuôi file `.exe` bị từ chối; thiếu/thừa scope bị từ chối; SV enrolled xem+tải được, SV không enroll bị chặn với thông báo rõ; sau deactivate thì list/download đều "không tìm thấy" (do global query filter `IsActive`) nhưng file vẫn còn trên đĩa.
- ⚠️ **Flutter UI cho Documents CHƯA làm** (list/upload/download screens) — xem mục 5.

### 3.11 Hoàn thành nốt Phase 4 — edge case + trễ giờ + xác nhận Flutter UI (2026-07-04)
- **Edge case check-in** (Module 4.2): review code cũ phát hiện `AttendanceService.CheckInAsync` **đã** chặn trùng ("Bạn đã điểm danh rồi."), buổi đã đóng ("Mã QR không hợp lệ hoặc buổi đã đóng."), không enroll ("Bạn không có trong danh sách lớp này.") từ trước — chỉ chưa được test/ghi nhận. Đã verify lại cả 3 case qua `curl` thật, PASS.
- **Late/on-time status (mới xây):** thêm cột `AttendanceRecords.Status` (`Migrations/AddLateStatusToAttendanceRecords.sql`, 1=Đúng giờ/2=Trễ, default 1). Ngưỡng trễ = check-in sau khi buổi mở quá 15 phút (`const LATE_GRACE_MINUTES = 15` trong `AttendanceService.cs`, cùng kiểu với `TOKEN_DURATION_SECONDS` có sẵn — không thêm config mới). Trả về trong cả `AttendanceRecordDto` (roster GV) và `MyAttendanceDto` (lịch sử SV, nullable vì có thể chưa điểm danh). Test bằng cách backdate `OpenedAtUtc` qua SQL trực tiếp để giả lập trễ — xác nhận `status=2`.
- **Flutter:** `AttendanceRecord`/`MyAttendanceItem` model thêm field `status` + getter `treGio`. `attendance_session_screen.dart` hiện badge cam "Trễ" cạnh tên SV trong danh sách check-in. `attendance_history_screen.dart` đổi text/màu/icon theo 3 trạng thái Có mặt (xanh) / Trễ (cam) / Vắng (đỏ). `flutter analyze` sạch.
- **Xác nhận 4 màn Flutter Attendance đã tồn tại từ trước** (`attendance_session_screen.dart`, `qr_scan_screen.dart`, `attendance_history_screen.dart`, `roster_screen.dart`) — roadmap ghi 0/3 là **stale**, thực ra đã build + wire đầy đủ (dùng `qr_flutter`, `mobile_scanner`, `geolocator` — cả 3 package đã khai báo trong `pubspec.yaml`). Chỉ chưa click-test được camera+GPS thật vì máy dev không có camera.
- Phase 4 giờ **97% (31/32)** — chỉ còn "Note future AttendancePolicies" (Module 4.0, cố tình để ngoài scope v1) và click-test tay trên điện thoại thật.

### 3.12 Blazor Server admin — mới scaffold (2026-07-04), CHƯA có màn quản lý cụ thể
Quyết định: phần "quản trị" (dành cho Admin/AcademicOffice) sẽ phát triển bằng **Blazor Server**, chạy **chung project** với backend (`SmartUniversity.csproj`) — không tách project riêng — để gọi thẳng `Application/Features/*Service` qua DI (bỏ qua HTTP), tái dùng 100% DTO/Service/policy đã có. Đây chỉ là **khung sườn (scaffold)**: đăng nhập + 1 trang chào mừng, xác nhận pipeline chạy đúng. **Chưa có màn quản lý cụ thể nào** — user sẽ cung cấp yêu cầu chi tiết ở phiên sau.

**Vấn đề kỹ thuật quan trọng đã giải quyết — auth hỗn hợp JWT + Cookie trong cùng 1 app:**
- Blazor Server giữ kết nối SignalR liên tục nên không hợp JWT bearer (trình duyệt không tự gắn header Authorization) → dùng **cookie scheme riêng** tên `"AdminCookie"` chỉ cho path `/admin/**`.
- ⚠️ **Blazor Razor component KHÔNG cho phép chỉ định `AuthenticationSchemes` trong `@attribute [Authorize(...)]`** (ném `NotSupportedException` lúc runtime, không phải lúc build — chỉ phát hiện khi chạy thử) — đây là giới hạn của `AuthorizeRouteView`/`AuthorizeViewCore`, khác hẳn với Controller MVC.
- **Giải pháp:** dùng **policy scheme** (`AddPolicyScheme`) làm scheme mặc định (`DefaultScheme = "MultiAuth"`), tự chọn `"AdminCookie"` hay JWT (`"Bearer"`) dựa theo `context.Request.Path.StartsWithSegments("/admin")`. Nhờ vậy `HttpContext.User` được điền đúng scheme **trước khi** Blazor's `[Authorize(Policy=...)]` chạy (không cần chỉ định scheme ở component) — còn mọi Controller API hiện có **không phải sửa gì** (`[Authorize]`/`[Authorize(Roles=...)]` cũ vẫn chạy y hệt qua JWT).
- Đã verify qua `curl` thật: JWT API vẫn hoạt động y hệt (không bị ảnh hưởng); `/admin` chưa đăng nhập → redirect `/admin/login`; đăng nhập đúng role (Admin) → cookie hợp lệ, vào được `/admin`, hiện tên thật; sai mật khẩu / role không phải Admin-AcademicOffice → bị chặn ngay ở bước login; đăng xuất → cookie mất hiệu lực, `/admin` redirect lại login.

**Cấu trúc file đã tạo (trong `SmartUniversity.csproj`, KHÔNG phải project mới):**
- `Program.cs` — thêm `AddPolicyScheme("MultiAuth",...)`, `.AddCookie("AdminCookie",...)`, `AddCascadingAuthenticationState()`, `AddRazorComponents().AddInteractiveServerComponents()`, `UseStaticFiles()`, `UseAntiforgery()`, `MapRazorComponents<App>().AddInteractiveServerRenderMode()`.
- `Controllers/Admin/AdminAuthController.cs` — `POST /admin/login-submit` (⚠️ route khác `/admin/login` — trùng route với trang Blazor Login gây `AmbiguousMatchException`), `POST /admin/logout`. Check role Admin/AcademicOffice ngay tại đây (không dựa vào policy phía sau).
- `Components/App.razor`, `Routes.razor`, `RedirectToLogin.razor`, `_Imports.razor`
- `Components/Layout/MainLayout.razor` (header + nút đăng xuất), `LoginLayout.razor` (layout riêng cho trang login, không có header)
- `Components/Pages/Login.razor` (route `/admin/login`, form tĩnh post tới `/admin/login-submit`), `Home.razor` (route `/admin`, `@attribute [Authorize(Policy = "AccountProvisioning")]` — policy có sẵn từ trước, không tạo mới)
- `wwwroot/css/site.css` — CSS thuần tối giản, chưa dùng thư viện UI nào (Bootstrap/MudBlazor...) — để ngỏ cho yêu cầu UI cụ thể sau.
- Policy `"AccountProvisioning"` (RequireRole Admin/AcademicOffice) đã có sẵn từ Module 1.4, tái dùng luôn cho gate trang `/admin`.

### 3.13 Blazor admin — Dashboard UI thật (2026-07-04, cùng phiên với 3.12)
User yêu cầu thiết kế UI/UX kế thừa tinh thần Flutter (`ARCHITECTURE.md`/`theme.dart`) cho trang Dashboard. Đã thay khung sườn "chào mừng" đơn giản ở 3.12 bằng giao diện đầy đủ:

- **Design tokens** (`wwwroot/css/tokens.css`) — chuyển thẳng 1-1 từ `AppColors`/`AppRadius`/`AppSpacing` trong `lib/core/theme.dart` sang CSS variables (`--accent: #5B5BD6`, `--canvas`, `--panel`, `--border`, `--text`, `--muted`, `--faint`, `--clr-blue/purple/teal/amber`, `--radius-sm..xl`, `--space-xs..xxl`), có `@media (prefers-color-scheme: dark)` override y hệt cặp light/dark của Flutter. `--shadow-soft` chỉ có ở light mode (Flutter cũng chỉ đổ bóng ở light mode).
- **Layout Sidebar + Topbar** (`Components/Layout/MainLayout.razor` viết lại + `NavMenu.razor` mới): sidebar trái 264px cố định, nhóm mục theo 3 cây của roadmap (Cơ cấu tổ chức / Đào tạo / Người dùng / Khác — Khoa, Bộ môn, Ngành, Chương trình đào tạo, Môn học, Học kỳ, Lớp hành chính, Lớp học phần, Giảng viên, Sinh viên, Tài liệu); topbar có avatar chữ cái đầu + tên + vai trò (đọc từ Claims) + nút đăng xuất. Các mục sidebar **chưa có trang thật** → trỏ tới `Components/Pages/ComingSoon.razor` (route `/admin/coming-soon?label=...`, placeholder giống tinh thần `_ComingSoonScreen` bên Flutter) để tránh liên kết chết.
- **Dashboard** (`Home.razor` viết lại): header gradient indigo/tím giống `_GreetingHeader` Flutter, 4 thẻ KPI **dữ liệu thật** (query thẳng `SmartUniversityContext` — không bịa số: Khoa/Môn học/Giảng viên/Sinh viên), lưới lối tắt 8 thẻ đa màu (xanh dương/tím/teal/cam luân phiên, giống `_FeatureGrid`), hover nổi nhẹ (`translateY` + đổ bóng đậm hơn).
- **Status Dialog** (tương đương `submit_status_dialog.dart`): `Components/Shared/StatusDialogService.cs` (scoped DI service, có `ChayAsync(nhanDangXuLy, nhanThanhCong, action)` trả `KetQuaThaoTac`) + `StatusDialogHost.razor` (overlay toàn màn hình, spinner CSS xoay → SVG tick xanh/cảnh báo cam/X đỏ, tự đóng sau 700ms nếu thành công, có nút "Đóng" nếu lỗi) — render 1 lần trong `MainLayout`, gọi được từ bất kỳ trang nào qua `@inject StatusDialogService`. Demo dùng nút "↻ Làm mới dữ liệu" trên Dashboard (load lại 4 số KPI qua dialog).
- **Đã verify qua `curl`** (SSR ban đầu, vì Blazor Server prerender tĩnh trước khi circuit SignalR kết nối): đăng nhập → `/admin` trả về đúng HTML có 4 số KPI thật (khớp dữ liệu seed: 3 khoa/5 môn/2 GV/4 SV), đủ 11 mục sidebar, trang `coming-soon` nhận `label` qua query string hiển thị đúng, CSS (`tokens.css`/`site.css`) trả 200.
- ⚠️ **CHƯA click-test tương tác thật trên trình duyệt** (nút "Làm mới dữ liệu" mở dialog xoay→tick cần kết nối SignalR sống — `curl` không mô phỏng được) — cùng giới hạn như các flow tương tác Flutter (QR/camera) đã ghi ở Phase 4, cần mở bằng trình duyệt thật để xác nhận.
- Dùng `color-mix()` CSS (cho các `.tone-*`) — cần trình duyệt hiện đại (Chrome/Edge/Firefox 113+); không phải vấn đề cho công cụ nội bộ nhưng ghi chú lại phòng khi debug trên trình duyệt cũ.

### 3.14 Bug fix — vào được `/admin` một lúc rồi tự đá về login (2026-07-04)
User test thật trên trình duyệt (Cốc Cốc) phát hiện: đăng nhập xong vào được `/admin`, nhưng **ngay sau đó** tự động bị đá về `/admin/login?returnUrl=admin` (chú ý: không có dấu `/` trước "admin" — đây là dấu hiệu nhận diện bug, xem bên dưới).

**Nguyên nhân:** policy scheme ở mục 3.12 chọn scheme theo path kiểu "mặc định JWT, riêng `/admin/**` mới dùng Cookie". Nhưng circuit SignalR (Blazor Server dùng để "kích hoạt" tương tác sau khi trang đã render tĩnh xong) kết nối qua 1 path nội bộ của framework (không phải `/admin`) → request đó rơi vào nhánh JWT → không có Bearer token → coi như anonymous → circuit vừa kết nối xong thấy "chưa đăng nhập" → `AuthorizeRouteView` tự nhảy `NotAuthorized` → `RedirectToLogin.razor` (dùng `NavigationManager.ToBaseRelativePath` nên ra `returnUrl=admin` không có `/`) → đá về login. Đây là lý do trang admin "hiện ra một lúc rồi mới đá về" — lúc render tĩnh ban đầu (path `/admin`, đúng Cookie) thì vào được, lúc circuit kết nối (path khác, sai JWT) mới bị đá.

**Cách sửa:** đảo ngược logic chọn scheme — **mặc định dùng Cookie, chỉ path bắt đầu bằng `/api` mới dùng JWT** (`Program.cs`, đoạn `ForwardDefaultSelector`). Vì toàn bộ API thật của app đều nằm dưới `/api/**` (đã kiểm tra tất cả Controller), cách này an toàn và không phụ thuộc vào việc phải biết chính xác path nội bộ của Blazor SignalR là gì.
- Đã verify lại qua `curl` toàn bộ 4 bước: `/admin` chưa đăng nhập → redirect login; đăng nhập → cookie set đúng; `/admin` với cookie → 200; **API JWT vẫn hoạt động y hệt** (có token → 200, không token → 401) — không bị ảnh hưởng bởi thay đổi.
- ⚠️ Bug này **không thể phát hiện qua `curl`** (curl không mô phỏng kết nối SignalR/circuit) — chỉ lộ ra khi user test tay bằng trình duyệt thật. Bài học: mọi thay đổi liên quan tới auth scheme của Blazor Server bắt buộc phải test bằng trình duyệt thật, không chỉ tin vào kết quả `curl`.

⚠️ **Việc tiếp theo cho Blazor admin:** user cần xác nhận lại bằng trình duyệt thật rằng bug đã hết trước khi xây tiếp; sau đó xây từng màn quản lý thật (thay `ComingSoon.razor`) — bắt đầu từ mục nào do user chỉ định; có thể tái dùng `MainLayout`/`StatusDialogService`/design tokens hiện có.

### 3.15 Backend — List + tìm kiếm Giảng viên/Sinh viên (2026-07-04, lỗ hổng cũ đã lấp)
Trước khi xây Blazor cho 2 mục "Giảng viên"/"Sinh viên", đã khảo sát: 8/10 mục sidebar admin đã có sẵn service CRUD đầy đủ (Faculty/Department/Major/Program/Course/AcademicTerm/AdminClass/CourseOffering/Document) — **tái dùng thẳng, không viết thêm**. Riêng Giảng viên/Sinh viên (`ProfileService`) trước đó chỉ có lấy/tạo/sửa theo 1 `userId`, chưa có list toàn bộ — đúng lỗ hổng đã ghi ở mục 5 các phiên trước.

**Đã thêm (tái dùng DTO có sẵn, không tạo DTO mới):**
- `ProfileService.LayDanhSachSVAsync(page, pageSize, timKiem?, adminClassId?)` → `PagedResult<StudentProfileDto>` — tìm theo `FullName`/`LoginCode` chứa `timKiem`, lọc theo lớp hành chính.
- `ProfileService.LayDanhSachGVAsync(page, pageSize, timKiem?, facultyId?, departmentId?)` → `PagedResult<LecturerProfileDto>` — tương tự, lọc theo khoa/bộ môn.
- `GET /api/profiles/students?page=&pageSize=&search=&adminClassId=` và `GET /api/profiles/lecturers?page=&pageSize=&search=&facultyId=&departmentId=` — cả 2 `[Authorize(Policy = "AccountProvisioning")]` (chỉ Admin/AcademicOffice; khác endpoint lấy-theo-ID cũ đang mở cho mọi role, vì đây là danh sách toàn bộ người dùng — dữ liệu nhạy cảm hơn).
- Verify qua `curl`: list/search đúng dữ liệu thật, `lecturer01` gọi bị `403`, không token bị `401`, tìm không khớp trả mảng rỗng (không lỗi).
- ⚠️ **Lưu ý số liệu lệch (không phải bug):** KPI Dashboard (mục 3.13) đếm **User có role Student/Lecturer** (4 SV / 2 GV theo UserRoles), còn list mới này chỉ trả về user **đã có `StudentProfile`/`LecturerProfile`** (hiện chỉ 1/1) — 2 khái niệm khác nhau (có role ≠ đã tạo hồ sơ), là dữ liệu seed thật chưa đủ profile, không cần sửa gì.

⚠️ **Việc tiếp theo:** xây Blazor page cho Giảng viên/Sinh viên dùng 2 endpoint mới này (thay `ComingSoon.razor`), rồi lần lượt các mục còn lại.

### 3.16 Blazor — trang Sinh viên & Giảng viên đầu tiên (2026-07-04, pattern mẫu cho các mục còn lại)
Xây xong 2 trang Blazor thật đầu tiên, thay `ComingSoon.razor` cho 2 mục sidebar:
- `Components/Pages/Students.razor` (route `/admin/students`) và `Lecturers.razor` (route `/admin/lecturers`) — cùng 1 pattern: gọi thẳng `ProfileService` (đã đăng ký DI sẵn) qua `LayDanhSachSVAsync`/`LayDanhSachGVAsync` (mục 3.15), ô tìm kiếm (debounce bằng Enter hoặc nút "Tìm"), bảng dữ liệu (`.data-table`), badge trạng thái màu cho SV (`.badge-success/info/danger`), phân trang Trước/Sau (`.pagination`), empty-state khi không có kết quả.
- **Lỗi cú pháp gặp phải:** không thể viết lambda inline `@oninput="e => ... ?? \"\""` trong thuộc tính Razor — dấu `\"` escape không hợp lệ trong ngữ cảnh này (`CS1525`/`CS1056`). Phải tách ra thành method riêng (`XuLyGoTim(ChangeEventArgs e)`) trong `@code`. **Áp dụng cho mọi trang Blazor sau này:** không escape quote trong lambda inline ở attribute, luôn tách method nếu cần literal string.
- Đã nối `NavMenu.razor` (2 mục Giảng viên/Sinh viên trỏ thẳng route thật, hết `Lien(...)`) và `Home.razor` (2 thẻ lối tắt tương ứng).
- CSS mới trong `site.css`: `.page-header/.page-title`, `.toolbar`, `.search-input`, `.data-table`, `.badge-*`, `.pagination` — dùng chung design tokens đã có (mục 3.13), sẽ tái dùng nguyên xi cho các trang list còn lại (Khoa/Môn học/...).
- Verify qua `curl`: cả 2 trang trả `200` với dữ liệu thật (`student01`/`Trần Thị B`/`KTPM2023A`/`Đang học`, `lecturer01`/`Nguyễn Văn A`/`Thạc sĩ`/khoa+bộ môn đúng), sidebar highlight đúng mục đang chọn (`admin-nav__link active`).
- ⚠️ Tương tác thật (gõ tìm kiếm, bấm phân trang) **chưa click-test qua trình duyệt** — cùng giới hạn `curl` như các mục trước, cần user xác nhận bằng mắt.

⚠️ **Việc tiếp theo:** dùng lại đúng pattern này (service DI → bảng → tìm kiếm → phân trang) cho các mục sidebar còn lại theo thứ tự do user chọn (Khoa/Bộ môn/Ngành/Chương trình/Môn học/Học kỳ/Lớp hành chính/Lớp học phần/Tài liệu).

### 3.17 Blazor — render toàn bộ 9 mục sidebar còn lại (2026-07-04, tất cả list-only, chưa CRUD)
Nhân bản pattern mục 3.16 sang toàn bộ sidebar còn lại. Tất cả đều **chỉ đọc (list + phân trang), chưa có tạo/sửa/xoá** — đúng scope "render" user yêu cầu, không tự ý mở rộng thêm CRUD.

**8 trang read-only đơn giản** (gọi thẳng service có sẵn qua DI, không cần code backend mới):
- `Faculties.razor` (`/admin/faculties`) → `FacultyService.GetListAsync`
- `Departments.razor` (`/admin/departments`) → `DepartmentService.LayDanhSachAsync`
- `Majors.razor` (`/admin/majors`) → `MajorService.GetListAsync`
- `Programs.razor` (`/admin/programs`) → `ProgramService.GetListAsync`
- `Courses.razor` (`/admin/courses`) → `CourseService.GetListAsync`
- `AcademicTerms.razor` (`/admin/academic-terms`) → `AcademicTermService.LayDanhSachAsync`
- `AdminClasses.razor` (`/admin/admin-classes`) → `AdminClassService.LayDanhSachAsync`
- `CourseOfferings.razor` (`/admin/course-offerings`) → `CourseOfferingService.LayDanhSachAsync`, có badge màu theo `Status` (Đang mở/Đã hủy)

**`Documents.razor` (`/admin/documents`) phức tạp hơn — cần 1 controller mới:**
- UI: dropdown chọn Môn học (load từ `CourseService`) → hiện danh sách tài liệu **chung của môn đó** (`DocumentService.LayDanhSachAsync(courseId, null, userId, isStaff:true)`). Chưa hỗ trợ xem tài liệu theo lớp học phần (`CourseOfferingId`) — để sau nếu cần.
- ⚠️ **Vấn đề phát hiện khi làm:** link tải file không thể trỏ thẳng `/api/documents/{id}/download` như bên Flutter, vì path đó giờ chỉ nhận JWT (mục 3.14 đã đổi `/api/**` → JWT-only) — trang Blazor chỉ có Cookie, không có JWT, sẽ bị 401. **Giải pháp:** thêm controller mới `Controllers/Admin/AdminDocumentsController.cs`, route `GET /admin/documents/{id}/download` (nằm ngoài `/api`, dùng Cookie, `[Authorize(Policy="AccountProvisioning")]`), gọi lại `DocumentService.LayFileDeTaiAsync` y hệt endpoint API. **Quy tắc rút ra cho các tính năng sau:** bất kỳ action nào trang Blazor cần gọi (đặc biệt là action ghi/tải file, không phải page điều hướng) đều phải có route riêng ngoài `/api/**`, không dùng chung endpoint với Flutter/API JWT.
- `NavMenu.razor` và `Home.razor` đã cập nhật hết — không còn mục nào trỏ `ComingSoon.razor` ngoại trừ **Bộ môn, Chương trình đào tạo, Lớp hành chính** không có trên lưới lối tắt Dashboard (vẫn có trang thật, chỉ là dashboard chỉ hiện 8 ô đại diện — xem sidebar để vào đủ 3 mục này).
- Verify qua `curl`: cả 9 route trả `200` với dữ liệu thật đúng (Khoa/Bộ môn/Ngành/CTĐT/Môn học/Học kỳ/Lớp hành chính/Lớp học phần/dropdown môn học của Tài liệu); route tải file admin (`/admin/documents/2/download`) trả đúng file bằng cookie.
- ⚠️ Tương tác thật (chọn dropdown, phân trang nhiều trang) **chưa click-test qua trình duyệt** — cần user xác nhận.

⚠️ **Việc tiếp theo:** toàn bộ 10 mục sidebar giờ đã có trang thật (đọc dữ liệu). Còn thiếu: (1) CRUD thật (tạo/sửa/xoá) cho từng mục — hiện chỉ đọc; (2) tài liệu theo lớp học phần (`CourseOfferingId`) trong `Documents.razor`; (3) `Coming Soon.razor` giờ không còn nơi nào trỏ tới, có thể xoá nếu không dùng nữa (chưa xoá, để phòng khi cần placeholder cho tính năng mới).

### 3.18 Blazor — CRUD thật cho Khoa/Lớp hành chính/Lớp học phần/Giảng viên/Sinh viên + tạo tài khoản nhân viên (2026-07-04)
Theo yêu cầu "Nhóm 2" (thu hẹp phạm vi từ đề xuất ban đầu — chỉ 4 mục + 1 tính năng mới, không làm Bộ môn/Ngành/Chương trình/Môn học/Học kỳ ở vòng này). **Không cần viết backend mới** cho 3/4 mục đầu — khảo sát xác nhận `FacultyService`/`AdminClassService`/`CourseOfferingService` đã có sẵn đủ `Create/Update/Deactivate` (hoặc Huỷ/ĐổiGV/GánSV) từ trước.

**Quyết định đã chốt với user trước khi code (đúng yêu cầu "cân nhắc trước khi làm"):**
- Sửa Sinh viên: **chỉ đổi Trạng thái** (Đang học/Tốt nghiệp/Nghỉ học), không đổi Lớp hành chính — dùng đúng API có sẵn, không viết thêm backend.
- **Không xây tính năng Xoá/Vô hiệu hoá cho hồ sơ Giảng viên/Sinh viên** — user tự đặt câu hỏi ngược "viết xóa trong database có sai quy tắc nghề nghiệp không" và tự kết luận không cần; khớp với convention đã ghi trong `BACKEND_DESIGN_RULES.md` (soft-delete, không hard-delete) — tài khoản User nên khoá ở cấp `Users.Status`, không phải xoá cấp Profile.
- **Tạo tài khoản nhân viên**: user làm rõ đây là tài khoản "nhân viên cấp cao/quản lý" của trường → giới hạn 3 vai trò **Admin/AcademicOffice/DepartmentStaff** (không gồm Lecturer/Student — 2 vai trò đó đã có luồng tạo riêng gộp trong chính trang Giảng viên/Sinh viên).

**Cách "Tạo" Giảng viên/Sinh viên hoạt động (2 bước gộp làm 1 form):**
Vì `ProfileService.TaoProfileGVAsync/TaoProfileSVAsync` yêu cầu **User đã tồn tại sẵn** (chỉ tạo hồ sơ gắn vào user có sẵn, không tạo tài khoản) — form "+ Thêm giảng viên/sinh viên" gộp cả 2 bước: (1) gọi `IAuthService.RegisterAsync` (inject thẳng qua DI, KHÔNG gọi qua `/api/auth/register` vì path đó giờ chỉ nhận JWT — xem mục 3.14/3.17 về nguyên tắc "mọi action Blazor cần route riêng ngoài `/api/**`", ở đây giải quyết gọn hơn nữa bằng cách bỏ qua HTTP hoàn toàn, gọi service C# trực tiếp); (2) `RegisterAsync` không trả về `UserId` mới (chỉ trả `AuthResult.Ok()` rỗng) → phải tự query `Db.Users.Where(LoginCode=...).Select(UserId).FirstAsync()` ngay sau đó để lấy `UserId` vừa tạo, rồi mới gọi `TaoProfileGVAsync/TaoProfileSVAsync`.
- Kiểm tra trùng `LoginCode` được làm thủ công trước (giống pattern `AdminAuthController`) vì `RegisterAsync` tự nó cũng check trùng nhưng thông báo lỗi chung chung — check trước cho thông báo rõ ràng hơn qua `StatusDialogService` (cảnh báo cam thay vì lỗi đỏ).

**File đã tạo/sửa:**
- CSS mới dùng chung: `.modal-overlay/.modal-card/.form-group/.form-row/.form-checkboxes/.modal-actions/.form-error/.row-actions` trong `site.css` — mọi form Tạo/Sửa sau này tái dùng nguyên bộ này.
- `Faculties.razor`: + Thêm khoa / Sửa / Vô hiệu hoá.
- `AdminClasses.razor`: + Thêm lớp (chọn Chương trình) / Sửa (tên, cố vấn) / Vô hiệu hoá / Gán sinh viên (nhập UserId).
- `CourseOfferings.razor`: + Thêm lớp học phần (chọn Môn học/Học kỳ/Giảng viên) / Sửa (sức chứa, lịch, phòng) / Huỷ lớp / Đổi giảng viên.
- `Lecturers.razor`: + Thêm giảng viên (tài khoản + Khoa/Bộ môn/học hàm gộp 1 form) / Sửa hồ sơ (Khoa/Bộ môn/học hàm).
- `Students.razor`: + Thêm sinh viên (tài khoản + Lớp hành chính/khoá gộp 1 form) / Sửa trạng thái.
- `StaffAccounts.razor` (route mới `/admin/accounts/new`): form tạo tài khoản Admin/AcademicOffice/DepartmentStaff, thêm mục sidebar "➕ Tạo tài khoản nhân viên".
- `Program.cs`: đăng ký thêm không cần gì mới (mọi service dùng đều đã có sẵn trong DI).
- `_Imports.razor`: thêm `@using Microsoft.EntityFrameworkCore` và `@using SmartUniversity.Models` toàn cục (nhiều trang cần query `SmartUniversityContext` trực tiếp).
- Verify qua `curl`: cả 6 route (`faculties`, `admin-classes`, `course-offerings`, `lecturers`, `students`, `accounts/new`) trả `200`, đúng nút/checkbox render (Thêm khoa, Gán SV, Đổi GV, Huỷ lớp, Thêm giảng viên, Thêm sinh viên, 3 checkbox vai trò).
- ⚠️ **QUAN TRỌNG — giới hạn đã nói rõ với user:** `curl` chỉ verify được HTML render ban đầu, **không thể click nút/mở modal/submit form** vì toàn bộ thao tác Tạo/Sửa/Xoá là tương tác Blazor Server qua circuit SignalR (event `@onclick`), không phải HTTP request/response độc lập. **Toàn bộ 6 luồng CRUD trong mục này CHƯA được click-test qua trình duyệt thật** — cần user tự bấm thử (mở modal, điền form, lưu, xem `StatusDialogHost` báo thành công/lỗi, xem bảng có tự làm mới không).

⚠️ **Việc tiếp theo:** (1) User click-test 6 luồng CRUD mới; (2) nếu ổn, cân nhắc làm nốt CRUD cho Bộ môn/Ngành/Chương trình/Môn học/Học kỳ (đã có backend, chỉ còn nối UI, theo đúng pattern vừa dùng); (3) Documents theo `CourseOfferingId`.

### 3.19 Blazor — CRUD + tìm kiếm + chi tiết cho 5 mục còn lại: Bộ môn/Ngành/CTĐT/Môn học/Học kỳ (2026-07-04)
User xác nhận 6 luồng CRUD mục 3.18 ổn, yêu cầu nhân rộng sang 5 mục còn lại — **gồm cả curriculum/prerequisite UI** (user chọn scope rộng khi được hỏi), không chỉ CRUD cơ bản.

- **CRUD cơ bản** (Tạo/Sửa/Vô hiệu hóa, trừ AcademicTerm không có Vô hiệu hóa vì service không hỗ trợ) cho cả 5 trang, tái dùng đúng pattern `.modal-overlay`/`StatusDialogService.ChayAsync` từ mục 3.18. Không viết thêm backend — mọi service đã có sẵn `Create/Update/Deactivate` từ Phase 2.
- **Curriculum UI (Programs.razor):** modal "Môn học" — xem/thêm/xoá môn học trong 1 chương trình đào tạo (`ProgramService.AddCourseAsync/RemoveCourseAsync/GetCoursesAsync`, đã có sẵn).
- **Prerequisite UI (Courses.razor):** modal "Tiên quyết" — xem/thêm/xoá môn tiên quyết (`CourseService.AddPrerequisiteAsync/RemovePrerequisiteAsync/GetPrerequisitesAsync`, đã có sẵn).
- **Tìm kiếm + Xem chi tiết** (yêu cầu thêm ngay sau đó, xem bên dưới) áp dụng luôn cho cả 5 trang này cùng lúc với 2 trang cũ hơn (Students/Lecturers).

**Tìm kiếm — 3 vòng lặp cải tiến trong cùng phiên:**
1. Thêm search param tùy chọn (trailing, backward-compatible) vào 5 service list method (`DepartmentService.LayDanhSachAsync`, `MajorService/ProgramService/CourseService.GetListAsync`, `AcademicTermService.LayDanhSachAsync`) — lọc theo Code/Name/ID (riêng AcademicTerm không có field tên/mã dạng chữ, chỉ lọc theo `AcademicTermId`/`AcademicYear`).
2. User yêu cầu lọc tức thời khi gõ (không cần bấm nút) → thêm debounce 400ms ban đầu, sau đó user yêu cầu bỏ hẳn debounce (lọc theo từng ký tự).
3. **Bug phát hiện khi user test tay:** gõ nhanh → "Đang tải" kẹt mãi, kể cả sau khi xóa hết ô tìm kiếm. **Nguyên nhân:** service (`ProgramService` etc.) dùng chung 1 `DbContext` theo scope Blazor circuit; gõ nhanh sinh nhiều lệnh gọi DB chồng lấn trên cùng context → EF Core ném lỗi ngầm "a second operation was started..." → `_dangTai` không bao giờ được set `false`. **Đã sửa:** `SemaphoreSlim` serialize truy vấn + kiểm tra lại `_searchRequestId` ngay sau khi giành lock (bỏ qua DB hoàn toàn nếu đã có lần gõ mới hơn) — vừa hết bug, vừa giảm tải hơn nữa. Đã lưu thành memory `feedback_blazor_live_search.md` (pattern dùng lại cho trang Blazor search mới sau này). User xác nhận "hoàn hảo" sau bản sửa cuối.
- **Xem chi tiết:** thêm nút "Chi tiết" mở modal read-only cho cả 5 trang — Departments/Majors/Programs/AcademicTerms hiện thông tin cơ bản + dữ liệu liên quan có sẵn trong `*DetailDto` (VD Major hiện danh sách Program con, Program hiện danh sách môn trong curriculum); **Courses hiện danh sách môn tiên quyết** (đúng yêu cầu "đối với môn học thì chi tiết về môn tiên quyết") — tách biệt với modal "Tiên quyết" (dùng để thêm/xoá).
- Verify: `dotnet build` sạch qua nhiều vòng sửa, verify route `200` qua `curl` sau mỗi lần build lại (phải `taskkill` process backend cũ trước khi build vì khoá DLL).
- ⚠️ User đã tự click-test tìm kiếm (xác nhận "hoàn hảo") — nhưng **CRUD cơ bản + curriculum/prerequisite modal của 5 trang này chưa click-test tay** (chỉ verify HTML render qua `curl`).

### 3.20 Blazor — Documents theo CourseOfferingId (2026-07-04)
`Documents.razor` trước đó chỉ xem được tài liệu chung theo Môn học (`CourseId` scope). Thêm dropdown thứ 2 "Lớp học phần" (load theo `courseId` đã chọn) để xem tài liệu riêng theo `CourseOfferingId`.
- Backend: thêm tham số `courseId` tùy chọn vào `CourseOfferingService.LayDanhSachAsync` (trailing, backward-compatible); thêm field `TermName` vào `CourseOfferingListDto` (chuyển từ `CourseOfferingDetailDto` lên base, xóa khai báo trùng) để dropdown phân biệt các lớp học phần cùng môn khác kỳ/giảng viên.
- Đã tạo sẵn 1 tài liệu test qua API (`lecturer01` upload vào offering `IT001_HK1_2024`, id=4) để user có dữ liệu click-test ngay, không cần tự lên Flutter/API tạo trước.
- User đã **click-test thành công qua trình duyệt thật**: chọn môn IT001 → chọn lớp `IT001_HK1_2024` → bảng đổi đúng sang tài liệu riêng của lớp (người upload "Giảng viên Nguyễn Văn A") → tải xuống OK; chuyển lại "Tài liệu chung" → đúng tài liệu khác (người upload "Quản trị viên hệ thống", vì course-scope chỉ staff mới upload được) → tải xuống OK. **Tính năng đã verify đầy đủ, không chỉ qua `curl`.**

### 3.21 Flutter — Documents UI (Phase 5 hoàn tất, 2026-07-04)
Xây xong 3 tính năng còn thiếu của Phase 5 (Module 5.2, roadmap 0/3 → 3/3): danh sách/tải lên/tải xuống tài liệu.
- **Package mới:** `file_picker` (chọn file upload), `path_provider` (lưu file tải về vào thư mục Downloads). **Quyết định đã hỏi user trước khi code:** chỉ lưu file vào Downloads, KHÔNG tự động mở bằng app mặc định (user chọn phương án đơn giản hơn, tránh thêm package mở-file đa nền tảng như `open_filex` — đỡ rủi ro tương thích Windows desktop + Android cùng lúc).
- **File mới:** `lib/data/models/document.dart` (`DocumentItem`), `lib/data/services/document_service.dart` (`layDanhSach/upload/taiVe/voHieuHoa`, multipart qua `http.MultipartRequest` — `AuthenticatedClient` tự gắn Bearer token vì extends `http.BaseClient`), `lib/features/academic/screens/document_list_screen.dart` (1 màn dùng chung cho cả 2 scope `courseId`/`courseOfferingId`, có `assert` bắt buộc đúng 1 trong 2).
- **Entry point:** nút icon "📁 Tài liệu" luôn hiện cho mọi role trong `course_offering_list_screen.dart` (tài liệu riêng theo lớp học phần) và `course_list_screen.dart` (tài liệu chung theo môn học) — theo đúng convention đã dùng cho nút điểm danh: chỉ gate quyền thô ở client (`coTheTaiLen` dựa vào role), quyền thật do server quyết định (403 nếu không đúng chủ lớp).
- `flutter pub get` + `flutter analyze` sạch (không lỗi/warning mới, chỉ còn 2 warning cũ đã biết).
- ⚠️ **CHƯA click-test trên thiết bị/app thật** (chọn file, tải lên, xem danh sách, tải xuống lưu vào Downloads) — chỉ mới verify tĩnh qua `flutter analyze`, cần user tự chạy app xác nhận.
- Roadmap Phase 5 giờ **100% (16/16)**.

### 3.22 Blazor CRUD (mục 3.19) đã click-test thật qua Playwright — PASS toàn bộ (2026-07-05)
Vì Claude không thể tự bấm chuột/gõ phím vào trình duyệt của user, đã tự cài Playwright + Chromium (`npm install playwright && npx playwright install chromium` trong thư mục scratchpad, không commit vào repo) và viết script điều khiển trình duyệt thật (đăng nhập qua form POST thật, click nút mở modal, điền input, submit, đọc lại DOM) — đây là tương tác SignalR circuit thật, khác hẳn `curl`.

Kết quả: **Departments, Majors, Programs (+ thêm/xoá môn curriculum), Courses (+ chi tiết + thêm/xoá môn tiên quyết), AcademicTerms** — Tạo/Sửa/Vô hiệu hóa (trừ AcademicTerm không có Vô hiệu hóa) đều PASS, 0 console error trong cả 3 lượt chạy script. → **Mối lo "chưa click-test CRUD cơ bản" ở mục 3.19/5 (bản cũ) đã được giải quyết**, không cần user tự làm lại việc này nữa.

Cũng đã thử tự động hoá test Flutter Documents UI (mục 3.21) qua Playwright bằng cách chạy `flutter run -d web-server` — **không thành công**: màn hình chọn vai trò render đúng lần đầu (0 lỗi) nhưng các lần sau bị trắng trơn dù chờ tới 18s (nghi do tài nguyên/trạng thái server dev khi nhiều trình duyệt tự động kết nối liên tục, không phải lỗi code — không có exception/request lỗi nào). App thật chạy trên Windows desktop/Android chứ không phải web, nên việc này cần user tự test tay như cũ.

### 3.23 Bug nghiêm trọng — Flutter Windows: đăng nhập xong gọi API nào cũng bị đá về màn đăng nhập (2026-07-05)
User tự chạy `flutter run -d windows` để test Documents UI (theo mục 3.22), phát hiện: đăng nhập được vào trang sinh viên, nhưng bấm "Đăng ký" 1 lớp học phần là **lập tức bị đá về màn chọn vai trò/đăng nhập** — và đăng nhập lại cũng bị đá ngay, **dù tài khoản nào (student/lecturer) cũng vậy**.

**Quá trình chẩn đoán** (không đoán mò — mỗi bước đều verify bằng dữ liệu thật):
1. Test `curl` lại đúng luồng login → `/api/auth/me` → enroll bằng token thật của `student01` — backend trả `200`/lỗi nghiệp vụ `400` bình thường, **không hề có 401**. → Loại trừ backend, lỗi nằm ở Flutter client.
2. Thử tự động hoá lại bằng Playwright trên Flutter web — dính đúng vụ trắng màn hình ở mục 3.22, không dùng được để chẩn đoán.
3. Chạy thẳng `flutter run -d windows` với log ra file, nhờ user tự thao tác lại trong lúc theo dõi log real-time (Claude không tự bấm được vào cửa sổ native Windows).
4. Log lần 1 (thêm print tạm vào `AuthenticatedClient.send()`) cho thấy: **MỌI request đều `hasAuthHeader=false`** ngay từ request đầu tiên (`GET /api/auth/me`) — nghĩa là chưa từng gắn được Bearer token, không phải do request "Đăng ký" cụ thể gây ra (cảm giác "bấm Đăng ký mới bị đá" chỉ là trùng thời điểm — vòng lặp 401→refresh-fail→logout đã chạy ngầm ngay sau khi login xong, user chỉ tình cờ bấm Đăng ký đúng lúc nó xảy ra).
5. Giả thuyết đầu (sai): 6 chỗ tạo `TokenStorage()` độc lập rải rác (`main.dart`, `auth_service.dart` default, `app_shell.dart`, `profile_screen.dart`, `splash_screen.dart`, `workspace_screen.dart`) → hợp nhất thành 1 biến `tokenStorage` global, truyền tay khắp nơi. **Không sửa được bug** — vì `FlutterSecureStorage(...)` được khai báo `const`, Dart tự canonical hóa nên dù bao nhiêu `TokenStorage()` cũng cùng trỏ về đúng 1 object, không phải vấn đề "nhiều instance".
6. Thêm print trực tiếp vào `TokenStorage.saveTokens/readAccessToken/readRefreshToken` để in độ dài giá trị thật. Kết quả: `saveTokens done, accessToken.length=376` rồi **`immediate read-back after save: NULL`** — ghi xong, đọc lại NGAY bằng chính object đó (không có race giữa nhiều instance) vẫn ra null. → **Xác nhận đây là bug thật của package `flutter_secure_storage` trên Windows**: `write()` không throw lỗi nhưng chưa flush kịp để `read()` ngay sau đó thấy được.

**Cách sửa:** thêm 1 lớp cache trong bộ nhớ (`_cachedAccessToken`/`_cachedRefreshToken`/`_cachedRolesRaw`) ngay trong `TokenStorage` (`lib/data/services/token_storage.dart`) — `saveTokens()` cập nhật cache trước khi ghi storage thật; mọi `readAccessToken()/readRefreshToken()/readRoles()` ưu tiên đọc cache, chỉ hỏi storage thật khi cache rỗng (trường hợp mới mở app, storage đã có đủ thời gian flush từ phiên trước). Né hẳn race của plugin mà không cần chờ fix từ thư viện. Đã xoá sạch mọi `print` debug tạm sau khi xác nhận nguyên nhân.

- **Giữ lại thay đổi hợp nhất `TokenStorage()` ở bước 5** dù không phải nguyên nhân chính — vẫn là thực hành đúng (tránh tạo nhiều instance không cần thiết), không hại gì.
- `flutter analyze` sạch sau mỗi lần sửa. User xác nhận bug đã hết sau bản sửa cache.
- ⚠️ Bug này **chỉ xảy ra trên Windows desktop** (chưa rõ có ảnh hưởng Android/iOS hay không — nhiều khả năng KHÔNG, vì `EncryptedSharedPreferences`/Keychain trên các nền tảng đó không có kiểu race này) — nếu sau này build Android/iOS mà gặp lại triệu chứng tương tự, cache này vẫn vô hại và tiếp tục có tác dụng phòng ngừa.
- Bài học giống mục 3.14: bug tầng auth/session **không thể phát hiện qua `curl`**, chỉ lộ ra khi chạy app thật. Lần này còn khó hơn vì cả Playwright (web) cũng không dùng được — phải chạy trực tiếp lên thiết bị thật (`flutter run -d windows`) + log file + nhờ user thao tác tay mới bắt được.

### 3.24 Bug 3.23 chưa hết hẳn — mất phiên đăng nhập sau khi tắt/mở lại app (2026-07-05, cùng ngày)
User phát hiện thêm: bug 3.23 (bị đá về login *trong* phiên chạy) đã hết sau bản vá cache, nhưng **tắt hẳn app rồi mở lại thì luôn bị bắt đăng nhập lại** — dù `login_screen.dart` có checkbox "Remember me" mặc định bật và `AuthService.login()` luôn gọi `saveTokens()` vô điều kiện (ý đồ thiết kế rõ ràng: phải nhớ phiên qua lần tắt/mở, đây **là bug chứ không phải cơ chế cố ý**).

**Nguyên nhân:** bản vá cache ở mục 3.23 chỉ che được triệu chứng *trong cùng 1 tiến trình* — cache mất theo tiến trình khi tắt app, lúc mở lại `SplashScreen.hasSession()` phải đọc thật từ storage.

**Verify việc ghi xuống đĩa có bao giờ thành công không** (không đoán mò): thêm code test tạm — sau `saveTokens()`, hẹn giờ đọc thẳng qua `_storage` gốc (bỏ qua cache) ở các mốc 3s/10s/30s. Kết quả cả 3 mốc: **`VẪN NULL`**. → Đây không phải race/chậm-flush như tưởng ở mục 3.23, mà là **ghi thất bại vĩnh viễn thật sự** của `flutter_secure_storage_windows` bản đang dùng (4.1.0) trên máy này.

**Thử nâng cấp package (KHÔNG thành công — đã revert, không đi lại đường này nữa):**
1. `flutter_secure_storage_windows` mới hơn (4.1.0 → 4.2.2) là dependency gián tiếp, bị khoá bởi ràng buộc của package chính `flutter_secure_storage: ^10.3.1`. Ép bằng `dependency_overrides: flutter_secure_storage_windows: ^4.2.2` → lỗi resolve: bản 4.2.2 cần `win32 ^6.0.1`, nhưng `file_picker` (đang dùng cho Documents UI, mục 3.21) chỉ hỗ trợ `win32 ^5.x`.
2. Thử nâng `file_picker` lên bản hỗ trợ `win32 ^6` → chỉ có bản **beta** (`^12.0.0-beta.7`) làm được, nhưng bản beta này **đổi breaking API** (`FilePicker.platform` không còn tồn tại) → vỡ `document_list_screen.dart`. Không dùng bản beta cho 1 dependency cốt lõi.
3. Thử ép cả `win32: ^6.0.1` qua override, giữ `file_picker` bản cũ ổn định → `flutter analyze` sạch (vì chỉ check tầng Dart), nhưng **build native thật sự vỡ**: code Windows-implementation của chính `file_picker` (`file_picker_windows.dart`) dùng thẳng API `win32` (`COINIT_APARTMENTTHREADED`, `FOS_PICKFOLDERS`, `COMObject`, `GUID.createInstance`...) đã đổi/xoá giữa `win32` 5.x→6.x → hàng chục lỗi biên dịch C++/Dart FFI. → **Đã revert sạch `pubspec.yaml` về trạng thái không có `dependency_overrides`, `file_picker` về lại `^8.1.7`.** Kết luận: nâng cấp package không khả thi lúc này (phải chờ `flutter_secure_storage` chính thức nới ràng buộc windows, hoặc `file_picker` ra bản stable hỗ trợ `win32` 6.x).

**Fix thật (đã áp dụng):** bỏ hẳn `flutter_secure_storage` cho riêng Windows desktop, thay bằng 1 backend tự viết — file JSON cục bộ trong `getApplicationSupportDirectory()` (package `path_provider` đã có sẵn từ Phase 5 Documents). Chọn backend theo platform bằng **conditional import** (đúng pattern đã có sẵn ở `core/api_config.dart`/`_platform_io.dart`/`_platform_web.dart`):
- `lib/data/services/_token_platform_io.dart` — `laWindowsDesktop() => Platform.isWindows`.
- `lib/data/services/_token_platform_web.dart` — luôn `false` (web dùng `flutter_secure_storage` bình thường, implementation web riêng, không dính bug này).
- `lib/data/services/token_storage.dart` viết lại: thêm class `_WindowsFileTokenStore` (đọc/ghi 1 file `auth_session.json`, cache in-memory + lazy load), `TokenStorage` chọn `_dungFileBackend` khi **không** bị inject storage giả (giữ hành vi cũ cho test) **và** đang chạy Windows desktop thật.
- ⚠️ **Đánh đổi bảo mật đã cân nhắc và ghi rõ trong code:** file này KHÔNG mã hoá bằng DPAPI/Windows Credential Manager như secure storage thật — chỉ được bảo vệ ở mức "chỉ user hiện tại trên máy đọc được" (quyền thư mục AppData riêng của user). Chấp nhận được cho 1 app nội bộ chạy trên máy cá nhân/dev, **không phải mức bảo mật production-grade**. Nếu sau này deploy Windows cho nhiều người dùng cuối thật, cần quay lại vấn đề này (chờ fix từ thư viện, hoặc tự làm DPAPI qua FFI).
- Cache in-memory ở mục 3.23 vẫn giữ nguyên phía trên (không hại gì, vẫn có lợi về hiệu năng + phòng ngừa chung).
- `flutter analyze` sạch. ⚠️ **Đang test lại full chu trình** (đăng nhập → tắt hẳn app → mở lại → xem còn phiên không) khi phiên làm việc này tạm dừng — user báo "thấy nó thành công rồi" nhưng chưa xác nhận rõ ràng đây là app chạy được hay đúng luồng persist-qua-restart đã test xong; **cần user xác nhận lại rõ ràng ở phiên sau**.

### 3.25 Dashboard Sinh viên — thiết kế lại "Bento Box / Super App" (2026-07-05)
User yêu cầu đóng vai Senior Flutter Dev/UI-UX thiết kế lại hẳn Dashboard Sinh viên theo phong cách OneUni: Bento Box UI + Glassmorphism nhẹ, header động, Focus Card "lớp sắp diễn ra" có đếm ngược, Bento Grid bất đối xứng, animation staggered khi load + micro-interaction khi nhấn, empty state riêng, kiến trúc chia nhỏ widget + mock data qua model class.

**File mới:**
- `lib/data/models/dashboard_mock_data.dart` — `MotivationalQuote` (mock, chọn ổn định theo ngày), `DashboardFeatureConfig`/`BentoStatus` (cấu hình hiển thị, không chứa dữ liệu nghiệp vụ).
- `lib/features/academic/screens/dashboard/` — `dashboard_header.dart` (lời chào theo buổi thật + avatar + chuông thông báo mock có pulse + thẻ SV thu nhỏ), `digital_student_card_sheet.dart` (bottom sheet QR — mã hoá `loginCode` THẬT qua `qr_flutter` đã có sẵn, ghi rõ đây là thẻ định danh KHÁC với QR điểm danh xoay vòng của giảng viên), `next_class_card.dart` (Focus Card — tái dùng + nâng cấp logic lấy TKB THẬT từ bản dashboard cũ, thêm đếm ngược sống bằng `Timer.periodic`, lọc đúng buổi chưa kết thúc thay vì buổi sớm nhất bất kể đã qua; không có lớp → `DashboardEmptyState` + quote mock), `bento_grid_menu.dart` (1 tile "featured" + lưới còn lại, dùng `GridView` chuẩn — không thêm `flutter_staggered_grid_view` theo đúng yêu cầu tránh dependency rủi ro), `feature_bento_card.dart` (gradient, `AnimatedScale` khi nhấn, badge "Sắp ra mắt" + Snackbar cho tính năng chưa có backend), `dashboard_empty_state.dart` (animation "thở" bằng `ScaleTransition` thuần Flutter, không dùng Lottie vì chưa có asset/muốn tránh thêm package).
- `dashboard_screen.dart` viết lại: tách `_StudentDashboard` (layout Bento mới, `AnimationController` + `Interval` tạo hiệu ứng load lệch nhau từng section) và `_StaffDashboard` (giữ nguyên layout gradient-header cũ cho Giảng viên/Quản trị — ngoài phạm vi yêu cầu, không đụng vào để tránh phá vỡ trải nghiệm đã ổn định).

**Đã tự sửa lại phân loại "Active" của user:** user liệt kê "Điểm số" là tính năng đã có, nhưng Phase 7 (Analytics) thực tế **chưa build (0%)** → xếp lại vào "Sắp ra mắt" cùng Học phí/Tin tức, để không đánh lừa người dùng. Chỉ 3 tile thật sự Active (Đăng ký học phần, Chương trình đào tạo, Danh mục môn học) điều hướng tới **màn hình có thật, đã build sẵn từ trước** — không phải placeholder.

**Bug tự tìm ra khi verify:** build lần đầu bắn lỗi thật `RenderFlex overflowed by 0.609 pixels` tại `feature_bento_card.dart` (Column icon+label bị chật theo chiều dọc ở 1 số bề rộng màn hình cụ thể). Sửa bằng bọc `Flexible` quanh `Text` label + tăng `childAspectRatio` của grid từ 0.92 → 0.85 (chừa thêm chỗ theo chiều dọc). `flutter analyze` sạch, rebuild xác nhận hết overflow, app chạy ổn định (không còn "Lost connection to device" — lần crash trước đó là do chính thao tác PowerShell `SetForegroundWindow`/`GetWindowRect` của Claude can thiệp cửa sổ app, không phải lỗi code).

⚠️ **Chưa được user click-test trực tiếp** (chỉ mới xác nhận app chạy được, chưa phản hồi cụ thể về animation/Bento layout/QR sheet) — cần user tự xem và cho nhận xét ở phiên sau.

---

## 4. Sự thật cần sửa so với context cũ (đã kiểm chứng lại)

- **Mật khẩu test đúng là `Test@123`** (không phải `Abc@12345` như context cũ ghi — lấy từ `Seeding/DbSeeder.cs`).
- **`student02` KHÔNG tồn tại** trong DB — seed chỉ tạo `student01`. Đừng dùng tài khoản này.
- ROADMAP_PROJECT.md từng ghi sai % (Phase 1 ghi 77% dù thực tế 100%) — đã sửa lại đúng.

---

## 5. Đề xuất việc tiếp theo

⚠️ **Chưa commit** — toàn bộ mục 3.22–3.25 (Playwright test + fix `TokenStorage` 2 vòng (cache rồi file-backend Windows) + thiết kế lại Dashboard Sinh viên) **CHƯA được commit**. Mục 3.19–3.21 (Blazor CRUD 5 mục + Documents theo CourseOfferingId + Flutter Documents UI) trước đó **đã commit và push lên GitHub rồi** (xem mục 6). Đây là khối lượng thay đổi lớn nhất trong 1 phiên — commit sớm ở phiên sau, có thể tách 2 commit riêng (fix TokenStorage / redesign Dashboard) cho lịch sử rõ ràng hơn.

📌 **Ý tưởng cũ chưa build:** Bulk import Excel để tạo hàng loạt tài khoản sinh viên — đã ghi thành feature "PLANNED" trong `ROADMAP_PROJECT.md` Module 1.4 (Completion 0/8) và §6.10 trong `Smart_University_Handover_EN.md`.

✅ **Đã xong, không cần làm lại:**
- CRUD cơ bản + curriculum/prerequisite của 5 trang Blazor mục 3.19 — đã click-test thật qua Playwright (mục 3.22), PASS toàn bộ.
- Bug Flutter Windows "đăng nhập xong bị đá ra ngay *trong* phiên chạy" — đã fix bằng cache trong bộ nhớ (mục 3.23), **user đã xác nhận hết bug**.
- Bug Flutter Windows "mất phiên đăng nhập sau khi tắt/mở lại app" — nguyên nhân sâu hơn (`flutter_secure_storage_windows` ghi thất bại vĩnh viễn, không phải chỉ chậm — đã verify bằng test 3s/10s/30s), đã thử nâng cấp package nhưng bế tắc (xung đột `win32` với `file_picker`, xem mục 3.24 để KHÔNG lặp lại đường này), **fix thật bằng backend file JSON riêng cho Windows** (mục 3.24) — `flutter analyze` sạch, nhưng ⚠️ **chưa có xác nhận rõ ràng từ user rằng chu trình tắt→mở lại→còn phiên đã thật sự OK** (mới chỉ nghe "thấy nó thành công rồi", mơ hồ giữa "app chạy được" và "persist qua restart đã đúng").
- Dashboard Sinh viên đã thiết kế lại toàn bộ theo Bento Box UI (mục 3.25) — `flutter analyze` sạch, đã tự tìm+sửa 1 lỗi RenderFlex overflow thật, app chạy ổn định. ⚠️ **User chưa click-test/phản hồi cụ thể** (animation, Bento layout, QR sheet).

⚠️ **Việc ưu tiên #1 tiếp theo — cần user tự xác nhận rõ ràng bằng tay (không suy luận từ lời nói mơ hồ):**
1. **Test lại đúng chu trình:** đăng nhập → **tắt hẳn cửa sổ app** (không phải hot-reload/restart trong `flutter run`) → mở lại → xác nhận vào thẳng Dashboard, KHÔNG bị bắt đăng nhập lại. Đây là điều kiện để coi bug 3.24 thật sự đã xong.
2. **Xem + phản hồi Dashboard Bento mới** (mục 3.25) — animation staggered lúc load, hiệu ứng nhấn Bento card, mở thẻ SV điện tử xem QR, Focus Card đếm ngược.
3. **Flutter Documents UI** (mục 3.21) — chọn file tải lên, xem danh sách, tải xuống — chưa từng test được vì bị 2 bug trên chặn suốt từ đầu.

Sau khi xác nhận ổn, thứ tự ưu tiên tiếp theo:

1. **(Đợi điều kiện)** Phase 4 chỉ còn: test luồng quét QR + GPS thật trên điện thoại khi có máy (`attendance_session_screen.dart`/`qr_scan_screen.dart` đã build + wire xong, xem mục 3.11).
2. Phase 6 (Notification) → Phase 7 (Analytics) → Phase 8 (AI Assistant) — chưa bắt đầu, để cuối theo đúng thứ tự phụ thuộc roadmap gốc.
3. Bulk import Excel (xem §6.10 handover) nếu muốn quay lại hoàn thiện Phase 1 trước khi qua Phase 6+.

### Gợi ý prompt để mở phiên mới

```
Đọc CONTEXT.md (đặc biệt mục 3.24–3.25 và mục 5) và ROADMAP_PROJECT.md.
Tôi vừa test [chu trình tắt/mở lại app / Dashboard Bento mới / Flutter Documents UI] — [ổn cả / lỗi ở chỗ X].
Hãy [sửa lỗi / commit lại repo Flutter / bắt đầu Phase 6 Notification].
```

---

## 6. Trạng thái Git

| Repo | Commit mới nhất đã push | Nội dung |
|---|---|---|
| Flutter (`Smart_University_Management_Platform`) | `5307446` (đã push lên `origin/main`) | Phase 5 Documents UI (mục 3.21) |
| Backend (`SmartUniversity`, solution root) | `3684f7f` (đã push lên `origin/master`) | Blazor CRUD 5 mục còn lại + tìm kiếm + Documents theo CourseOfferingId (mục 3.19–3.20) |

⚠️ **CHƯA commit** (mục 3.23–3.25, phiên 2026-07-05) — khối lượng lớn, gợi ý tách 2 commit:
- **Fix TokenStorage (mục 3.23–3.24):** `lib/data/services/token_storage.dart` (viết lại: cache + backend file JSON riêng cho Windows), `lib/data/services/_token_platform_io.dart` + `_token_platform_web.dart` (mới), `lib/main.dart` (biến `tokenStorage` global), và các file dùng lại nó: `login_screen.dart`, `app_shell.dart`, `profile_screen.dart`, `splash_screen.dart`, `workspace_screen.dart`, `change_password_screen.dart`. Đây là bug chặn hoàn toàn việc dùng app trên Windows desktop.
- **Dashboard Bento redesign (mục 3.25):** `lib/data/models/dashboard_mock_data.dart` (mới), `lib/features/academic/screens/dashboard/` cả thư mục (mới), `lib/features/academic/screens/dashboard_screen.dart` (viết lại).
- `pubspec.yaml`/`pubspec.lock` **không có gì cần commit thêm** — thử nâng cấp package ở mục 3.24 đã bị revert sạch về đúng trạng thái đã push (`file_picker ^8.1.7`, không có `dependency_overrides`).

---

## 7. Current Tech Setup

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
