# Bối cảnh — Đăng ký học phần & Bảng điểm

## 1. Đăng ký học phần

Giả sử học kỳ 1 năm nay đang mở đăng ký. Hiển thị thẳng danh sách lớp học phần của kỳ đó cho sinh viên, không bắt chọn học kỳ trước. Sinh viên đăng ký, hệ thống giới hạn tổng số tín chỉ được đăng ký trong 1 kỳ (ví dụ 24 tín). Các môn đã đăng ký tự động thuộc về đúng học kỳ đó.

Giới hạn tín chỉ hiện để cứng cho mọi sinh viên (ví dụ 24) — nhưng thực tế các trường VN có trần thay đổi theo học lực (sinh viên diện cảnh báo học vụ bị giới hạn thấp hơn, ví dụ 14–17 tín). Không cần làm ngay, chỉ cần đặt con số này ở 1 hằng số riêng (kiểu `MAX_CREDITS_PER_TERM`) để sau này đổi thành logic động mà không phải sửa rải rác nhiều chỗ.

Ngoài giới hạn tín chỉ, đăng ký học phần còn thiếu: kiểm tra trùng giờ học giữa các lớp, kiểm tra môn tiên quyết trước khi cho đăng ký, và xếp hàng đợi (waitlist) khi lớp đầy chỗ.

## 2. Bảng điểm — Đậu/Rớt

Cần biết một môn sinh viên đã đăng ký là **Đậu** hay **Rớt** (không cần điểm số chi tiết, chỉ cần 2 trạng thái này). Đây là dữ liệu nền cho cả "Chương trình đào tạo" và "Danh mục môn học" bên dưới — nếu không có thông tin đậu/rớt thì không thể biết môn tiên quyết đã hoàn thành hay chưa, cũng không phân biệt được "chưa học" với "rớt".

## 3. Chương trình đào tạo

Mỗi môn trong chương trình đào tạo của sinh viên nên hiện 1 trong 3 trạng thái: **Đậu**, **Rớt (cần học lại)**, hoặc **Chưa học**. Không dùng 2 trạng thái tick/x đơn giản vì sẽ gộp nhầm "chưa học" với "rớt" — hai trường hợp SV cần xử lý khác nhau.

## 4. Danh mục môn học

Áp dụng đúng 3 trạng thái Đậu/Rớt/Chưa học như mục 3, dùng để lọc danh sách môn học đã học/chưa học cho sinh viên.
