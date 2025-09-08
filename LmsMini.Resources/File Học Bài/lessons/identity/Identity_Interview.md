# ASP.NET Identity - Sổ tay phỏng vấn (ngắn gọn)

Mục tiêu: nắm nhanh các khái niệm và câu trả lời mẫu để trả lời phỏng vấn một cách trôi chảy.

---

## Tổng quan ngắn

- ASP.NET Identity là thư viện quản lý người dùng tích hợp trong ASP.NET Core.
- Nó xử lý: đăng ký, đăng nhập, phân quyền (roles), claims, reset mật khẩu.
- Thường lưu trữ bằng Entity Framework Core khi sử dụng EF stores.

---

## Các khái niệm chính (đơn giản)

- User: đối tượng người dùng (IdentityUser hoặc ApplicationUser).
- Role: tên vai trò (Admin, User, ...).
- Claim: thông tin bổ sung về user (ví dụ: can_view_reports).
- UserManager<T>: API để quản lý user (Create, Find, AddToRole...).
- SignInManager<T>: API để thực hiện đăng nhập/đăng xuất.
- RoleManager<TRole>: API để quản lý roles.
- Stores: nơi lưu dữ liệu (ví dụ: Entity Framework stores).

---

## Kiến thức cấu trúc (ngắn)

- IdentityUser<TKey> là lớp cơ bản. TKey thường là string hoặc Guid.
- Tạo ApplicationUser : IdentityUser<Guid> để thêm thuộc tính như FullName.
- DbContext: kế thừa IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid> nếu dùng EF.
- Đăng ký trong Program.cs: AddIdentity / AddDefaultIdentity kết hợp AddEntityFrameworkStores.

---

## Các phương thức quan trọng (mẫu)

- userManager.CreateAsync(user, password) → tạo user.
- signInManager.PasswordSignInAsync(email, password, remember, lockout) → đăng nhập.
- userManager.AddToRoleAsync(user, "Admin") → gán role.
- roleManager.RoleExistsAsync("Admin") → kiểm tra role.
- userManager.FindByEmailAsync(email) → tìm user.

---

## Authentication: cookie vs JWT (tóm tắt)

- Cookie: phù hợp cho web app và server-rendered app. Dễ cấu hình.
- JWT: phù hợp cho API/SPA. Token không trạng thái (stateless), cần bảo vệ khóa.
- Luôn lưu secret (Jwt:Key) ở user-secrets hoặc biến môi trường.

---

## Migration & chiến lược cơ sở dữ liệu (nhanh)

- Code-first: tạo migration để EF tạo bảng AspNet*.
  - Lệnh: dotnet ef migrations add InitIdentity -p LmsMini.Infrastructure -s LmsMini.Api
  - Áp: dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
- Database-first (scaffold): ánh xạ code tới bảng đã có; KHÔNG chạy migration để tạo lại bảng AspNet*.
- Nếu cơ sở dữ liệu đã có bảng tương ứng, tạo migration baseline (Up rỗng) hoặc chỉnh tay migration trước khi apply.

---

## Câu hỏi phỏng vấn thường gặp và câu trả lời mẫu

Q: ASP.NET Identity là gì?
A: Là framework quản lý người dùng và xác thực trong ASP.NET Core. Cung cấp UserManager, SignInManager, RoleManager và các stores.

Q: Cách lưu mật khẩu an toàn?
A: Identity sử dụng hashing và salting tự động; không lưu mật khẩu ở dạng plain text.

Q: Role và Claim khác nhau thế nào?
A: Role là nhóm (ví dụ: Admin). Claim là thông tin chi tiết hơn về user (ví dụ: can_edit, department).

Q: Muốn đổi Id type từ string sang Guid, cần làm gì?
A: Thay generic parameter sang IdentityUser<Guid>, cập nhật DbContext và migration. Cần cẩn trọng với dữ liệu cũ.

Q: Khi nào dùng UserManager và khi nào dùng SignInManager?
A: UserManager để thao tác quản lý user (tạo, sửa, gán role). SignInManager để xử lý luồng đăng nhập/đăng xuất và cookie/JWT flows.

Q: Cách seed role an toàn?
A: Dùng RoleManager trong scope khi ứng dụng khởi động; kiểm tra RoleExists trước khi Create.

---

## Debug nhanh (vấn đề thường gặp)

- No database provider has been configured → chưa gọi UseSqlServer/UseNpgsql trong cấu hình DbContext.
- Password does not meet requirements → điều chỉnh PasswordOptions trong AddIdentity.
- Migration tạo trùng bảng AspNet* với DB hiện có → tạo migration baseline rỗng hoặc xóa phần CreateTable trong migration.
- Missing Jwt:Key → đặt user-secrets hoặc biến môi trường trước khi chạy.

---

## Mẹo trả lời phỏng vấn (ngắn gọn)

- Nêu rõ bạn hiểu các lớp: UserManager, SignInManager, RoleManager.
- Đưa ví dụ thực tế: "Tôi dùng RoleSeeder để seed role Admin khi ứng dụng khởi động." 
- Khi nói về JWT, nhấn mạnh token validation và bảo vệ khóa.
- Khi nói về migration, nhấn vào việc review SQL trước khi apply và phối hợp với DBA ở môi trường production.

---

## Câu trả lời mẫu 60 giây (elevator pitch)

"ASP.NET Identity là giải pháp quản lý người dùng cho ASP.NET Core. Nó cung cấp API để đăng ký, đăng nhập, quản lý roles và claims. Thường dùng với EF Core để lưu AspNetUsers, AspNetRoles. Tôi đã triển khai Identity trong dự án database-first: ánh xạ lớp user tới bảng scaffolded, seed role bằng RoleManager, và đảm bảo không chạy migration tạo lại bảng AspNet* để tránh xung đột dữ liệu."

---

## Các lệnh thường dùng (tóm tắt)

- dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
- dotnet ef migrations add <Name> -p LmsMini.Infrastructure -s LmsMini.Api
- dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
- dotnet user-secrets set "Jwt:Key" "your-key"

---

## Các câu trả lời nhanh và đoạn mã mẫu (phục vụ ôn phỏng vấn)

- Tóm tắt: "Chỉ dùng một CLR user type; gọi base.OnModelCreating; ánh xạ ToTable cho AspNet* nếu DB-first."

- Ví dụ seed roles (ngắn):

```csharp
using var scope = app.Services.CreateScope();
var rm = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
if (!await rm.RoleExistsAsync("Admin")) await rm.CreateAsync(new IdentityRole<Guid>("Admin"));
```

- Ví dụ tạo JWT (tối giản):

```csharp
var claims = new[]{ new Claim(ClaimTypes.Name, user.UserName) };
var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]));
var token = new JwtSecurityToken(signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256), claims: claims, expires: DateTime.UtcNow.AddHours(1));
```

---

## Checklist quyết định kiến trúc (nói trong phỏng vấn)

- Quyết: code-first hay DB-first (ai quản lý schema?).
- Chọn một CLR user type duy nhất (ApplicationUser hay scaffolded AspNetUser).
- Quyết nơi seed roles và admin (seeder chạy khi khởi động ứng dụng trong scope).
- Quyết chiến lược token: JWT access + refresh hay cookie.
- Đặt các quyết định bảo mật: yêu cầu xác nhận email, lockout, chính sách mật khẩu.

---

## Vấn đề phổ biến và cách sửa nhanh

- Duplicate mapping → đảm bảo chỉ có một CLR type ánh xạ AspNetUsers.
- DbContext build fails in EF CLI → thêm IDesignTimeDbContextFactory.
- Migration collides with existing DB → tạo baseline migration hoặc chỉnh SQL migration.

---

Ghi nhớ: trả lời ngắn, trọng tâm và kèm ví dụ thực tế. Chúc phỏng vấn thành công!
