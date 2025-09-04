# Hướng dẫn nhanh: Thêm ASP.NET Identity (giải thích dành cho học sinh lớp 5)

**Lưu ý ngắn (dành cho người làm kỹ thuật) — cô tóm tắt trước khi hướng dẫn các em:**

- "Đăng ký ASP.NET Identity" nghĩa là bật một bộ tính năng sẵn có để quản lý người dùng: lưu tên đăng nhập, mật khẩu, phân vai trò (Admin/Instructor/Learner), và xử lý đăng nhập/đăng xuất.
- Lưu ý: chương trình cần gọi đoạn cài đặt này trong Program.cs để hệ thống biết dùng Identity khi chạy.
- `AddEntityFrameworkStores<LmsDbContext>()` có nghĩa là: hãy dùng LmsDbContext (kết nối tới cơ sở dữ liệu) để lưu mọi thông tin người dùng và vai trò. Nói cách khác, Identity sẽ ghi dữ liệu vào những bảng trong database thông qua LmsDbContext.
- Sau khi thêm, cần bật middleware xác thực trong pipeline: `app.UseAuthentication()` và `app.UseAuthorization()` để cho phép kiểm tra ai được phép làm gì.
- Cuối cùng, phải tạo migration và cập nhật database (tạo bảng `AspNetUsers`, `AspNetRoles`, v.v.) — giống như xây tủ đựng thông tin người dùng trước khi sử dụng.

---

Xin chào các em! Hôm nay cô sẽ hướng dẫn các em từng bước rất đơn giản để thêm hệ thống quản lý người dùng vào chương trình. Cô nói chậm, rõ ràng để các em dễ hiểu nhé.

## 1. Sao lưu trước khi làm
- Cô khuyên các em hãy lưu lại mã trước khi sửa, giống như chụp ảnh trước khi thay đổi.
- Cách làm: chạy `git add .` rồi `git commit -m "backup trước khi thêm Identity"`.

## 2. Kiểm tra công cụ cần có
- Trước khi bắt đầu, cần kiểm tra xem đã có các gói phần mềm sau chưa:
  - Microsoft.AspNetCore.Identity.EntityFrameworkCore
  - Microsoft.EntityFrameworkCore.Design
  - Nếu dùng mã token để đăng nhập: Microsoft.AspNetCore.Authentication.JwtBearer
- Nếu thiếu, các em có thể cài bằng `dotnet add package <tên-package>`.

## 3. Kiểm tra "thẻ người dùng" và "tủ lưu"
- "Thẻ người dùng" là lớp AspNetUser — nơi lưu tên và mật khẩu của bạn.
- "Tủ lưu" là LmsDbContext — nơi chương trình cất thông tin vào cơ sở dữ liệu.
- Cần đảm bảo LmsDbContext biết cách làm việc với Identity (ví dụ: kế thừa hoặc cấu hình đúng).

## 4. Chuẩn bị khóa bí mật
- Khóa bí mật giống như chìa khóa nhà — giữ thật an toàn, không chia cho người khác.
- Lưu khóa vào user-secrets hoặc appsettings.Development.json.
- Ví dụ: `dotnet user-secrets init` và `dotnet user-secrets set "Jwt:Key" "<bí-mật>"`.

## 5. Thêm đăng ký Identity vào Program.cs
- Trong file Program.cs, cô sẽ thêm lệnh để bật hệ thống quản lý người dùng:
  - `services.AddIdentity<...>().AddEntityFrameworkStores<LmsDbContext>();`
  - Nếu dùng token JWT, thêm `services.AddAuthentication(...).AddJwtBearer(...);`
- Khi chạy ứng dụng, nhớ gọi:
  - `app.UseAuthentication();` trước
  - `app.UseAuthorization();` sau

## 6. Tạo migration để tạo bảng trong database
- Tạo migration giống như bản vẽ để xây tủ lưu trong database.
- Tạo migration: `dotnet ef migrations add Init_Identity -s LmsMini.Api -p LmsMini.Infrastructure`
- Áp migration: `dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure`

## 7. Tạo sẵn Roles và tài khoản admin
- Tạo các vai trò: Admin (người quản lý), Instructor (giáo viên), Learner (học sinh).
- Tạo một tài khoản admin ban đầu để quản lý hệ thống.
- Viết đoạn mã seed dùng RoleManager và UserManager và chạy khi ứng dụng khởi động; làm sao để chạy nhiều lần vẫn an toàn.

## 8. Kiểm tra bằng tay
- Dùng Postman hoặc Swagger để thử:
  - Đăng ký (register)
  - Đăng nhập (login)
  - Gọi endpoint đã bảo vệ để xem hệ thống có chặn khi chưa đăng nhập hay không

## 9. Giữ an toàn
- Không đưa khóa bí mật lên Git.
- Ở môi trường thật (production), ẩn hoặc giới hạn Swagger để không lộ thông tin.

## 10. Nếu có lỗi
- Nếu có vấn đề, các em có thể quay lại bản sao lưu (bước 1) hoặc phục hồi database từ bản backup.
- Luôn kiểm tra file migration trước khi áp vào database.

---
Tập tin này lưu tại: `LmsMini.Api/docs/identity/Identity_For_Grade5.md`