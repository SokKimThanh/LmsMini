Identity — Lộ trình thực hành (Code‑First) — LmsMini

Tổng quan ngắn
- Nếu mục tiêu là dùng ASP.NET Core Identity chuẩn thì KHÔNG cần scaffold toàn bộ các bảng AspNet*.
- Thư viện Identity (IdentityDbContext, IdentityUser/IdentityRole, UserManager/RoleManager) đã cung cấp mapping và logic cần thiết; bằng cách dùng code‑first bạn giữ cấu hình đơn giản và tránh xung đột khi scaffold lại.

Tại sao tránh scaffold AspNet* (DB‑first) trừ khi bắt buộc
- DB‑first làm tăng độ phức tạp: scaffold tạo nhiều POCOs trùng với types của Identity → dễ xảy ra duplicate table mapping, lỗi EF (table mapped twice), hoặc phải liên tục chỉnh các lớp để kế thừa Identity types.
- Khi DBA đã tạo bảng theo cách khác, merge schema phức tạp và scaffold có thể ghi đè hoặc loại bỏ thuộc tính tuỳ chỉnh.
- Nếu không bắt buộc (DB đã chuẩn theo Identity) thì prefer code‑first để đơn giản hoá triển khai.

Code‑First — các bước thực hành (thứ tự rõ ràng)
1. Thêm package cần thiết (project Infrastructure):
   - Microsoft.AspNetCore.Identity.EntityFrameworkCore
   - Microsoft.EntityFrameworkCore.SqlServer
2. Tạo/điều chỉnh model user/role nếu cần:
   - Tùy chọn nhẹ: class ApplicationUser : IdentityUser<Guid> { /* navigation only */ }
   - Tùy chọn role: class ApplicationRole : IdentityRole<Guid> { }
3. DbContext:
   - public class LmsDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid> { ... }
   - Đưa cấu hình nghiệp vụ (Courses, Modules…) vào OnModelCreating; để mapping Identity mặc định do base.OnModelCreating quản lý.
4. Program.cs (DI):
   - builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(opts => { ... })
       .AddEntityFrameworkStores<LmsDbContext>()
       .AddDefaultTokenProviders();
   - Đăng ký DbContext trước khi Build.
   - app.UseAuthentication(); app.UseAuthorization(); (đặt đúng thứ tự)
5. Migrations (code‑first):
   - dotnet ef migrations add InitialIdentityAndDomain -p LmsMini.Infrastructure -s LmsMini.Api
   - dotnet ef database update
   - Lưu ý: nếu DB‑first bắt buộc cho Identity, DON'T let migrations modify AspNet* (coordinate with DBA).
6. Seeder roles/users:
   - Sử dụng RoleManager<ApplicationRole> / UserManager<ApplicationUser> trong scope khi app start để tạo roles/admin (idempotent).
7. Test end‑to‑end: register/login via Swagger, kiểm tra bảng AspNetUsers/AspNetRoles/AspNetUserRoles.

Những điểm cần chú ý (best practices)
- Tránh UsingEntity<Dictionary<...>> cho AspNetUserRoles nếu dùng IdentityDbContext — Identity đã tạo join entity.
- Nếu giữ POCO scaffolded, bắt buộc cho chúng kế thừa Identity types để tránh CS0311/duplicate mapping.
- Tách mapping ổn định vào partial file (OnModelCreatingPartial) nếu vẫn dùng scaffold -> giảm rủi ro khi regen.
- Trong CI: chặn migration có thay đổi AspNet* nếu DB‑first quản lý Identity.

Mục riêng: Phức tạp của DB‑First với Identity
- Khi scaffold từ DB có AspNet* bạn phải:
  - Đồng bộ CLR types với bảng (tạo lớp kế thừa IdentityUser/IdentityRole/... hoặc điều chỉnh mapping),
  - Xử lý duplicate mapping (ví dụ IdentityRoleClaim vs AspNetRoleClaim),
  - Duy trì partial mapping để tránh bị scaffold ghi đè.
- Kết luận: DB‑first phù hợp khi DBA quản lý schema hoặc bảng có khác biệt lớn; nếu không, code‑first đơn giản và ít lỗi hơn.

Study card (phỏng vấn) — nhớ nhanh
- Khi dùng Identity, tối thiểu cần: ApplicationUser (IdentityUser<TKey>), LmsDbContext : IdentityDbContext<...>, AddIdentity + AddEntityFrameworkStores in Program.cs, UseAuthentication() before UseAuthorization().
- Tránh scaffold AspNet* trừ khi bắt buộc; nếu scaffolded thì convert POCO -> inherit Identity types.
- Nguyên nhân phổ biến lỗi EF: "table mapped twice" → do duplicate mapping (built‑in Identity entity + manual UsingEntity/POCO). Giải pháp: remove manual UsingEntity or use the same Identity CLR types.
- Seeder roles: dùng RoleManager, luôn làm idempotent.

Bài học rút ra
- Kinh nghiệm bạn nêu: tạo bảng trước rồi áp Identity dẫn tới mất thuộc tính và phải chỉnh lại — bài học: bắt đầu từ code‑first hoặc chuẩn hoá mapping trước khi scaffold/đổi schema.

Tài liệu tham khảo nhanh (commands)
- dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
- dotnet ef migrations add Initial -p LmsMini.Infrastructure -s LmsMini.Api
- dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api

File ngắn, dễ thao tác khi học thực hành. Nếu muốn tôi có thể thêm một checklist migration CI (GitHub Action) vào thư mục docs/ops.
