# Hướng dẫn triển khai đầy đủ AccountController & các flow Identity

Mục tiêu: bổ sung đầy đủ các endpoint quản lý tài khoản (change password, forgot/reset password, confirm email, delete account, profile, refresh token/revoke, role management) và hướng dẫn các thay đổi cần thiết trong dự án để chạy được.

Tệp: `LmsMini.Resources/lessons/identity/AccountController_CompleteImplementation.md`

---

## Mục lục

- [1. Tóm tắt các endpoint cần thêm](#1-tóm-tắt-các-endpoint-cần-thêm)
  - [1.1 Bảng tóm tắt endpoint](#11-bảng-tóm-tắt-endpoint)
- [2. DTOs mẫu](#2-dtos-mẫu)
- [3. IEmailSender (service)](#3-iemailsender-service)
- [4. Program.cs — thay đổi cần (LmsMini.Api)](#4-programcs-—-thay-đổi-cần-lmsminiapi)
- [5. Mẫu code (AccountController) — snippets cho từng endpoint](#5-mẫu-code-accountcontroller-—-snippets-cho-từng-endpoint)
  - [5.1 Change password](#51-change-password)
  - [5.2 Forgot password](#52-forgot-password)
  - [5.3 Reset password](#53-reset-password)
  - [5.4 Confirm email](#54-confirm-email)
  - [5.5 Delete account (self)](#55-delete-account-self)
  - [5.6 Get / Update profile](#56-get--update-profile)
  - [5.7 Role endpoints (Admin only)](#57-role-endpoints-admin-only)
  - [5.8 Setup admin (chỉ lần đầu)](#58-setup-admin-chỉ-lần-đầu)
- [6. Email token encoding](#6-email-token-encoding)
- [7. RoleSeeder & AdminSeeder](#7-roleseeder--adminseeder)
- [8. Tests](#8-tests)
- [9. Security & Best practices](#9-security--best-practices)
- [10. Checklist thực hiện](#10-checklist-thực-hiện)

---

## 1. Tóm tắt các endpoint cần thêm

Phần này liệt kê các endpoint để triển khai tính năng quản lý tài khoản và role.

### 1.1 Bảng tóm tắt endpoint

| HTTP | URL | Auth | Mô tả |
|---:|---|---|---|
| POST | /api/account/change-password | Authorized | Đổi mật khẩu khi đã đăng nhập |
| POST | /api/account/forgot-password | Public | Gửi email chứa token reset (không tiết lộ user tồn tại) |
| POST | /api/account/reset-password | Public | Đặt lại mật khẩu bằng token |
| POST | /api/account/confirm-email | Public | Xác nhận email bằng token |
| DELETE | /api/account | Authorized | Xóa tài khoản của chính user (hoặc admin xóa khác) |
| GET | /api/account/me | Authorized | Lấy profile hiện tại |
| PUT | /api/account/me | Authorized | Cập nhật profile |
| POST | /api/account/refresh-token | Public/Authorized | (Tùy) Cấp mới access token bằng refresh token |
| POST | /api/account/logout | Authorized | (Tùy) Thu hồi refresh token |
| GET | /api/account/roles | Admin only | Lấy danh sách role |
| POST | /api/account/roles | Admin only | Tạo role mới |
| PUT | /api/account/roles/{id} | Admin only | Cập nhật role |
| DELETE | /api/account/roles/{id} | Admin only | Xóa role |
| POST | /api/account/setup-admin | Public (one-time) | Tạo admin mặc định & role (chỉ dùng lần đầu) |

---

## 2. DTOs mẫu

> Ghi chú: Một số DTO đã có sẵn trong project (ví dụ RegisterRequest, LoginRequest). Ở danh sách dưới, tôi **đánh dấu**:
>
> - **[EXISTING]** — kiểm tra trong dự án; không tạo lại nếu đã có.
> - **[CREATE]** — tạo mới trong `LmsMini.Api/Models` nếu chưa tồn tại.

```csharp
// [EXISTING] => kiểm tra trong dự án, không tạo nếu đã có
public record RegisterRequest(string Email, string Password); // [EXISTING]
public record LoginRequest(string Email, string Password);    // [EXISTING]

// [CREATE] => tạo mới trong LmsMini.Api/Models nếu chưa có
public record ChangePasswordRequest(string CurrentPassword, string NewPassword); // [CREATE]
public record ForgotPasswordRequest(string Email);                               // [CREATE]
public record ResetPasswordRequest(string Email, string Token, string NewPassword); // [CREATE]
public record ConfirmEmailRequest(Guid UserId, string Token);                    // [CREATE]
public record UpdateProfileRequest(string? UserName, string? DisplayName);       // [CREATE]
public record DeleteAccountRequest(string? Password);                            // [CREATE]
public record RoleRequest(string Name, string Description);                      // [CREATE]
public record SetupAdminRequest(string Email, string Password, string Role);     // [CREATE]
```

**Khi nào dùng**:

- [EXISTING] — đã dùng trong controller hiện tại (Register/Login). Không tạo lại.
- [CREATE] — cần cho các flow: đổi mật khẩu, quên/mật khẩu/confirm email, quản lý role, setup admin, cập nhật profile, xóa tài khoản.

*Gợi ý:* thêm annotation như `[Required]`, `[EmailAddress]`, `[StringLength]` tuỳ chính sách mật khẩu và validate input.

---

## 3. IEmailSender (service)

Mục đích: gửi email trong các flow *forgot-password* và *confirm-email*.

### 3.1 Interface

Tạo interface trong dự án Infrastructure:

```csharp
public interface IEmailSender
{
    Task SendEmailAsync(string to, string subject, string html);
}
```

### 3.2 Implementation dev stub

Ví dụ dev stub (ghi log hoặc gửi console) nằm tại `LmsMini.Infrastructure/Services/ConsoleEmailSender.cs`. Đăng ký DI:

```csharp
builder.Services.AddTransient<IEmailSender, ConsoleEmailSender>();
```

> Trong production: thay bằng SMTP provider hoặc dịch vụ email (SendGrid, SES...).

---

## 4. Program.cs — thay đổi cần (LmsMini.Api)

Trước khi sử dụng các API, cần đăng ký Identity, token providers và authentication.

### 4.1 Đăng ký Identity

Đoạn mẫu thêm vào `Program.cs`:

```csharp
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options => {
    options.User.RequireUniqueEmail = true;
    options.Password.RequiredLength = 6; // tuỳ môi trường
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();
```

### 4.2 JWT Bearer (nếu dùng JWT)

Đăng ký authentication + JWT bearer (tham khảo `Identity_FullGuide.md`).

### 4.3 Đăng ký IEmailSender

```csharp
builder.Services.AddTransient<IEmailSender, ConsoleEmailSender>();
```

### 4.4 Policies (tuỳ chọn)

Đăng ký policy hoặc role-based authorization nếu muốn dùng `[Authorize(Roles = "Admin")]`.

---

## 5. Mẫu code (AccountController) — snippets cho từng endpoint

> Mỗi đoạn code kèm mô tả ngắn trước khi hiển thị code. Giữ nguyên logic và nội dung kỹ thuật từ bản gốc.

### 5.1 Change password

**Mô tả:** Endpoint cho phép user đã đăng nhập đổi mật khẩu hiện tại.

```csharp
[HttpPost("change-password")]
[Authorize]
public async Task<IActionResult> ChangePassword(ChangePasswordRequest req)
{
    var user = await _userManager.GetUserAsync(User);
    if (user == null) return Unauthorized();

    var res = await _userManager.ChangePasswordAsync(user, req.CurrentPassword, req.NewPassword);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

### 5.2 Forgot password

**Mô tả:** Tạo token đặt lại mật khẩu và gửi email (không tiết lộ user tồn tại).

```csharp
[HttpPost("forgot-password")]
public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return Ok(); // không tiết lộ user tồn tại

    var token = await _userManager.GeneratePasswordResetTokenAsync(user);
    var encoded = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));
    var url = $"{_config["App:BaseUrl"]}/reset-password?email={Uri.EscapeDataString(user.Email)}&token={encoded}";

    await _emailSender.SendEmailAsync(user.Email, "Reset password", $"Click: {url}");
    return Ok();
}
```

> **Lưu ý:** cần `using Microsoft.AspNetCore.WebUtilities;` để dùng `WebEncoders`.

### 5.3 Reset password

**Mô tả:** Nhận token (Base64Url) và đặt mật khẩu mới.

```csharp
[HttpPost("reset-password")]
public async Task<IActionResult> ResetPassword(ResetPasswordRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return BadRequest("Invalid request");

    var token = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(req.Token));
    var res = await _userManager.ResetPasswordAsync(user, token, req.NewPassword);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

### 5.4 Confirm email

**Mô tả:** Xác nhận email bằng token (thường dùng sau đăng ký).

```csharp
[HttpPost("confirm-email")]
public async Task<IActionResult> ConfirmEmail(ConfirmEmailRequest req)
{
    var user = await _userManager.FindByIdAsync(req.UserId.ToString());
    if (user == null) return BadRequest();

    var res = await _userManager.ConfirmEmailAsync(user, req.Token);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

### 5.5 Delete account (self)

**Mô tả:** Xóa tài khoản của chính user đã đăng nhập. Có thể yêu cầu nhập lại mật khẩu.

```csharp
[HttpDelete]
[Authorize]
public async Task<IActionResult> DeleteAccount(DeleteAccountRequest? req = null)
{
    var user = await _userManager.GetUserAsync(User);
    if (user == null) return Unauthorized();

    if (req?.Password != null)
    {
        var check = await _userManager.CheckPasswordAsync(user, req.Password);
        if (!check) return BadRequest("Invalid password");
    }

    var res = await _userManager.DeleteAsync(user);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

### 5.6 Get / Update profile

**Mô tả:** Lấy thông tin profile hiện tại và cập nhật các trường cho phép.

```csharp
[HttpGet("me")]
[Authorize]
public async Task<IActionResult> Me()
{
    var user = await _userManager.GetUserAsync(User);
    if (user == null) return Unauthorized();
    var roles = await _userManager.GetRolesAsync(user);
    return Ok(new { user.Id, user.Email, user.UserName, Roles = roles });
}

[HttpPut("me")]
[Authorize]
public async Task<IActionResult> UpdateProfile(UpdateProfileRequest req)
{
    var user = await _userManager.GetUserAsync(User);
    if (user == null) return Unauthorized();

    if (!string.IsNullOrWhiteSpace(req.UserName)) user.UserName = req.UserName;
    // cập nhật các trường khác nếu có

    var res = await _userManager.UpdateAsync(user);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

### 5.7 Role endpoints (Admin only)

**Mô tả:** CRUD cho role; chỉ Admin mới được phép (hoặc policy tương đương).

```csharp
[HttpGet("roles")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> GetRoles()
{
    var roles = await _roleManager.Roles.ToListAsync();
    return Ok(roles);
}

[HttpPost("roles")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> CreateRole(RoleRequest req)
{
    var role = new IdentityRole<Guid> { Name = req.Name, NormalizedName = req.Name.ToUpper() };
    var res = await _roleManager.CreateAsync(role);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}

[HttpPut("roles/{id}")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> UpdateRole(Guid id, RoleRequest req)
{
    var role = await _roleManager.FindByIdAsync(id.ToString());
    if (role == null) return NotFound();

    role.Name = req.Name;
    role.NormalizedName = req.Name.ToUpper();
    var res = await _roleManager.UpdateAsync(role);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}

[HttpDelete("roles/{id}")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> DeleteRole(Guid id)
{
    var role = await _roleManager.FindByIdAsync(id.ToString());
    if (role == null) return NotFound();

    var res = await _roleManager.DeleteAsync(role);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

### 5.8 Setup admin (chỉ lần đầu)

**Mô tả:** Tạo role **Admin** và một user admin mặc định (dùng khi mới triển khai DB lần đầu).

```csharp
[HttpPost("setup-admin")]
public async Task<IActionResult> SetupAdmin(SetupAdminRequest req)
{
    var adminRole = new IdentityRole<Guid> { Name = "Admin", NormalizedName = "ADMIN" };
    await _roleManager.CreateAsync(adminRole);

    var user = new AspNetUser { UserName = req.Email, Email = req.Email };
    var res = await _userManager.CreateAsync(user, req.Password);
    if (res.Succeeded)
    {
        await _userManager.AddToRoleAsync(user, adminRole.Name);
        return Ok();
    }
    return BadRequest(res.Errors);
}
```

> Thay `await _role_manager.CreateAsync` bằng `await _roleManager.CreateAsync` nếu đặt tên biến là `_roleManager` trong constructor.

---

## 6. Email token encoding

**Mô tả:** Token do Identity sinh có ký tự đặc biệt — *không* truyền thẳng trong URL. Dùng Base64Url encode/decode.

```csharp
var token = await _user_manager.GeneratePasswordResetTokenAsync(user);
var encoded = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));

// Khi nhận lại
var decoded = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(encodedToken));
```

> Cần `using Microsoft.AspNetCore.WebUtilities;`.

---

## 7. RoleSeeder & AdminSeeder

**Mô tả:** Seeder tạo các role mặc định (Admin, Instructor, Learner) và (tuỳ) tạo admin user.

**Ví dụ RoleSeeder:**

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

**Gọi seeder** sau `var app = builder.Build();`:

```csharp
await RoleSeeder.SeedAsync(app.Services);
```

**AdminSeeder (tuỳ chọn):** tạo user admin mặc định và gán role Admin; lưu credentials trong config hoặc user-secrets (không commit vào repo).

---

## 8. Tests

Viết integration tests cho các flow sau:

- Register + Login → trả JWT.
- ForgotPassword → token generate (mock `IEmailSender`).
- ResetPassword → cập nhật mật khẩu.
- ChangePassword (thành công / lỗi).
- DeleteAccount.
- Role CRUD (Admin endpoints).

*Gợi ý:* mock `UserManager`/`RoleManager` hoặc dùng test server + in-memory DB.

---

## 9. Security & Best practices

Danh sách các điểm bảo mật cần chú ý:

- **Không tiết lộ** user tồn tại trong phản hồi của *forgot-password* (always return 200 Ok).
- **RequireConfirmedEmail**: bật nếu muốn chặn login khi chưa xác thực email.
- **Password policy**: đặt chính sách mật khẩu phù hợp môi trường production (length, complexity).
- **Secrets**: lưu `Jwt:Key`/admin passwords trong user-secrets hoặc biến môi trường — **không** commit vào repo.
- **Token expiry**: access token nên có thời hạn ngắn (ví dụ 1 giờ); dùng refresh token an toàn nếu cần.
- **Re-authentication**: yêu cầu nhập lại mật khẩu cho hành động nhạy cảm (xóa tài khoản, đổi mật khẩu lớn).
- **Logging & Monitoring**: log các sự kiện đăng nhập thất bại, reset token requests, admin role changes.
- **Input validation**: dùng DataAnnotations và server-side validation để tránh injection/XSS.
- **Least privilege**: chỉ cho admin quyền tạo/xoá/ cập nhật role.

---

## 10. Checklist thực hiện (chi tiết hành động)

1. Tạo DTOs [CREATE] trong `LmsMini.Api/Models` nếu chưa có.
2. Tạo `IEmailSender` + `ConsoleEmailSender` trong `LmsMini.Infrastructure/Services`; đăng ký DI.
3. Cập nhật `Program.cs`: AddIdentity, AddDefaultTokenProviders, AddAuthentication (JwtBearer), đăng ký IEmailSender.
4. Thêm `RoleSeeder` (và tuỳ chọn `AdminSeeder`) và gọi sau `builder.Build()`.
5. Mở `LmsMini.Api/Controllers/AccountController.cs`, inject thêm `RoleManager<IdentityRole<Guid>>` nếu cần và thêm endpoint code theo mẫu.
6. Thêm `using Microsoft.AspNetCore.WebUtilities;` cho Base64Url encode/decode.
7. Chạy `dotnet build` và `dotnet run`; kiểm tra bằng Postman/Swagger.
8. Viết integration tests (mock hoặc test server) cho các flow quan trọng.

---

Nếu bạn muốn, tôi có thể:

- **A**: Tạo các DTO [CREATE] + IEmailSender stub + cập nhật skeleton `Program.cs` + thêm methods vào `AccountController` và chạy build.
- **B**: Chỉ giữ tài liệu (xong) — bạn thực hiện các bước tiếp theo.

Chọn A hoặc B để tôi thực hiện tiếp.
