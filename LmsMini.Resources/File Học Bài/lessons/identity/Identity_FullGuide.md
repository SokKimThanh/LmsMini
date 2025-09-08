# Hướng dẫn tích hợp ASP.NET Core Identity (dùng AspNetUser scaffolded)

<!-- Mục lục -->
- [1. Tóm tắt chiến lược](#1-tóm-tắt-chiến-lược)
- [2. Chỉnh AspNetUser (ví dụ)](#2-chỉnh-aspnetuser-ví-dụ)
- [3. Cập nhật LmsDbContext (ví dụ)](#3-cập-nhật-lmsdbcontext-ví-dụ)
- [4. Đăng ký Identity & Authentication trong Program.cs](#4-đăng-ký-identity--authentication-trong-programcs)
- [5. Controller mẫu: AccountController (Register + Login → JWT)](#5-controller-mẫu-accountcontroller-register--login-→-jwt)
- [6. RoleSeeder (sử dụng RoleManager)](#6-roleseeder-sử-dụng-rolemanager)
- [7. Migration & apply](#7-migration--apply)
- [8. Troubleshooting: Duplicate entity mapping](#8-troubleshooting-duplicate-entity-mapping)
- [9. Best practices & security](#9-best-practices--security)
- [10. Next steps (tùy chọn tôi có thể làm giúp)](#10-next-steps-tùy-chọn-tôi-có-thể-làm-giúp)
- [11. Các bước còn thiếu — hướng dẫn thực thi nhanh (actionable checklist)](#11-các-bước-còn-thiếu-—-hướng-dẫn-thực-thi-nhanh-actionable-checklist)

Mục tiêu: hướng dẫn chi tiết cách sử dụng lớp scaffolded `AspNetUser` làm user type cho ASP.NET Core Identity trong dự án LMS‑Mini. Bao gồm: chỉnh entity, cập nhật DbContext, đăng ký Identity trong Program.cs, tạo JWT, controller mẫu (register/login), seeder role, migration và xử lý lỗi duplicate mapping.

---

## 1. Tóm tắt chiến lược

- Sử dụng file scaffolded `LmsMini.Domain.Entities.Identity.AspNetUser` làm user type bằng cách cho nó kế thừa `IdentityUser<Guid>`; loại bỏ các thuộc tính trùng với Identity (UserName, Email, PasswordHash...).
- DbContext `LmsDbContext` kế thừa `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>` và gọi `base.OnModelCreating(modelBuilder)` trước các cấu hình scaffolded.
- Map các bảng Identity mặc định (`AspNetUsers`, `AspNetRoles`, `AspNetUserClaims`, ...) bằng `ToTable(...)` để giữ tương thích schema hiện có.
- Đăng ký Identity trong `Program.cs` và (tùy chọn) cấu hình JWT để phát token.

---

## 2. Chỉnh AspNetUser (ví dụ)

File: `LmsMini.Domain/Entities/Identity/AspNetUser.cs`

```csharp
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace LmsMini.Domain.Entities;

public partial class AspNetUser : IdentityUser<Guid>
{
    // Chỉ giữ navigation properties; các thuộc tính cơ bản (UserName, Email, PasswordHash, ...) do IdentityUser<Guid> cung cấp
    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    public virtual ICollection<Course> Courses { get; set; } = new List<Course>();
    public virtual ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();
    public virtual ICollection<FileAsset> FileAssets { get; set; } = new List<FileAsset>();
    public virtual ICollection<Notification> NotificationSentByNavigations { get; set; } = new List<Notification>();
    public virtual ICollection<Notification> NotificationToUsers { get; set; } = new List<Notification>();
    public virtual ICollection<Progress> Progresses { get; set; } = new List<Progress>();
    public virtual ICollection<QuizAttempt> QuizAttempts { get; set; } = new List<QuizAttempt>();
}
```

Lưu ý: Không để các thuộc tính như `public Guid Id { get; set; }` hay `public string PasswordHash { get; set; }` xuất hiện trùng lặp — IdentityUser đã định nghĩa chúng.

---

## 3. Cập nhật LmsDbContext (ví dụ)

File: `LmsMini.Infrastructure/Persistence/LmsDbContext.cs`

- Kế thừa `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>`.
- Gọi `base.OnModelCreating(modelBuilder)` đầu tiên.
- Map các bảng Identity bằng `ToTable(...)` để khớp schema hiện có.
- Xóa `DbSet<AspNetUser>` nếu trước đó đã khai báo thủ công (IdentityDbContext cung cấp `Users`).

Ví dụ (trích đoạn):

```csharp
public partial class LmsDbContext : IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>
{
    public LmsDbContext(DbContextOptions<LmsDbContext> options) : base(options) { }

    // DbSet khác...

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // map Identity tables → giữ tên AspNet* hiện có
        modelBuilder.Entity<AspNetUser>(b => b.ToTable("AspNetUsers"));
        modelBuilder.Entity<IdentityRole<Guid>>(b => b.ToTable("AspNetRoles"));
        modelBuilder.Entity<IdentityUserRole<Guid>>(b => b.ToTable("AspNetUserRoles"));
        modelBuilder.Entity<IdentityUserClaim<Guid>>(b => b.ToTable("AspNetUserClaims"));
        modelBuilder.Entity<IdentityUserLogin<Guid>>(b => b.ToTable("AspNetUserLogins"));
        modelBuilder.Entity<IdentityRoleClaim<Guid>>(b => b.ToTable("AspNetRoleClaims"));
        modelBuilder.Entity<IdentityUserToken<Guid>>(b => b.ToTable("AspNetUserTokens"));

        // existing scaffolded entity configurations ...
    }
}
```

---

## 4. Đăng ký Identity & Authentication trong Program.cs

- Đăng ký Identity với EF store và token providers.
- Bật middleware Authentication trước Authorization.
- (Tùy) Cấu hình JWT bearer để cấp token cho API.

Ví dụ (trích đoạn):

```csharp
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();

// (Nếu dùng JWT) AddAuthentication + AddJwtBearer
builder.Services.AddAuthentication(options => {
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options => {
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = configuration["Jwt:Issuer"],
        ValidAudience = configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
    };
});

app.UseAuthentication();
app.UseAuthorization();
```

---

## 5. Controller mẫu: AccountController (Register + Login → JWT)

File ví dụ: `LmsMini.Api/Controllers/AccountController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly UserManager<AspNetUser> _userManager;
    private readonly SignInManager<AspNetUser> _signInManager;
    private readonly IConfiguration _config;

    public AccountController(UserManager<AspNetUser> userManager, SignInManager<AspNetUser> signInManager, IConfiguration config)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _config = config;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        var user = new AspNetUser { UserName = req.Email, Email = req.Email };
        var result = await _userManager.CreateAsync(user, req.Password);
        if (!result.Succeeded) return BadRequest(result.Errors);

        // Add default role if needed
        await _userManager.AddToRoleAsync(user, "Learner");

        return Ok();
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user == null) return Unauthorized();

        var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
        if (!pwOk) return Unauthorized();

        // create JWT
        var roles = await _userManager.GetRolesAsync(user);
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Name, user.UserName ?? string.Empty)
        };
        claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds);

        return Ok(new { token = new JwtSecurityTokenHandler().WriteToken(token) });
    }
}
```

Mẫu DTOs:

```csharp
public record RegisterRequest(string Email, string Password);
public record LoginRequest(string Email, string Password);
```

---

## 6. RoleSeeder (sử dụng RoleManager)

```csharp
public static class RoleSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var rm = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        var roles = new[] { "Admin", "Instructor", "Learner" };
        foreach (var r in roles)
        {
            if (!await rm.RoleExistsAsync(r)) await rm.CreateAsync(new IdentityRole<Guid>(r));
        }
    }
}
```

Gọi seeder sau khi `var app = builder.Build();` trước `app.Run();`:

```csharp
await RoleSeeder.SeedAsync(app.Services);
```

---

## 7. Migration & apply

- Tạo migration (từ solution root):

```
dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api
```

- Áp dụng migration:

```
dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
```

Chú ý: kiểm tra SQL migration trước khi apply, đặc biệt nếu DB hiện có dữ liệu.

---

## 8. Troubleshooting: Duplicate entity mapping

Nguyên nhân phổ biến:
- Có hai CLR types ánh xạ cùng bảng `AspNetUsers` (ví dụ: `AspNetUser` scaffolded và `ApplicationUser` cùng tồn tại).
- DbContext cấu hình mapping trùng (ví dụ cả `DbSet<AspNetUser>` và `IdentityDbContext<ApplicationUser,...>` cùng ánh xạ `AspNetUsers`).

Kiểm tra:
- Tìm `class ApplicationUser` trong solution.
- Tìm `DbSet<AspNetUser>` và các `modelBuilder.Entity<...>().ToTable("AspNetUsers")` trùng lặp.

Khắc phục:
- Giữ một kiểu duy nhất cho user (trong hướng dẫn này là `AspNetUser`).
- Đảm bảo chỉ map bảng `AspNetUsers` một lần: gọi `base.OnModelCreating()` và sử dụng `modelBuilder.Entity<AspNetUser>().ToTable("AspNetUsers")` nếu cần.

---
# Hướng dẫn tích hợp ASP.NET Core Identity (dùng AspNetUser scaffolded)

Mục tiêu: hướng dẫn chi tiết cách sử dụng lớp scaffolded `AspNetUser` làm user type cho ASP.NET Core Identity trong dự án LMS‑Mini. Bao gồm: chỉnh entity, cập nhật DbContext, đăng ký Identity trong Program.cs, tạo JWT, controller mẫu (register/login), seeder role, migration và xử lý lỗi duplicate mapping.

---

## 1. Tóm tắt chiến lược

- Sử dụng file scaffolded `LmsMini.Domain.Entities.Identity.AspNetUser` làm user type bằng cách cho nó kế thừa `IdentityUser<Guid>`; loại bỏ các thuộc tính trùng với Identity (UserName, Email, PasswordHash...).
- DbContext `LmsDbContext` kế thừa `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>` và gọi `base.OnModelCreating(modelBuilder)` trước các cấu hình scaffolded.
- Map các bảng Identity mặc định (`AspNetUsers`, `AspNetRoles`, `AspNetUserClaims`, ...) bằng `ToTable(...)` để giữ tương thích schema hiện có.
- Đăng ký Identity trong `Program.cs` và (tùy chọn) cấu hình JWT để phát token.

---

## 2. Chỉnh AspNetUser (ví dụ)

File: `LmsMini.Domain/Entities/Identity/AspNetUser.cs`

```csharp
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace LmsMini.Domain.Entities;

public partial class AspNetUser : IdentityUser<Guid>
{
    // Chỉ giữ navigation properties; các thuộc tính cơ bản (UserName, Email, PasswordHash, ...) do IdentityUser<Guid> cung cấp
    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    public virtual ICollection<Course> Courses { get; set; } = new List<Course>();
    public virtual ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();
    public virtual ICollection<FileAsset> FileAssets { get; set; } = new List<FileAsset>();
    public virtual ICollection<Notification> NotificationSentByNavigations { get; set; } = new List<Notification>();
    public virtual ICollection<Notification> NotificationToUsers { get; set; } = new List<Notification>();
    public virtual ICollection<Progress> Progresses { get; set; } = new List<Progress>();
    public virtual ICollection<QuizAttempt> QuizAttempts { get; set; } = new List<QuizAttempt>();
}
```

Lưu ý: Không để các thuộc tính như `public Guid Id { get; set; }` hay `public string PasswordHash { get; set; }` xuất hiện trùng lặp — IdentityUser đã định nghĩa chúng.

---

## 3. Cập nhật LmsDbContext (ví dụ)

File: `LmsMini.Infrastructure/Persistence/LmsDbContext.cs`

- Kế thừa `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>`.
- Gọi `base.OnModelCreating(modelBuilder)` đầu tiên.
- Map các bảng Identity bằng `ToTable(...)` để khớp schema hiện có.
- Xóa `DbSet<AspNetUser>` nếu trước đó đã khai báo thủ công (IdentityDbContext cung cấp `Users`).

Ví dụ (trích đoạn):

```csharp
public partial class LmsDbContext : IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>
{
    public LmsDbContext(DbContextOptions<LmsDbContext> options) : base(options) { }

    // DbSet khác...

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // map Identity tables → giữ tên AspNet* hiện có
        modelBuilder.Entity<AspNetUser>(b => b.ToTable("AspNetUsers"));
        modelBuilder.Entity<IdentityRole<Guid>>(b => b.ToTable("AspNetRoles"));
        modelBuilder.Entity<IdentityUserRole<Guid>>(b => b.ToTable("AspNetUserRoles"));
        modelBuilder.Entity<IdentityUserClaim<Guid>>(b => b.ToTable("AspNetUserClaims"));
        modelBuilder.Entity<IdentityUserLogin<Guid>>(b => b.ToTable("AspNetUserLogins"));
        modelBuilder.Entity<IdentityRoleClaim<Guid>>(b => b.ToTable("AspNetRoleClaims"));
        modelBuilder.Entity<IdentityUserToken<Guid>>(b => b.ToTable("AspNetUserTokens"));

        // existing scaffolded entity configurations ...
    }
}
```

---

## 4. Đăng ký Identity & Authentication trong Program.cs

- Đăng ký Identity với EF store và token providers.
- Bật middleware Authentication trước Authorization.
- (Tùy) Cấu hình JWT bearer để cấp token cho API.

Ví dụ (trích đoạn):

```csharp
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();

// (Nếu dùng JWT) AddAuthentication + AddJwtBearer
builder.Services.AddAuthentication(options => {
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options => {
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = configuration["Jwt:Issuer"],
        ValidAudience = configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
    };
});

app.UseAuthentication();
app.UseAuthorization();
```

---

## 5. Controller mẫu: AccountController (Register + Login → JWT)

File ví dụ: `LmsMini.Api/Controllers/AccountController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly UserManager<AspNetUser> _userManager;
    private readonly SignInManager<AspNetUser> _signInManager;
    private readonly IConfiguration _config;

    public AccountController(UserManager<AspNetUser> userManager, SignInManager<AspNetUser> signInManager, IConfiguration config)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _config = config;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        var user = new AspNetUser { UserName = req.Email, Email = req.Email };
        var result = await _userManager.CreateAsync(user, req.Password);
        if (!result.Succeeded) return BadRequest(result.Errors);

        // Add default role if needed
        await _userManager.AddToRoleAsync(user, "Learner");

        return Ok();
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user == null) return Unauthorized();

        var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
        if (!pwOk) return Unauthorized();

        // create JWT
        var roles = await _userManager.GetRolesAsync(user);
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Name, user.UserName ?? string.Empty)
        };
        claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds);

        return Ok(new { token = new JwtSecurityTokenHandler().WriteToken(token) });
    }
}
```

Mẫu DTOs:

```csharp
public record RegisterRequest(string Email, string Password);
public record LoginRequest(string Email, string Password);
```

---

## 6. RoleSeeder (sử dụng RoleManager)

```csharp
public static class RoleSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var rm = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        var roles = new[] { "Admin", "Instructor", "Learner" };
        foreach (var r in roles)
        {
            if (!await rm.RoleExistsAsync(r)) await rm.CreateAsync(new IdentityRole<Guid>(r));
        }
    }
}
```

Gọi seeder sau khi `var app = builder.Build();` trước `app.Run();`:

```csharp
await RoleSeeder.SeedAsync(app.Services);
```

---

## 7. Migration & apply

- Tạo migration (từ solution root):

```
dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api
```

- Áp dụng migration:

```
dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
```

Chú ý: kiểm tra SQL migration trước khi apply, đặc biệt nếu DB hiện có dữ liệu.

---

## 8. Troubleshooting: Duplicate entity mapping

Nguyên nhân phổ biến:
- Có hai CLR types ánh xạ cùng bảng `AspNetUsers` (ví dụ: `AspNetUser` scaffolded và `ApplicationUser` cùng tồn tại).
- DbContext cấu hình mapping trùng (ví dụ cả `DbSet<AspNetUser>` và `IdentityDbContext<ApplicationUser,...>` cùng ánh xạ `AspNetUsers`).

Kiểm tra:
- Tìm `class ApplicationUser` trong solution.
- Tìm `DbSet<AspNetUser>` và các `modelBuilder.Entity<...>().ToTable("AspNetUsers")` trùng lặp.

Khắc phục:
- Giữ một kiểu duy nhất cho user (trong hướng dẫn này là `AspNetUser`).
- Đảm bảo chỉ map bảng `AspNetUsers` một lần: gọi `base.OnModelCreating()` và sử dụng `modelBuilder.Entity<AspNetUser>().ToTable("AspNetUsers")` nếu cần.

---

## 9. Best practices & security

- Bật Email confirmation (RequireConfirmedEmail) nếu muốn hạn chế người dùng chưa xác thực.
- Đặt password policy phù hợp cho môi trường production.
- Token expiry ngắn (ví dụ 1 giờ) + refresh token an toàn.
- Không commit secrets vào repo: dùng user-secrets hoặc environment variables cho JWT key.
- Khi re-scaffold DB, đặt scaffold vào thư mục tạm và merge thủ công — tránh ghi đè các file Identity đã chỉnh sửa.

---

## 10. Next steps (tùy chọn tôi có thể làm giúp)

- Tạo `AccountController` file trong project API với mã mẫu trên.
- Tạo `RoleSeeder` file và gọi trong Program.cs.
- Thêm cấu hình JWT vào Program.cs và cập nhật Swagger để dùng Bearer token.
- Tạo migration mẫu và cung cấp SQL để review.

Nếu bạn muốn tôi tạo các file mẫu (Controller, Seeder, JWT config) trong workspace và chạy build, xác nhận tác vụ cụ thể — tôi sẽ thực hiện và kiểm tra build.

---

## 11. Các bước còn thiếu — hướng dẫn thực thi nhanh (actionable checklist)

Dưới đây là danh sách các bước cụ thể cần làm tiếp để hoàn tất tích hợp Identity, mỗi bước kèm tệp cần tạo/sửa và lệnh kiểm tra.

1) Tạo Design‑time DbContext Factory
- File: `LmsMini.Infrastructure/Persistence/LmsDbContextFactory.cs`
- Làm: implement `IDesignTimeDbContextFactory<LmsDbContext>` theo mẫu.
- Kiểm tra: `dotnet ef migrations add TestFactory -p LmsMini.Infrastructure -s LmsMini.Api` (sau khi kiểm tra xong, xóa migration thử).

2) Tạo RoleSeeder và AdminSeeder
- File: `LmsMini.Infrastructure/Services/RoleSeeder.cs` và `AdminSeeder.cs` (tuỳ)
- Làm: dùng `RoleManager<IdentityRole<Guid>>` và `UserManager<AspNetUser>` để tạo các role và admin mặc định.
- Kiểm tra: chạy app và kiểm tra bảng `AspNetRoles`/`AspNetUsers`.

3) Tạo AccountController (Register/Login/Confirm/Reset)
- File: `LmsMini.Api/Controllers/AccountController.cs`
- Làm: sử dụng `UserManager<AspNetUser>`, `SignInManager<AspNetUser>` để implement register/login; nếu dùng JWT thì tạo token.
- Kiểm tra: đăng ký user + login qua Swagger/Postman, nhận token.

4) Cấu hình JWT & Swagger
- File: `LmsMini.Api/Program.cs` và `appsettings.Development.json` (hoặc user‑secrets)
- Làm: thêm `AddAuthentication().AddJwtBearer(...)`, lưu `Jwt:Key`/`Issuer`/`Audience` ở secret.
- Kiểm tra: login → copy token → Swagger Authorize → gọi endpoint bảo vệ.

5) Email sender cho Confirm/Reset (dev stub)
- File: `LmsMini.Infrastructure/Services/EmailSender.cs`
- Làm: implement `IEmailSender` (dev: log token to console; prod: SMTP).
- Kiểm tra: gửi confirm/reset link và kiểm tra log.

6) Dọn các lớp scaffolded trùng (nếu có)
- Tìm: `AspNetUserClaim.cs`, `AspNetUserLogin.cs`, `AspNetUserToken.cs`, `AspNetRoleClaim.cs`, v.v.
- Quy tắc: chỉ dùng built‑in Identity types (IdentityUserClaim, IdentityUserLogin, ...) hoặc xóa scaffolded file để tránh duplicate mapping.
- Kiểm tra: `dotnet build` không báo lỗi duplicate entity mapping.

7) Migration baseline & review
- Lệnh tạo migration:
  `dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api`
- Kiểm tra SQL script:
  `dotnet ef migrations script -p LmsMini.Infrastructure -s LmsMini.Api`
- Nếu DB có sẵn AspNet* và không muốn thay đổi, tạo migration rỗng hoặc dùng baseline.

8) Tests & CI
- Viết unit/integration tests cho register/login/role seeding.
- Thêm CI step: block PR nếu migration thay đổi AspNet* mà chưa review.

9) Chuẩn hóa navigation types
- Tìm toàn cục `ApplicationUser` / `AspNetUser` và chuẩn hóa sang 1 type.
- Kiểm tra: `dotnet build`.

10) Secrets & cấu hình
- Lưu JWT key vào user‑secrets hoặc environment variables (không commit vào repo).
- Thêm `appsettings.Development.json.sample` chứa cấu trúc (không chứa secret).

---

Thực hiện các bước trên theo thứ tự sẽ giúp bạn hoàn tất tích hợp Identity an toàn và có thể chạy các flow register/login/role seeding một cách tin cậy. Nếu muốn, tôi có thể tạo các file mẫu (DesignTimeFactory, RoleSeeder, AdminSeeder, AccountController, EmailSender, và JWT config) trong workspace và chạy build/test — xác nhận hành động bạn muốn để tôi thực hiện tiếp.