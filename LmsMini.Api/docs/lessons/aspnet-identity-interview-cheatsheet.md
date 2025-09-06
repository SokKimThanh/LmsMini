# ASP.NET Identity - Sổ Tay Phỏng Vấn (ngắn gọn)

Mục tiêu: học thuộc lòng các khái niệm và câu trả lời mẫu để trả lời phỏng vấn trôi chảy.

---

## Tổng quan ngắn

- ASP.NET Identity là thư viện quản lý người dùng tích hợp trong ASP.NET Core.
- Nó xử lý: đăng ký, đăng nhập, phân quyền (roles), claims, reset mật khẩu.
- Lưu trữ bằng Entity Framework Core khi dùng stores EF.

---

## Các khái niệm chính (đơn giản)

- User: đối tượng người dùng (IdentityUser hoặc ApplicationUser).
- Role: tên vai trò (Admin, User, ...).
- Claim: thông tin bổ sung về user (ví dụ can_view_reports).
- UserManager<T>: API để quản lý user (Create, Find, AddToRole...).
- SignInManager<T>: API để thực hiện đăng nhập/đăng xuất.
- RoleManager<TRole>: API để quản lý roles.
- Stores: nơi lưu dữ liệu (ví dụ Entity Framework stores).

---

## Kiến thức cấu trúc (ngắn)

- IdentityUser<TKey> là class cơ bản. TKey thường là string hoặc Guid.
- Tạo ApplicationUser : IdentityUser<Guid> để thêm thuộc tính như FullName.
- DbContext: kế thừa IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid> nếu dùng EF.
- Đăng ký trong Program.cs: AddIdentity / AddDefaultIdentity + AddEntityFrameworkStores.

---

## Các phương thức quan trọng (mẫu)

- _userManager.CreateAsync(user, password)_ → tạo user.
- _signInManager.PasswordSignInAsync(email, password, remember, lockout)_ → đăng nhập.
- _userManager.AddToRoleAsync(user, "Admin")_ → gán role.
- _roleManager.RoleExistsAsync("Admin")_ → kiểm tra role.
- _userManager.FindByEmailAsync(email)_ → tìm user.

---

## Authentication: cookie vs JWT (tóm tắt)

- Cookie: phù hợp web app + server render. Dễ cấu hình.
- JWT: phù hợp API/SPA. Token stateless, cần bảo mật key.
- Luôn lưu secret (Jwt:Key) ở user-secrets hoặc env vars.

---

## Migration & chiến lược DB (quick)

- Code-first: tạo migration để tạo bảng AspNet* bằng EF.
  - Lệnh: dotnet ef migrations add InitIdentity -p LmsMini.Infrastructure -s LmsMini.Api
  - Áp: dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
- Database-first (scaffold): map code tới bảng đã có. KHÔNG tạo migration cho AspNet*.
- Nếu DB đã có bảng, tạo migration baseline rỗng hoặc xóa phần CreateTable trong migration.

---

## Câu hỏi phỏng vấn thường gặp và trả lời mẫu

Q: ASP.NET Identity là gì?
A: Là framework quản lý user và auth trong ASP.NET Core. Cung cấp UserManager, SignInManager, RoleManager và stores.

Q: Làm sao lưu mật khẩu an toàn?
A: Identity dùng hashing + salting tự động. Không lưu plaintext.

Q: Role vs Claim khác nhau thế nào?
A: Role là nhóm (Admin). Claim là thông tin chi tiết (can_edit, department).

Q: Muốn thay Id type từ string sang Guid? Các bước?
A: Thay generic parameter IdentityUser<Guid>, cập nhật DbContext và migration. Cẩn thận với dữ liệu cũ.

Q: Khi nào dùng UserManager vs SignInManager?
A: UserManager để quản lý user. SignInManager để xử lý đăng nhập và cookie/JWT flow.

Q: Cách seed role an toàn?
A: Dùng RoleManager trong scope khi ứng dụng khởi động. Kiểm tra RoleExists trước Create.

---

## Debug nhanh (common issues)

- No database provider has been configured → chưa gọi UseSqlServer/UseNpgsql.
- Password does not meet requirements → điều chỉnh PasswordOptions trong AddIdentity.
- Migration tạo trùng AspNet* với DB hiện có → tạo migration rỗng hoặc xóa phần CreateTable.
- Missing Jwt:Key → set user-secrets hoặc env var trước khi chạy.

---

## Mẹo trả lời phỏng vấn (ngắn)

- Nói rõ bạn hiểu các lớp: UserManager, SignInManager, RoleManager.
- Nêu ví dụ thực tế: "tôi dùng RoleSeeder để seed Admin khi app start".
- Nếu nói về JWT, nhắc token validation và bảo vệ key.
- Nếu nói migration, nhấn tính an toàn cho DB production (review, DBA).

---

## Câu trả lời mẫu 60s (elevator pitch)

"ASP.NET Identity là giải pháp quản lý người dùng cho ASP.NET Core. Nó cung cấp API để đăng ký, đăng nhập, quản lý roles và claims. Thường dùng với EF Core để lưu AspNetUsers, AspNetRoles. Tôi đã triển khai Identity ở dự án database-first: map lớp user tới bảng scaffolded, seed role bằng RoleManager, và đảm bảo không tạo migration cho bảng AspNet* để tránh xung đột." 

---

## Các lệnh thường dùng (tóm tắt)

- dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
- dotnet ef migrations add <Name> -p LmsMini.Infrastructure -s LmsMini.Api
- dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
- dotnet user-secrets set "Jwt:Key" "your-key"

---

Ghi nhớ: trả lời ngắn, trọng tâm, và kèm ví dụ thực tế. Chúc phỏng vấn thành công!
