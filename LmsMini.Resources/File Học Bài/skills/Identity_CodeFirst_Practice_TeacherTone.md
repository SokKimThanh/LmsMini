# Identity - Lộ Trình Thực Hành (Code-First) - Phiên bản "Cô giáo trẻ trung"

Chào các em! Cô rất vui được đồng hành cùng các bạn trên hành trình tìm hiểu ASP.NET Core Identity theo hướng Code-First. Mình sẽ hướng dẫn từng bước, rõ ràng và dễ thực hành — như một buổi học ngắn gọn, sinh động.

## Tổng quan nhanh
- Code-First giúp ta quản lý schema bằng code, tránh xung đột khi dùng Identity sẵn có.
- Nếu không cần thiết, không scaffold các bảng AspNet* từ database — để tránh phức tạp không đáng có.

## Vì sao không nên scaffold AspNet* (nếu không bắt buộc)
- Scaffold từ DB thường sinh ra nhiều POCO trùng với Identity types, dễ dẫn tới lỗi "table mapped twice".
- Quản lý schema bằng code (Code-First) giúp team dễ đồng bộ và triển khai.

## Lỗi hay gặp: "table mapped twice"
- Xảy ra khi hai CLR entity khác nhau map cùng 1 bảng mà không có quan hệ rõ ràng.
- Ví dụ: có class `AspNetRoleClaim` (POCO) và `IdentityRoleClaim<Guid>` cùng map vào bảng `AspNetRoleClaims`.
- Khắc phục: dùng chung một CLR type cho các entity Identity hoặc bỏ mapping thủ công trùng lặp.

## Hướng dẫn thực hành (từng bước)
1. Cài package trong project Infrastructure:
   - Microsoft.AspNetCore.Identity.EntityFrameworkCore
   - Microsoft.EntityFrameworkCore.SqlServer
2. Định nghĩa model (tuỳ nhu cầu):
   - `class ApplicationUser : IdentityUser<Guid> { }`
   - `class ApplicationRole : IdentityRole<Guid> { }`
3. Tạo DbContext:
   - `public class LmsDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>`
   - Trong `OnModelCreating`, gọi `base.OnModelCreating(modelBuilder)` rồi thêm mapping domain khác.
4. Đăng ký Identity trong `Program.cs`:
   - `builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(opts => { /* options */ })`
     `.AddEntityFrameworkStores<LmsDbContext>()`
     `.AddDefaultTokenProviders();`
   - Đăng ký DbContext trước khi `builder.Build()`.
   - Gọi `app.UseAuthentication()` trước `app.UseAuthorization()`.
5. Migrations và apply:
   - `dotnet ef migrations add InitialIdentityAndDomain -p LmsMini.Infrastructure -s LmsMini.Api`
   - `dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api`
6. Seeder roles và admin (idempotent):
   - Dùng `RoleManager<ApplicationRole>` và `UserManager<ApplicationUser>` trong scope khi app khởi động.

## Ví dụ seeder ngắn (tham khảo)
```csharp
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

## Lưu ý và best practices
- Nếu có thể, không tạo POCO riêng cho AspNet* — hãy kế thừa Identity types.
- Nếu đã scaffold từ DB, chuyển POCO để kế thừa `IdentityUser`/`IdentityRole`/... để tránh duplicate mapping.
- Tách cấu hình Identity ra `OnModelCreatingPartial` để dễ bảo trì.
- Trong CI: kiểm tra và chặn migration làm thay đổi AspNet* nếu DBA quản lý schema.

---

Muốn cô thêm checklist CI hoặc phiên bản tiếng Anh không? Cô sẵn sàng giúp tiếp!