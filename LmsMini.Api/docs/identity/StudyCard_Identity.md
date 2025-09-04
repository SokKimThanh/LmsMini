# Study Card: ASP.NET Identity — Tóm tắt nhanh (Tiếng Việt)

Mục tiêu: ghi nhớ nhanh các khái niệm, lệnh và bước thực hành để bật ASP.NET Identity trong dự án Clean Architecture.

---

## Khái niệm chính
- Identity: framework quản lý user, role, login, token, claims.
- AspNetUsers / AspNetRoles / AspNetUserRoles: các bảng mặc định trong DB khi bật Identity.
- UserManager / RoleManager: dịch vụ quản lý user và role.
- IdentityUser<TKey>: kiểu user mặc định (IdentityUser = string id; IdentityUser<Guid> = Guid id).
- AddEntityFrameworkStores<TContext>(): lưu Identity qua DbContext (EF Core).

---

## Luồng cơ bản
1. User gửi request (register/login) → Controller
2. Controller gọi UserManager/SignInManager -> Identity
3. Identity dùng EF Core (LmsDbContext) đọc/ghi bảng AspNet*
4. Nếu dùng JWT: trả token cho client

---

## Lệnh thường dùng
- Cài package (API project):
  - `dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore`
  - `dotnet add package Microsoft.EntityFrameworkCore.Design`
  - `dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer`
- User secrets (dev):
  - `dotnet user-secrets init`
  - `dotnet user-secrets set "Jwt:Key" "<bí-mật>"`
- Tạo migration / apply:
  - `dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api`
  - `dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api`

---

## Cấu hình nhanh (Program.cs - tối thiểu)
- Đăng ký DbContext (ví dụ):

```csharp
builder.Services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
```

- Đăng ký Identity + EF store:

```csharp
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>()
    .AddEntityFrameworkStores<LmsDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => { /* token validation */ });
```

- Middleware (quan trọng):

```csharp
app.UseAuthentication();
app.UseAuthorization();
```

---

## Seed Roles & Admin (nhanh)
- Tạo roles: `Admin`, `Instructor`, `Learner`.
- Tạo admin nếu chưa có, dùng UserManager.CreateAsync(user, password) rồi AddToRoleAsync.

---

## Kiểm tra nhanh sau khi setup
- Kiểm tra bảng `AspNetUsers`, `AspNetRoles` trong DB.
- Kiểm tra `__EFMigrationsHistory` có migration đã apply.
- Test register/login bằng Swagger/Postman.

---

## Lỗi hay gặp & cách xử lý
- Missing Jwt:Key: đặt user-secrets hoặc biến môi trường.
- EF không thể tạo DbContext khi Program.cs yêu cầu services: thêm `IDesignTimeDbContextFactory<LmsDbContext>`.
- Migration muốn tạo bảng đã tồn tại: tạo migration baseline (Up rỗng) hoặc xóa CreateTable trong migration file trước khi apply.

---

## Mẹo ghi nhớ
- 3 chữ vàng: User — Role — Token
- 2 lệnh sống còn: `UseAuthentication()` + `UseAuthorization()`
- 1 nơi lưu: `LmsDbContext`
- 1 chìa khóa: `Jwt:Key` (giữ bí mật)

---

## 6 câu flashcards (self-check)
1. Q: Package nào cần để dùng Identity với EF Core? A: Microsoft.AspNetCore.Identity.EntityFrameworkCore
2. Q: Dùng kiểu Id nào nếu DB cột Id là UNIQUEIDENTIFIER? A: IdentityUser<Guid>
3. Q: Lệnh tạo migration (project Infrastructure, startup Api)? A: `dotnet ef migrations add <Name> -p LmsMini.Infrastructure -s LmsMini.Api`
4. Q: Nếu migration tạo AspNetUsers nhưng bảng đã có, làm gì? A: Xóa phần CreateTable trong migration hoặc tạo migration baseline (Up rỗng)
5. Q: Dịch vụ nào tạo token JWT? A: cấu hình JwtBearer trong AddAuthentication/AddJwtBearer
6. Q: Muốn EF CLI khởi tạo DbContext ở design time thì thêm gì? A: IDesignTimeDbContextFactory<LmsDbContext>

---

File: `LmsMini.Api/docs/identity/StudyCard_Identity.md` — lưu để in hoặc dán cạnh màn hình.
