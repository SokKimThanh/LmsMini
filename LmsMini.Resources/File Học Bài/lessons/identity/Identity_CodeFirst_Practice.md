# Identity - Lộ Trình Thực Hành (Code-First) - LmsMini

## Tổng Quan
- Sử dụng ASP.NET Core Identity theo Code-First giúp đơn giản hóa cấu hình và tránh xung đột với các lớp POCO scaffolded.
- Identity bản thân đã cung cấp mapping mặc định cho AspNet* table. Nếu không cần thiết, không nên scaffold các bảng AspNet* từ database.

## Tại Sao Không Nên Scaffold AspNet* (DB-first) Nếu Không Bắt Buộc
- Scaffold tạo nhiều POCO trùng lặp với các Identity types, dẫn đến:
  - Duplicate mapping -> lỗi EF: "table mapped twice".
  - Công tác hoán đổi code để kế thừa từ Identity types.
- Không để kiểm soát schema thông qua code sẽ làm phức tạp việc hợp nhất với DBA.

## Lỗi Chính Hay Gặp: "table mapped twice"
- Xảy ra khi có 2 CLR entity khác nhau được map cùng 1 bảng mà không có quan hệ (inheritance hoặc FK chung).
- Ví dụ: bạn có class AspNetRoleClaim (POCO) và IdentityRoleClaim<Guid> cùng map vào AspNetRoleClaims.
- Cách giải: sử dụng cùng 1 CLR type cho Identity role claim hoặc xóa mapping thủ công cho entity trùng lặp.

## Code-First: Các Bước Thực Hiện (Chi Tiết)
1. Cài đặt package (trong project Infrastructure):
   - Microsoft.AspNetCore.Identity.EntityFrameworkCore
   - Microsoft.EntityFrameworkCore.SqlServer
2. Định nghĩa model (nếu cần):
   - class ApplicationUser : IdentityUser<Guid> { /* navigation properties nếu cần */ }
   - class ApplicationRole : IdentityRole<Guid> { }
3. Tạo DbContext:
   - public class LmsDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>
   - Trong OnModelCreating: gọi base.OnModelCreating(modelBuilder) để dùng mapping mặc định của Identity. Add các mapping domain khác ở đây.
4. Đăng ký Identity trong Program.cs:
   - builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(opts => { /* options */ })
       .AddEntityFrameworkStores<LmsDbContext>()
       .AddDefaultTokenProviders();
   - Đăng ký DbContext trước khi Build.
   - Gọi app.UseAuthentication(); app.UseAuthorization(); sắp xếp thứ tự đúng.
5. Tạo và apply migrations:
   - dotnet ef migrations add InitialIdentityAndDomain -p LmsMini.Infrastructure -s LmsMini.Api
   - dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
   - Nếu DB-first bắt buộc: thao tác với DBA để chặn migrations thay đổi AspNet*.
6. Seeder roles và admin:
   - Sử dụng RoleManager<ApplicationRole> và UserManager<ApplicationUser> trong scope khi app start.
   - Thực hiện idempotent (kiểm tra tồn tại trước khi tạo).

## Ví Dụ Seeder (Kiến Nghị)
```
using (var scope = app.Services.CreateScope())
{
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();
    var roles = new[] { "Admin", "Instructor", "Student" };
    foreach (var r in roles)
    {
        if (!roleManager.RoleExistsAsync(r).GetAwaiter().GetResult())
        {
            roleManager.CreateAsync(new ApplicationRole { Name = r }).GetAwaiter().GetResult();
        }
    }
}
```

## Best Practices Và Lưu Ý
- Không tạo POCO mới cho AspNet* nếu có thể kế thừa Identity types.
- Nếu đã scaffold từ DB: chuyển các POCO để kế thừa IdentityUser/IdentityRole/IdentityRoleClaim... để tránh duplicate mapping.
- Nếu cần join table tự động, sử dụng cấu hình mặc định Identity cho UserRoles, không dùng UsingEntity<Dictionary<...>> từ ngoài.
- Tách cấu hình Identity vào partial OnModelCreatingPartial để dễ quản lý nếu cần regen code.
- Trong CI, chặn migrations thay đổi AspNet* nếu DBA quản lý schema.

## Lệnh Tham Khảo Nhanh
- dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
- dotnet ef migrations add Initial -p LmsMini.Infrastructure -s LmsMini.Api
- dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
