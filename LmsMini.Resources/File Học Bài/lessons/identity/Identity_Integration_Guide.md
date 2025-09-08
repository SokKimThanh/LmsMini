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

Ghi chú: nếu bạn muốn, mình có thể tạo file snippets riêng (Program.cs diff, LmsDbContext diff, DesignTimeFactory, RoleSeeder) để bạn copy/paste. Hãy nói "tạo snippets" và mình sẽ tạo các file đó trong thư mục `LmsMini.Resources/Identity/snippets` để bạn dán vào dự án.