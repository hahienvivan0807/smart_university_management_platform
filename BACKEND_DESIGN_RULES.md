# BACKEND_DESIGN_RULES.md — Smart University

Quy tắc thiết kế code cho ASP.NET Core backend.

---

## Comment style

Chỉ viết một XML doc comment (`///`) ở đầu hàm mô tả **intent** (hàm này làm gì).
Không comment từng dòng code bên trong — code tự nói lên logic qua tên biến.

```csharp
/// Đăng ký học phần. Kiểm tra còn chỗ và chưa đăng ký trùng trước khi tạo Enrollment.
public async Task<EnrollmentDto> DangKyAsync(int userId, int courseOfferingId) { ... }
```

## Architecture

Controller → Service → DbContext. Controller không chứa business logic.

## DTOs

Chỉ expose DTO ở API boundary — không return EF entity, không return password/token hash.

## Soft delete

Dùng `IsActive = false`, không hard delete. Block deactivate nếu còn con đang active.
Ngoại lệ: `CourseOffering` dùng `Status` byte (1=Mở, 2=Hủy), không có `IsActive`.

## EF Core

- Dùng `FirstOrDefaultAsync` thay `FindAsync` trong Update/Deactivate — `FindAsync` bỏ qua global query filter.
- Khi check unique khi tạo mới: `.IgnoreQueryFilters()` để bắt được bản ghi đã deactivate.
- Mọi query `CourseOffering` phải `.IgnoreQueryFilters()`.

## Authorization

Đọc roles từ JWT claim — không bao giờ tin role do client tự gửi lên.

## Naming

| Phần | Quy tắc |
|---|---|
| DTO properties | Tiếng Anh |
| Biến local, tham số | Tiếng Việt ngắn |
| Tên method service | Tiếng Việt + Async |
| Tên action controller | Tiếng Việt |
