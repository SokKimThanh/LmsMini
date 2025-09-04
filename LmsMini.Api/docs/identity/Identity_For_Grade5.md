# Hướng dẫn nhanh: Thêm ASP.NET Identity (dành cho học sinh lớp 5)

Xin chào các em — cô giữ lại cả phần "Giải thích cơ bản" như trước để các em dễ hiểu, đồng thời vẫn có phần "Phương án đơn giản" cho các em thực hành.

---

## Giải thích cơ bản (cô nói thật dễ hiểu)
- ASP.NET Identity là một bộ công cụ có sẵn giúp chương trình quản lý người dùng: lưu tên đăng nhập, mật khẩu (dạng băm), email, phân vai trò (Admin/Instructor/Learner) và xử lý đăng nhập/đăng xuất.
- Tưởng tượng như hệ thống an ninh của toà nhà:
  - AspNetUsers = danh sách cư dân (ai sống trong toà nhà),
  - AspNetRoles = nhóm cư dân (ban quản trị, giáo viên, học sinh),
  - AspNetUserRoles = ai thuộc nhóm nào,
  - Tokens/Claims = thẻ ra vào hoặc quyền đặc biệt.

### Thành phần chính (ngắn gọn)
- User (AspNetUsers): lưu username, email, password hash.
- Role (AspNetRoles): tên vai trò (Admin, Instructor, Learner).
- UserRole (AspNetUserRoles): ánh xạ nhiều-nhiều.
- Claims, Logins, Tokens: thông tin thêm, đăng nhập bên ngoài, token.

### Luồng hoạt động cơ bản
1. User gửi yêu cầu (login/register) tới API.
2. Controller gọi UserManager/SignInManager (Identity) để xử lý.
3. Identity dùng EF Core để lưu/đọc dữ liệu từ LmsDbContext → Database.
4. Nếu dùng JWT, server trả token cho client.

---

## Phương án đơn giản (mạch lạc, từng bước) — dành cho các em thực hành
1) Sao lưu
- Commit mã: `git add . && git commit -m "backup before Identity"`.
- Backup database nếu có thể.

2) Kiểm tra kiểu Id trong DB
- Mở DB, xem cột `AspNetUsers.Id`:
  - UNIQUEIDENTIFIER → dùng `IdentityUser<Guid>`;
  - NVARCHAR/STRING → dùng `IdentityUser` (string).

3) Đồng bộ code
- `AspNetUser` kế thừa `IdentityUser<Guid>` (hoặc `IdentityUser`).
- `LmsDbContext` kế thừa `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>` (hoặc tương ứng string).
- Gọi `base.OnModelCreating(modelBuilder);` trong `OnModelCreating`.

4) Đăng ký Identity và Authentication
- Trong `Program.cs`:
  - `services.AddIdentity<...>().AddEntityFrameworkStores<LmsDbContext>()`;
  - `services.AddAuthentication(...).AddJwtBearer(...)` nếu dùng JWT;
  - middleware: `app.UseAuthentication();` trước `app.UseAuthorization();`.

5) Thiết lập dev tạm
- Trong thư mục `LmsMini.Api`:
  - `dotnet user-secrets init`
  - `dotnet user-secrets set "Jwt:Key" "dev-temp-key"`
- Đảm bảo connection string cho EF CLI (ví dụ LocalDB) qua biến môi trường hoặc appsettings.Development.json (không commit).

6) Tạo migration an toàn (baseline)
- Tạo migration:
  `dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api`
- Nếu bảng AspNet* đã tồn tại, mở file migration mới và XÓA phần `CreateTable` cho các bảng AspNet* để tránh tạo trùng. Hoặc tạo migration rỗng (Up() rỗng) làm baseline.

7) Áp migration
- `dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api`.
- Kiểm tra `__EFMigrationsHistory` và bảng `AspNetUsers` vẫn nguyên vẹn.

8) Seed roles & admin (tùy chọn)
- Dùng snippet seed trong tài liệu để tạo roles và tài khoản admin.

9) Kiểm tra
- Chạy: `dotnet run --project LmsMini.Api`.
- Test bằng Swagger hoặc Postman hoặc kiểm tra DB trực tiếp.

10) Dọn dẹp cấu hình dev
- Xóa user-secrets dev key khi xong: `dotnet user-secrets remove "Jwt:Key"` hoặc thay bằng key production.

---

## Checklist ngắn (in tâm trí)
- Backup code + DB ✔
- Xác định kiểu Id ✔
- Đồng bộ AspNetUser & LmsDbContext ✔
- Đăng ký Identity & JWT trong Program.cs ✔
- Tạo migration baseline hoặc chỉnh tay ✔
- Áp migration và kiểm tra ✔
- Seed roles/admin và kiểm tra ✔

---

## Hướng dẫn cài đặt chi tiết (code + lệnh) — làm theo từng bước

Dưới đây cô viết các đoạn mã mẫu và lệnh chính xác để em chép vào dự án. Làm theo thứ tự từng bước, mỗi bước kiểm tra kỹ trước khi tiếp.

### Bước 0 — Chuẩn bị
- Mở terminal tại thư mục gốc repo, đảm bảo `dotnet --version` là 9.x.
- Sao lưu code: `git add . && git commit -m "backup before Identity"`.

### Bước 1 — Cài package cần thiết
Chạy trong thư mục `LmsMini.Api`:

```bash
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

Sau đó `dotnet restore` và `dotnet build`.

### Bước 2 — Thêm lớp AspNetUser (Domain)
Tạo/Chỉnh file `LmsMini.Domain/Entities/Identity/AspNetUser.cs` (nếu em dùng Guid cho Id):

```csharp
using Microsoft.AspNetCore.Identity;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public class AspNetUser : IdentityUser<Guid>
{
    // giữ navigation properties nếu cần
    public virtual ICollection<Course> Courses { get; set; } = new List<Course>();
    public virtual ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();
    // ... các navigation khác
}
```

Nếu DB dùng string Id, thay `IdentityUser<Guid>` bằng `IdentityUser`.

### Bước 3 — Cập nhật LmsDbContext (Infrastructure)
Chỉnh `LmsMini.Infrastructure/Persistence/LmsDbContext.cs` để kế thừa IdentityDbContext:

```csharp
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace LmsMini.Domain.Entities;

public partial class LmsDbContext : IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>
{
    public LmsDbContext(DbContextOptions<LmsDbContext> options) : base(options) { }

    // DbSets cho entity khác
    public virtual DbSet<Course> Courses { get; set; }
    // ...

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder); // quan trọng

        // mapping thêm nếu cần (ví dụ đặt max length giống schema hiện có)
        modelBuilder.Entity<AspNetUser>(b =>
        {
            b.ToTable("AspNetUsers");
            b.Property(u => u.UserName).HasMaxLength(256);
            b.Property(u => u.NormalizedUserName).HasMaxLength(256);
            b.Property(u => u.Email).HasMaxLength(256);
            // tùy chỉnh thêm nếu schema khác
        });

        // giữ các cấu hình entity khác như cũ
        OnModelCreatingPartial(modelBuilder);
    }
    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
```

### Bước 4 — Thiết lập Program.cs (Api)
Trong `LmsMini.Api/Program.cs`, thêm các using và đăng ký Identity + JWT. Chỉ chèn phần dưới đây vào chỗ phù hợp (giữa builder khởi tạo và var app = builder.Build()).

```csharp
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

// Lấy key từ cấu hình
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Missing Jwt:Key");

builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});
```

Và trong phần middleware, đảm bảo:

```csharp
app.UseAuthentication();
app.UseAuthorization();
```

Nếu muốn tự động seed roles/admin khi khởi động, gọi hàm seed sau `var app = builder.Build();`:

```csharp
using (var scope = app.Services.CreateScope())
{
    await SeedDataAsync(scope.ServiceProvider);
}
```

### Bước 5 — Seed roles & admin (mẫu)
Thêm phương thức seed (chẳng hạn ở `LmsMini.Infrastructure` hoặc `LmsMini.Api`):

```csharp
public static async Task SeedDataAsync(IServiceProvider services)
{
    using var scope = services.CreateScope();
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AspNetUser>>();

    string[] roles = new[] { "Admin", "Instructor", "Learner" };
    foreach (var role in roles)
    {
        if (!await roleManager.RoleExistsAsync(role))
            await roleManager.CreateAsync(new IdentityRole<Guid>(role));
    }

    var adminEmail = "admin@example.com";
    var admin = await userManager.FindByEmailAsync(adminEmail);
    if (admin == null)
    {
        admin = new AspNetUser { UserName = "admin", Email = adminEmail, EmailConfirmed = true };
        var result = await userManager.CreateAsync(admin, "Admin@123");
        if (result.Succeeded) await userManager.AddToRoleAsync(admin, "Admin");
    }
}
```

**Lưu ý:** đổi mật khẩu mẫu trước khi đưa vào production.

### Bước 6 — Design-time DbContext factory cho EF tools
Tạo `LmsMini.Infrastructure/Persistence/LmsDbContextFactory.cs` để EF CLI không cần Program.cs khi tạo migration:

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using LmsMini.Domain.Entities;

public class LmsDbContextFactory : IDesignTimeDbContextFactory<LmsDbContext>
{
    public LmsDbContext CreateDbContext(string[] args)
    {
        var builder = new DbContextOptionsBuilder<LmsDbContext>();
        var conn = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
                   ?? "Server=(localdb)\\MSSQLLocalDB;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;";
        builder.UseSqlServer(conn);
        return new LmsDbContext(builder.Options);
    }
}
```

### Bước 7 — Tạo migration & áp vào database
1. Tạo migration (từ thư mục gốc):

```bash
dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api
```

2. Nếu DB đã có bảng AspNetUsers: mở file migration mới và XÓA phần `CreateTable` cho `AspNet*` (hoặc tạo migration rỗng làm baseline) để tránh tạo trùng.

3. Áp migration:

```bash
dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
```

### Bước 8 — Kiểm tra & chạy
- Chạy API: `dotnet run --project LmsMini.Api`.
- Mở Swagger (`https://localhost:5001/swagger`) hoặc dùng Postman để kiểm tra Endpoints.
- Kiểm tra DB: `AspNetUsers`, `AspNetRoles`, `__EFMigrationsHistory`.

### Mẹo & xử lý lỗi nhanh
- Lỗi "Missing Jwt:Key" khi chạy migrations: đặt user-secrets tạm hoặc biến môi trường `Jwt:Key` trước khi chạy EF nếu Program.cs dùng builder.Configuration trực tiếp.
- Nếu EF CLI không khởi tạo DbContext vì Program.cs yêu cầu services, thêm design-time factory (bước 6).
- Luôn đọc file migration trước khi apply.

---

Cô đã soạn các đoạn mã và lệnh để em tự làm. Nếu em gặp lỗi cụ thể khi chép/migrate, gửi lỗi cho cô (copy paste) cô sẽ hướng dẫn sửa từng bước.
