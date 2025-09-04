# Hướng dẫn nhanh: Thêm ASP.NET Identity (giải thích dành cho học sinh lớp 5)
<img width="402" height="678" alt="image" src="https://github.com/user-attachments/assets/9016642d-d9e4-4a47-94b8-578e794335e3" />

**Lưu ý ngắn (dành cho người làm kỹ thuật) — cô tóm tắt trước khi hướng dẫn các em:**

- "Đăng ký ASP.NET Identity" nghĩa là bật một bộ tính năng sẵn có để quản lý người dùng: lưu tên đăng nhập, mật khẩu, phân vai trò (Admin/Instructor/Learner), và xử lý đăng nhập/đăng xuất.
- Lưu ý: chương trình cần gọi đoạn cài đặt này trong Program.cs để hệ thống biết dùng Identity khi chạy.
- `AddEntityFrameworkStores<LmsDbContext>()` có nghĩa là: hãy dùng LmsDbContext (kết nối tới cơ sở dữ liệu) để lưu mọi thông tin người dùng và vai trò. Nói cách khác, Identity sẽ ghi dữ liệu vào những bảng trong database thông qua LmsDbContext.
- Sau khi thêm, cần bật middleware xác thực trong pipeline: `app.UseAuthentication()` và `app.UseAuthorization()` để cho phép kiểm tra ai được phép làm gì.
- Cuối cùng, phải tạo migration và cập nhật database (tạo bảng `AspNetUsers`, `AspNetRoles`, v.v.) — giống như xây tủ đựng thông tin người dùng trước khi sử dụng.

## Bảng mặc định khi bật Identity (ghi chú kỹ thuật)
Khi gọi `AddIdentity<...>().AddEntityFrameworkStores<LmsDbContext>()` và tạo migration, ASP.NET Identity sẽ tạo một tập hợp bảng mặc định trong database. Hãy xem và kiểm tra các bảng này trong file migration trước khi áp:

- `AspNetUsers` — lưu thông tin người dùng (username, email, password hash, v.v.).
- `AspNetRoles` — lưu các vai trò (role) như Admin/Instructor/Learner.
- `AspNetUserRoles` — ánh xạ nhiều-nhiều giữa người dùng và vai trò.
- `AspNetUserClaims` — lưu các claim gán cho user (thông tin thêm như quyền đặc biệt).
- `AspNetRoleClaims` — lưu các claim gán cho role.
- `AspNetUserLogins` — lưu thông tin đăng nhập từ nhà cung cấp bên ngoài (Google, Facebook, ...).
- `AspNetUserTokens` — lưu các token liên quan tới người dùng (ví dụ refresh token hoặc token xác thực hành động).

Lưu ý ngắn:
- Những bảng trên được sinh tự động bởi Identity khi migration được tạo; không phải do mình tự thêm tay.
- Trước khi apply migration, mở file migration và kiểm tra cấu trúc, kiểu khóa chính (string vs GUID), tên bảng/schema để đảm bảo phù hợp với dự án.

## Checklist tạo migration & lưu ý
- Tạo migration: `dotnet ef migrations add Init_Identity -s LmsMini.Api -p LmsMini.Infrastructure`.
- Mở file migration trong dự án Infrastructure và review các `CreateTable` cho `AspNet*`.
- Kiểm tra kiểu dữ liệu ID: nếu dự án dùng `Guid` cho user Id, đảm bảo `AspNetUser` kế thừa `IdentityUser<Guid>` và DbContext mapping tương ứng.
- Sau khi xác nhận, apply: `dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure`.

---

Xin chào các em! Hôm nay cô sẽ hướng dẫn các em từng bước rất đơn giản để thêm hệ thống quản lý người dùng vào chương trình. Cô nói chậm, rõ ràng để các em dễ hiểu nhé.

## 1. Sao lưu trước khi làm
- Cô khuyên các em hãy lưu lại mã trước khi sửa, giống như chụp ảnh trước khi thay đổi.
- Cách làm: chạy `git add .` rồi `git commit -m "backup trước khi thêm Identity"`.

## 2. Kiểm tra & cài gói cần thiết
- Trước khi bắt đầu, các em nên cài những gói sau để dự án có thể sử dụng ASP.NET Identity và EF Core migration.

Chạy những lệnh này trong thư mục chứa file `.csproj` của dự án API (ví dụ `LmsMini.Api`):

```bash
# Cài gói ASP.NET Identity với EF Core
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore

# Cài gói hỗ trợ thiết kế EF Core (dùng cho migration)
dotnet add package Microsoft.EntityFrameworkCore.Design

# Nếu dùng JWT để đăng nhập, cài thêm gói xác thực JWT Bearer
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

- Sau khi cài xong, chạy `dotnet restore` nếu cần và build dự án (`dotnet build`) để chắc các package đã được thêm thành công.

## 3. Kiểm tra "thẻ người dùng" và "tủ lưu"
- "Thẻ người dùng" là lớp AspNetUser — nơi lưu tên và mật khẩu của bạn.
- "Tủ lưu" là LmsDbContext — nơi chương trình cất thông tin vào cơ sở dữ liệu.
- Cần đảm bảo LmsDbContext biết cách làm việc với Identity (ví dụ: kế thừa hoặc cấu hình đúng).

## 4. Chuẩn bị khóa bí mật 🔑

Cô sẽ nói nhỏ dễ nghe nhé — chúng ta giữ bí mật này thật an toàn!

Khóa bí mật (JWT Key) giống như **chìa khóa nhà** – tuyệt đối không cho người khác mượn.  
Khóa này dùng để ký và kiểm tra **JSON Web Token (JWT)** khi các em đăng nhập.

### 📌 Lưu khóa bí mật

Các em có hai cách để lưu khóa, cô khuyên dùng cách 1 (User Secrets) khi đang làm trên máy của mình.

---

### **Cách 1: Lưu bằng User Secrets** (Khuyến nghị cho môi trường phát triển)

1. **Khởi tạo User Secrets** cho dự án (chạy trong thư mục chứa file `.csproj`):

```sh
dotnet user-secrets init
```

2. **Đặt khóa bí mật** (thay `<bí-mật>` bằng chuỗi bí mật của bạn):

```sh
dotnet user-secrets set "Jwt:Key" "<bí-mật>"
```

3. **Kiểm tra lại**:

```sh
dotnet user-secrets list
```

Kết quả sẽ hiển thị ví dụ:

```
Jwt:Key = <bí-mật>
```

---

### **Cách 2: Lưu trong appsettings.Development.json** (Chỉ dùng khi không thể dùng User Secrets)

Mở file `appsettings.Development.json` và thêm:

```json
{
  "Jwt": {
    "Key": "<bí-mật>"
  }
}
```

⚠️ Lưu ý: Không commit file này lên Git nếu chứa khóa thật.

---

### 📥 Sử dụng khóa trong mã nguồn
Trong `Program.cs` hoặc nơi cấu hình JWT, lấy khóa bằng:

```csharp
var jwtKey = builder.Configuration["Jwt:Key"];
```

Khóa sẽ được lấy từ User Secrets hoặc `appsettings.Development.json` tùy môi trường.

### 🔒 Lưu ý bảo mật
- Không viết khóa trực tiếp trong mã nguồn (hardcode).
- Không commit khóa bí mật lên GitHub.
- Ở môi trường production, nên lưu khóa trong biến môi trường hoặc dịch vụ bảo mật như Azure Key Vault.

## 5. Ví dụ cấu hình Program.cs (mẫu)

Dưới đây là ví dụ ngắn gọn minh họa nơi nên đăng ký Identity, liên kết với LmsDbContext, và cấu hình JWT Bearer. Hãy điều chỉnh theo kiểu Id của dự án (string hoặc Guid) và namespace thực tế.

```csharp
// using directives (thêm nếu cần)
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Lấy key từ cấu hình
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Missing Jwt:Key");

// DbContext registration (ví dụ)
builder.Services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Identity registration
// Giả sử AspNetUser : IdentityUser<Guid> và dùng Guid cho role
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();

// Authentication - JWT
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

var app = builder.Build();

// Middleware
app.UseAuthentication();
app.UseAuthorization();

// ... Map controllers, etc.
```

> Ghi chú: Nếu dự án sử dụng `string` cho Id (mặc định của Identity), thay `IdentityRole<Guid>` bằng `IdentityRole` và `IdentityUser<Guid>` bằng `IdentityUser` hoặc loại user tương ứng.

## 6. Ví dụ seed Roles & Admin (mẫu)

Đoạn code sau là ví dụ đơn giản để tạo roles và một tài khoản admin nếu chưa tồn tại. Gọi hàm `SeedDataAsync` khi ứng dụng khởi động (ví dụ trong `Program.cs` sau khi `app` được build).

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
        {
            await roleManager.CreateAsync(new IdentityRole<Guid>(role));
        }
    }

    // Tạo admin nếu chưa có
    var adminEmail = "admin@example.com";
    var admin = await userManager.FindByEmailAsync(adminEmail);
    if (admin == null)
    {
        admin = new AspNetUser
        {
            UserName = "admin",
            Email = adminEmail,
            EmailConfirmed = true
        };
        var result = await userManager.CreateAsync(admin, "Admin@123");
        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(admin, "Admin");
        }
    }
}
```

Gọi khi ứng dụng khởi động:

```csharp
using (var scope = app.Services.CreateScope())
{
    await SeedDataAsync(scope.ServiceProvider);
}
```

> Lưu ý: Đổi mật khẩu mặc định và email trong ví dụ khi đưa vào môi trường thật; dùng secrets để lưu các giá trị nhạy cảm.

## 7. Sơ đồ đơn giản (minh họa)

Client → API (Controllers) → Identity / EF Core → Database (bảng AspNetUsers, AspNetRoles, ...)

ASCII minh họa nhỏ:

```
[Client]
   |
   | HTTP (login/register)
   v
[LmsMini API]
   |-- Identity services
   |-- JwtService
   v
[Database]
   |-- AspNetUsers
   |-- AspNetRoles
   |-- AspNetUserRoles
   |-- AspNetUserClaims
   ...
```

## 8. Kiểm tra bằng tay
- Dùng Postman hoặc Swagger để thử:
  - Đăng ký (register)
  - Đăng nhập (login)
  - Gọi endpoint đã bảo vệ để xem hệ thống có chặn khi chưa đăng nhập hay không

## 9. Giữ an toàn
- Không đưa khóa bí mật lên Git.
- Ở môi trường thật (production), ẩn hoặc giới hạn Swagger để không lộ thông tin.

## 10. Nếu có lỗi
- Nếu có vấn đề, các em có thể quay lại bản sao lưu (bước 1) hoặc phục hồi database từ bản backup.
- Luôn kiểm tra file migration trước khi áp vào database.

## Bản đồ ghi nhớ: ASP.NET Identity

Cô soạn giúp các em một tấm "bản đồ ghi nhớ" ngắn gọn để dễ ôn nhé.

1. Mục đích
- "Quản lý người dùng, vai trò, đăng nhập, phân quyền" — giống hệ thống an ninh tòa nhà: có danh sách cư dân (users), phân loại (roles), và thẻ ra vào (tokens).

2. Thành phần chính
- User (AspNetUsers): Lưu thông tin người dùng (tên, email, mật khẩu băm).
- Role (AspNetRoles): Nhóm quyền (Admin, Instructor, Learner).
- UserRole (AspNetUserRoles): Ai thuộc nhóm nào (mapping).
- Claims (AspNetUserClaims, AspNetRoleClaims): Quyền đặc biệt hoặc thông tin thêm.
- Login (AspNetUserLogins): Đăng nhập ngoài (Google, Facebook…).
- Tokens (AspNetUserTokens): Token xác thực, refresh token.

3. Các bước cài đặt cơ bản
- Cài gói:
  - Microsoft.AspNetCore.Identity.EntityFrameworkCore
  - Microsoft.EntityFrameworkCore.Design
  - (Nếu dùng JWT) Microsoft.AspNetCore.Authentication.JwtBearer
- Cấu hình trong Program.cs:
  - `AddIdentity<...>().AddEntityFrameworkStores<LmsDbContext>()`
  - `AddAuthentication().AddJwtBearer(...)`
- Bật middleware:
  - `app.UseAuthentication()`
  - `app.UseAuthorization()`
- Tạo migration & update DB:
  - `dotnet ef migrations add Init_Identity`
  - `dotnet ef database update`
- Seed dữ liệu: tạo roles và admin mặc định (RoleManager / UserManager).
- Bảo mật khóa JWT: lưu trong User Secrets hoặc biến môi trường.

4. Luồng hoạt động cơ bản
- Người dùng → gửi yêu cầu (login/register) → Controller → Identity (UserManager/SignInManager) → EF Core → Database (AspNetUsers, AspNetRoles...) → trả JWT (nếu dùng JWT).

5. Mẹo ghi nhớ
- 3 chữ vàng: User – Role – Token
- 2 lệnh sống còn: `UseAuthentication()` + `UseAuthorization()`
- 1 nơi lưu trữ: LmsDbContext
- 1 chìa khóa: `Jwt:Key` (giữ bí mật)

---

Tập tin này lưu tại: `LmsMini.Api/docs/identity/Identity_For_Grade5.md`
