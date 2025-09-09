# Hướng dẫn triển khai đầy đủ AccountController & các flow Identity

Mục tiêu: bổ sung đầy đủ các endpoint quản lý tài khoản (change password, forgot/reset password, confirm email, delete account, profile, refresh token/revoke) và hướng dẫn các thay đổi cần thiết trong project để chạy được.

Tệp này đặt tại: `LmsMini.Resources/lessons/identity/AccountController_CompleteImplementation.md`

---

## 1. Tóm tắt các endpoint cần thêm

- POST /api/account/change-password
  - Auth: [Authorize]
  - Body: { CurrentPassword, NewPassword }
  - Hành động: _userManager.ChangePasswordAsync(user, current, new)_

- POST /api/account/forgot-password
  - Body: { Email }
  - Hành động: _userManager.GeneratePasswordResetTokenAsync(user)_ + gửi email chứa token (url encode)

- POST /api/account/reset-password
  - Body: { Email, Token, NewPassword }
  - Hành động: _userManager.ResetPasswordAsync(user, token, new)_

- POST /api/account/confirm-email
  - Body: { UserId, Token }
  - Hành động: _userManager.ConfirmEmailAsync(user, token)_

- DELETE /api/account
  - Auth: [Authorize]
  - Optional body: { Password } (xác thực lại) hoặc admin delete by id
  - Hành động: _userManager.DeleteAsync(user)_ (hoặc soft delete theo SDD)

- GET /api/account/me
  - Auth: [Authorize]
  - Trả về profile cơ bản (id, email, userName, roles)

- PUT /api/account/me
  - Auth: [Authorize]
  - Update profile (display name, avatar, ...) → _userManager.UpdateAsync(user)_

- POST /api/account/refresh-token (tuỳ chọn)
  - Nếu dùng refresh tokens server-side: validate + issue new access token

- POST /api/account/logout (tuỳ chọn)
  - Nếu dùng server-side token revocation: đánh dấu refresh token bị thu hồi

---

## 2. DTOs mẫu (tạo file trong LmsMini.Api/Models hoặc LmsMini.Application)

```csharp
public record RegisterRequest(string Email, string Password);
public record LoginRequest(string Email, string Password);
public record ChangePasswordRequest(string CurrentPassword, string NewPassword);
public record ForgotPasswordRequest(string Email);
public record ResetPasswordRequest(string Email, string Token, string NewPassword);
public record ConfirmEmailRequest(Guid UserId, string Token);
public record UpdateProfileRequest(string? UserName, string? DisplayName);
public record DeleteAccountRequest(string? Password);
```

Gợi ý: thêm DataAnnotations nếu cần.

---

## 3. IEmailSender (service) — cần để gửi token confirm/reset

- Tạo interface trong Infrastructure:

```csharp
public interface IEmailSender
{
    Task SendEmailAsync(string to, string subject, string html);
}
```

- Tạo implementation dev stub (log to console / Serilog) trong LmsMini.Infrastructure/Services/EmailSender.cs và đăng ký DI:

```csharp
builder.Services.AddTransient<IEmailSender, ConsoleEmailSender>();
```

Production: thay bằng SMTP provider.

---

## 4. Program.cs — thay đổi cần (LmsMini.Api)

- Đăng ký Identity nếu chưa có:

```csharp
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options => {
    options.User.RequireUniqueEmail = true;
    options.Password.RequiredLength = 6; // tuỳ môi trường
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();
```

- Đăng ký JWT (nếu chưa): AddAuthentication + AddJwtBearer (xem Identity_FullGuide.md)
- Đăng ký IEmailSender stub

---

## 5. Mẫu code (AccountController) — snippets cho từng endpoint

Lưu ý: controller hiện có register/login. Thêm methods sau (tóm tắt):

- Change password

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

- Forgot password

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

- Reset password

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

- Confirm email

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

- Delete account (self)

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

- Get / Update profile

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

---

## 6. Email token encoding

- Token chứa ký tự đặc biệt, dùng Base64Url encode khi truyền trong URL:

```csharp
var token = await _userManager.GeneratePasswordResetTokenAsync(user);
var encoded = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));
```

- Khi nhận lại:

```csharp
var decoded = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(encodedToken));
```

(Requires Microsoft.AspNetCore.WebUtilities)

---

## 7. RoleSeeder & AdminSeeder

- Tạo seeder để tạo role: Admin, Instructor, Learner; và 1 admin user mặc định (config secret).
- Gọi seeder sau khi `var app = builder.Build();`.

---

## 8. Tests

- Viết integration tests cho:
  - Register + Login → trả JWT
  - ForgotPassword → token generate (mock IEmailSender)
  - ResetPassword → cập nhật mật khẩu
  - ChangePassword success/fail
  - DeleteAccount

---

## 9. Security & Best practices

- Không trả về chi tiết (email exists) trong forgot-password.
- Dùng RequireConfirmedEmail tuỳ yêu cầu: nếu bật, block login cho user chưa confirm.
- Không commit JWT secrets; dùng user-secrets / environment variables.
- Token expiry ngắn; refresh token an toàn.
- Xác thực lại (reauth) cho các hành động quan trọng (delete, change password) nếu cần.

---

## 10. Checklist thực hiện (chi tiết hành động)

1. Tạo DTOs trong LmsMini.Api/Models.
2. Tạo IEmailSender + ConsoleEmailSender trong LmsMini.Infrastructure/Services; đăng ký DI.
3. Cập nhật Program.cs để AddIdentity + AddDefaultTokenProviders + AddAuthentication JwtBearer.
4. Mở `LmsMini.Api/Controllers/AccountController.cs`, thêm các endpoint code theo mẫu.
5. Đảm bảo `using Microsoft.AspNetCore.WebUtilities;` cho Base64Url.
6. Chạy `dotnet build` và `dotnet run`; test bằng Postman/Swagger.
7. Viết tests nếu có thời gian.

---

Nếu bạn muốn, tôi có thể:
- A: Tạo ngay các DTO files + IEmailSender stub + cập nhật Program.cs skeleton + thêm methods vào AccountController và chạy build.
- B: Chỉ tạo tài liệu này (xong) — bạn làm tiếp.

Chọn A hoặc B để tôi thực hiện tiếp.
