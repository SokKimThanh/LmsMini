# Hướng dẫn chi tiết tích hợp ASP.NET Core Identity (Database‑first → Code‑First option)

Mục đích: tài liệu chi tiết, từng bước để bạn (hoặc team) thực hiện chuyển/đồng bộ Identity trong dự án LMS‑Mini.

Lưu ý: workspace hiện có `ApplicationUser : IdentityUser<Guid>` và các lớp scaffolded từ DB. Tài liệu này mô tả kịch bản chuyển sang code‑first (EF quản lý bảng AspNet*). Nếu bạn muốn giữ DBA quản lý bảng, xem phần "Nếu giữ database‑first".

---

## 1. Yêu cầu trước khi bắt đầu
- .NET 9 SDK
- Backup mã nguồn & database
- Kết nối DB (DefaultConnection) trong `LmsMini.Api/appsettings.Development.json` hoặc biến môi trường
- Đảm bảo projects tham chiếu nhau: Api → Infrastructure → Domain

---

## 2. Quyết định chiến lược
- Code‑first (khuyến nghị nếu bạn kiểm soát DB): EF tạo các bảng AspNet* qua migration.
- Database‑first (nếu DBA quản lý): cung cấp SQL cho DBA, chỉ map các CLR types vào bảng hiện có, KHÔNG chạy migration tạo AspNet*.

Bạn đã chọn chuyển sang code‑first => tiếp theo làm theo bước 3.

---

## 3. Các thay đổi cần thực hiện (theo thứ tự)

1. Consolidate User type
   - Giữ `LmsMini.Domain/Entities/Identity/ApplicationUser.cs` (kế thừa `IdentityUser<Guid>`).
   - Xóa hoặc deprecate các lớp scaffolded trùng (ví dụ `AspNetUser.cs`) để tránh duplicate mapping. Nếu muốn giữ file scaffolded, convert/merge thành `partial class ApplicationUser` (chỉ một CLR type ánh xạ bảng `AspNetUsers`).

2. Cập nhật DbContext
   - File: `LmsMini.Infrastructure/Persistence/LmsDbContext.cs`
   - Thực hiện:
     - Đổi inheritance: `IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>`
     - Loại bỏ `DbSet<AspNetUser>`; dùng `base.Users` hoặc thêm `DbSet<ApplicationUser> Users { get; set; }`
     - Gọi `base.OnModelCreating(modelBuilder);` ở đầu `OnModelCreating`.
     - (Tùy) Map tên bảng: `modelBuilder.Entity<ApplicationUser>().ToTable("AspNetUsers");` và map các Identity types tương ứng.

3. Cập nhật các entity tham chiếu user
   - Tìm các nơi dùng `AspNetUser` (Enrollment.User, QuizAttempt.User, FileAsset.OwnerUser, Progress.User, Notification.*SentBy/ToUser, AuditLog.User, Course.CreatedByNavigation, ...)
   - Thay kiểu thành `ApplicationUser` và giữ tên thuộc tính.
   - Thêm `using LmsMini.Domain.Entities.Identity;` nếu cần.

4. Program.cs (API)
   - File: `LmsMini.Api/Program.cs`
   - Thêm using:
     ```csharp
     using Microsoft.AspNetCore.Identity;
     using Microsoft.AspNetCore.Authentication.JwtBearer;
     using Microsoft.IdentityModel.Tokens;
     using System.Text;
     using LmsMini.Domain.Entities.Identity;
     ```
   - Thêm dịch vụ Identity:
     ```csharp
     builder.Services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
     {
         options.Password.RequireDigit = true;
         options.Password.RequiredLength = 6;
         options.Password.RequireNonAlphanumeric = false;
     })
     .AddEntityFrameworkStores<LmsDbContext>()
     .AddDefaultTokenProviders();
     ```
   - Nếu dùng JWT, đăng ký `AddAuthentication(...).AddJwtBearer(...)` lấy key từ `builder.Configuration["Jwt:Key"]`.
   - Trong pipeline: gọi `app.UseAuthentication();` trước `app.UseAuthorization();`.

5. Design‑time DbContext factory
   - Tạo file `LmsMini.Infrastructure/Persistence/LmsDbContextFactory.cs` implement `IDesignTimeDbContextFactory<LmsDbContext>` để EF CLI hoạt động độc lập.

6. RoleSeeder
   - Tạo một seeder idempotent để tạo các role `Admin`, `Instructor`, `Learner`. Gọi seeder sau `var app = builder.Build();` trước `app.Run();`.

7. Migration & Apply
   - Tạo migration: `dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api`
   - Apply: `dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api`

---

## 4. Một số đoạn code mẫu (copy‑paste)

### LmsDbContext (header & OnModelCreating mẫu)
```csharp
using LmsMini.Domain.Entities.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

public partial class LmsDbContext : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>
{
    public LmsDbContext(DbContextOptions<LmsDbContext> options) : base(options) { }

    // other DbSet<TEntity>

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // map Identity tables to default names (optional)
        modelBuilder.Entity<ApplicationUser>(b => b.ToTable("AspNetUsers"));
        modelBuilder.Entity<IdentityRole<Guid>>(b => b.ToTable("AspNetRoles"));
        modelBuilder.Entity<IdentityUserRole<Guid>>(b => b.ToTable("AspNetUserRoles"));
        modelBuilder.Entity<IdentityUserClaim<Guid>>(b => b.ToTable("AspNetUserClaims"));
        modelBuilder.Entity<IdentityUserLogin<Guid>>(b => b.ToTable("AspNetUserLogins"));
        modelBuilder.Entity<IdentityRoleClaim<Guid>>(b => b.ToTable("AspNetRoleClaims"));
        modelBuilder.Entity<IdentityUserToken<Guid>>(b => b.ToTable("AspNetUserTokens"));

        // existing entity mapping (Courses, Modules, ...)

        OnModelCreatingPartial(modelBuilder);
    }
}
```

### DesignTime factory (mẫu)
```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

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

### RoleSeeder (mẫu)
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

---

## 5. Kiểm tra & troubleshooting nhanh
- Build: `dotnet build` — sửa lỗi tham chiếu/using.
- EF migrations lỗi: chạy `dotnet ef database update` với design‑time factory; nếu Program.cs dùng configuration that causes failure at design time, factory sẽ giúp.
- Lỗi duplicate mapping: tìm file còn khai báo class mà cùng map `AspNetUsers` (xóa/merge).
- Nếu DB có dữ liệu cũ: cân nhắc tạo migration baseline thay vì để EF tạo lại bảng (tạo migration rỗng Up()).

---

## 6. Nếu bạn muốn giữ database‑first (DBA tạo bảng)
- Không run migrations để tạo AspNet*.
- Map `ApplicationUser` lên bảng hiện có: `modelBuilder.Entity<ApplicationUser>().ToTable("AspNetUsers")`.
- Provide SQL scripts (`LmsMini.Resources/File Tài liệu/File db sql/identity-create.sql`) cho DBA để tạo các bảng AspNetRoles/AspNetUserRoles/AspNetRoleClaims/... trước khi chạy seeder.

---

## 7. Checklist hoàn tất
- [ ] ApplicationUser là type duy nhất cho user
- [ ] LmsDbContext kế thừa IdentityDbContext và base.OnModelCreating gọi
- [ ] Tất cả references AspNetUser → ApplicationUser
- [ ] DesignTimeFactory tồn tại và build ok
- [ ] Tạo migration & apply (hoặc DBA đã tạo bảng nếu giữ database‑first)
- [ ] Seeder roles chạy thành công
- [ ] Test register/login/roles

---

## 8. Các bước còn thiếu (thực hiện ngay / ưu tiên)
Dưới đây là danh sách bước còn thiếu hoặc cần thực hiện tiếp để hoàn thiện tích hợp Identity — mỗi mục kèm gợi ý thực thi và lệnh/điểm kiểm tra.

1) Tạo Design‑time DbContext Factory
- Mục đích: EF CLI (dotnet ef) cần có factory để khởi tạo DbContext khi không chạy ứng dụng.
- Hành động: tạo `LmsMini.Infrastructure/Persistence/LmsDbContextFactory.cs` theo mẫu ở trên.
- Kiểm tra: `dotnet ef migrations add TestFactory -p LmsMini.Infrastructure -s LmsMini.Api` (sau khi tạo xong, xoá migration thử).

2) Tạo RoleSeeder và Admin Seeder
- Mục đích: đảm bảo roles tồn tại và có admin mặc định.
- Hành động: thêm `RoleSeeder` và `AdminSeeder` (dùng UserManager để tạo admin nếu chưa có).
- Gọi: sau `var app = builder.Build();` gọi `await RoleSeeder.SeedAsync(app.Services); await AdminSeeder.SeedAsync(app.Services);`.
- Kiểm tra: khởi chạy app và kiểm tra bảng AspNetRoles/AspNetUsers.

3) Thêm AccountController (Register/Login/Confirm/Reset)
- Mục đích: cung cấp API cho authentication.
- Hành động: tạo controller mẫu sử dụng UserManager/SignInManager và tạo JWT nếu dùng token.
- Kiểm tra: đăng ký 1 user, login, nhận token (hoặc cookie nếu dùng Cookie auth).

4) Cấu hình JWT & Swagger
- Mục đích: API sử dụng token bearer; Swagger có thể thử API bảo mật.
- Hành động: thêm AddAuthentication/JwtBearer trong Program.cs; thêm cấu hình Jwt: Key, Issuer, Audience trong appsettings.Development.json (hoặc user‑secrets).
- Kiểm tra: gọi login rồi dùng token ở Swagger Authorize.

5) Email sender cho Confirm/Reset
- Mục đích: gửi link xác nhận email và reset password.
- Hành động: cài IEmailSender (stub cho dev, SMTP cho prod) và inject vào AccountController.
- Kiểm tra: gửi email thử (hoặc log nội dung token vào console trong dev).

6) Loại bỏ/hoàn thiện các lớp scaffolded trùng
- Mục đích: tránh duplicate mapping (AspNetUserClaim, AspNetRoleClaim, v.v.).
- Hành động: tìm các file scaffolded `AspNetUserClaim.cs`, `AspNetUserLogin.cs`, `AspNetUserToken.cs`, `AspNetRoleClaim.cs`.
  - Nếu dùng Identity types built‑in (IdentityUserClaim, ...) → xóa file scaffolded tương ứng.
  - Nếu giữ scaffolded, đảm bảo không đăng ký mapping trùng trong DbContext.
- Kiểm tra: `dotnet build` không báo lỗi duplicate entity mapping.

7) Migrations: tạo migration baseline & apply an toàn
- Mục đích: không ghi đè dữ liệu hiện có.
- Hành động: review migration SQL (dotnet ef migrations script) trước khi apply.
- Nếu DB đã có bảng AspNet* và bạn không muốn thay đổi, tạo migration rỗng (Up() {}), hoặc tạo migration chỉ thêm những thay đổi cần thiết.

8) Tests & CI
- Viết tests cho: register/login flow, role seeding, protected endpoints.
- Thêm CI check: block PR nếu migration thay đổi AspNet* mà chưa review.

9) Cập nhật entities liên quan
- Mục đích: mọi navigation property dùng đúng type user.
- Hành động: tìm toàn cục "AspNetUser" và "ApplicationUser" — chuẩn hóa dùng 1 type.
- Kiểm tra: build và chạy unit tests.

10) Secrets & cấu hình
- Lưu JWT key vào user‑secrets hoặc environment variables; không commit vào repo.
- Thêm sample `appsettings.Development.json` (không chứa secret thật).

---

## 9. Lệnh thường dùng (tóm tắt)
- Tạo migration:
  `dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api`
- Áp dụng migration:
  `dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api`
- Chạy app:
  `dotnet run --project LmsMini.Api`
- Build toàn bộ solution:
  `dotnet build`

---

## 10. Kết luận
Thực hiện theo checklist ở phần 7 và các bước bổ sung ở phần 8 sẽ giúp bạn hoàn thành tích hợp ASP.NET Core Identity an toàn và không gây duplicate mapping. Nếu muốn, tôi có thể tự động tạo các file mẫu (DesignTimeFactory, RoleSeeder, AccountController, JWT config) trong workspace — xác nhận tác vụ mong muốn và tôi sẽ implement và chạy build kiểm tra.