# Hướng dẫn nhanh: Thêm ASP.NET Identity (giải thích cho học sinh lớp 5)

Tài liệu này giải thích từng bước rất đơn giản để thêm hệ thống quản lý người dùng (ASP.NET Identity) vào dự án.

## 1. Sao lưu trước khi làm
- Giống như chụp ảnh trước khi sửa: lưu lại mã hiện có.
- Lệnh gợi ý: `git add .` rồi `git commit -m "backup trước khi thêm Identity"`.

## 2. Kiểm tra công cụ cần có
- Cần các gói (packages) giống như chuẩn bị bút và vở:
  - Microsoft.AspNetCore.Identity.EntityFrameworkCore
  - Microsoft.EntityFrameworkCore.Design
  - Nếu dùng token: Microsoft.AspNetCore.Authentication.JwtBearer
- Nếu thiếu, dùng `dotnet add package <tên-package>` để cài.

## 3. Kiểm tra "thẻ người dùng" và "tủ lưu"
- "Thẻ người dùng" = lớp AspNetUser (lưu thông tin người dùng).
- "Tủ lưu" = LmsDbContext (nơi lưu dữ liệu vào cơ sở dữ liệu).
- Phải đảm bảo LmsDbContext hỗ trợ Identity (ví dụ kế thừa IdentityDbContext hoặc có cấu hình phù hợp).

## 4. Chuẩn bị khóa bí mật
- Giống như chìa khóa nhà: không chia cho người lạ.
- Lưu bí mật (JWT key) trong user-secrets hoặc appsettings.Development.json.
- Ví dụ tạo user-secrets: `dotnet user-secrets init` và `dotnet user-secrets set "Jwt:Key" "<bí-mật>"`.

## 5. Thêm đăng ký Identity vào Program.cs
- Trong file Program.cs thêm:
  - `services.AddIdentity<...>().AddEntityFrameworkStores<LmsDbContext>();`
  - Nếu dùng JWT, thêm `services.AddAuthentication(...).AddJwtBearer(...);`
- Trong pipeline cần gọi:
  - `app.UseAuthentication();`
  - `app.UseAuthorization();`

## 6. Tạo migration để tạo bảng trong database
- Giống như xây tủ trước khi để đồ: tạo thay đổi cho database.
- Tạo migration: `dotnet ef migrations add Init_Identity -s LmsMini.Api -p LmsMini.Infrastructure`
- Áp migration: `dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure`

## 7. Tạo sẵn Roles và tài khoản admin
- Tạo vai trò: Admin, Instructor, Learner.
- Tạo 1 tài khoản admin để quản lý ban đầu.
- Viết code seed (dùng RoleManager và UserManager) và chạy khi app khởi động; làm sao cho an toàn nếu chạy nhiều lần (idempotent).

## 8. Kiểm tra bằng tay
- Dùng Postman hoặc Swagger để thử:
  - Đăng ký (register)
  - Đăng nhập (login)
  - Gọi endpoint cần bảo vệ (xem có bị chặn nếu chưa đăng nhập không)

## 9. Giữ an toàn
- Không đưa bí mật (keys) lên Git.
- Ẩn hoặc giới hạn Swagger trên môi trường production.

## 10. Nếu có lỗi
- Quay lại bản sao lưu (bước 1) hoặc khôi phục database từ bản backup.
- Kiểm tra file migration trước khi apply.

---
Tập tin này lưu tại: `LmsMini.Api/docs/identity/Identity_For_Grade5.md`