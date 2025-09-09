# Hướng dẫn triển khai đầy đủ AccountController & các flow Identity

Mục tiêu: bổ sung đầy đủ các endpoint quản lý tài khoản (change password, forgot/reset password, confirm email, delete account, profile, refresh token/revoke, role management) và hướng dẫn các thay đổi cần thiết trong dự án để chạy được.

Tệp: `LmsMini.Resources/lessons/identity/AccountController_CompleteImplementation.md`

---

## Mục lục

- [1. Tóm tắt các endpoint cần thêm](#1-tóm-tắt-các-endpoint-cần-thêm)
  - [1.1 Bảng tóm tắt endpoint](#11-bảng-tóm-tắt-endpoint)
- [2. DTOs mẫu](#2-dtos-mẫu)
- [3. IEmailSender (service)](#3-iemailsender-service)
  - [3.1 Interface](#31-interface)
  - [3.2 Dev stub (ConsoleEmailSender)](#32-dev-stub-consoleemailsender)
  - [3.3 Production implementations (SMTP / SendGrid)](#33-production-implementations-smtp--sendgrid)
- [4. Program.cs — đăng ký Identity, JWT và DI](#4-programcs-—-đăng-ký-identity-jwt-và-di)
  - [4.1 AddIdentity & TokenProviders](#41-addidentity--tokenproviders)
  - [4.2 JWT configuration (AddAuthentication + AddJwtBearer)](#42-jwt-configuration-addauthentication--addjwtbearer)
  - [4.3 Đăng ký IEmailSender và RoleSeeder](#43-đăng-ký-iemailsender-và-roleseeder)
- [5. Mẫu code (AccountController) — snippets cho từng endpoint](#5-mẫu-code-accountcontroller-—-snippets-cho-từng-endpoint)
  - [5.1 Change password](#51-change-password)
  - [5.2 Forgot password](#52-forgot-password)
  - [5.3 Reset password](#53-reset-password)
  - [5.4 Confirm email](#54-confirm-email)
  - [5.5 Delete account (self)](#55-delete-account-self)
  - [5.6 Get / Update profile](#56-get--update-profile)
  - [5.7 Role endpoints (Admin only)](#57-role-endpoints-admin-only)
  - [5.8 Setup admin (chỉ lần đầu)](#58-setup-admin-chỉ-lần-đầu)
  - [5.9 Login / Register — cập nhật để phát refresh token và gán role](#59-login--register-—-cập-nhật-để-phát-refresh-token-và-gán-role)
  - [5.10 Refresh token & Logout (code mẫu hoàn chỉnh)](#510-refresh-token--logout-code-mẫu-hoàn-chỉnh)
- [6. Email token encoding](#6-email-token-encoding)
- [7. RoleSeeder & AdminSeeder](#7-roleseeder--adminseeder)
- [8. Migration & cập nhật database schema](#8-migration--cập-nhật-database-schema)
- [9. Tests (xUnit) — ví dụ mẫu](#9-tests-xunit-—-ví-dụ-mẫu)
- [10. Security & Best practices](#10-security--best-practices)
- [11. Checklist thực hiện (chi tiết hành động)](#11-checklist-thực-hiện-chi-tiết-hành-động)

---

## 1. Tóm tắt các endpoint cần thêm

Phần này liệt kê các endpoint để triển khai tính năng quản lý tài khoản và role.

### 1.1 Bảng tóm tắt endpoint

| HTTP | URL | Auth | Mô tả | Input DTO | Output |
|---:|---|---|---|---|---|
| POST | /api/account/change-password | Authorized | Đổi mật khẩu | ChangePasswordRequest | 200 Ok / 400 BadRequest |
| POST | /api/account/forgot-password | Public | Gửi email chứa token reset | ForgotPasswordRequest | 200 Ok |
| POST | /api/account/reset-password | Public | Đặt lại mật khẩu bằng token | ResetPasswordRequest | 200 Ok / 400 BadRequest |
| POST | /api/account/confirm-email | Public | Xác nhận email bằng token | ConfirmEmailRequest | 200 Ok / 400 BadRequest |
| DELETE | /api/account | Authorized | Xóa tài khoản của chính user | DeleteAccountRequest? | 200 Ok / 400 BadRequest |
| GET | /api/account/me | Authorized | Lấy profile hiện tại | - | profile JSON |
| PUT | /api/account/me | Authorized | Cập nhật profile | UpdateProfileRequest | 200 Ok / 400 BadRequest |
| POST | /api/account/refresh-token | Public | Đổi refresh token lấy access token mới | RefreshTokenRequest | { accessToken, refreshToken } |
| POST | /api/account/logout | Authorized | Thu hồi refresh token | LogoutRequest | 200 Ok |
| GET | /api/account/roles | Admin only | Lấy danh sách role | - | list roles |
| POST | /api/account/roles | Admin only | Tạo role mới | RoleRequest | 200 Ok / 400 BadRequest |
| PUT | /api/account/roles/{id} | Admin only | Cập nhật role | RoleRequest | 200 Ok / 404 |
| DELETE | /api/account/roles/{id} | Admin only | Xóa role | - | 200 Ok / 404 |
| POST | /api/account/setup-admin | Public (one-time) | Tạo admin mặc định & role | SetupAdminRequest | 200 Ok / 400 |

> *Output* ở trên là mô tả ngắn; trong thực tế có thể trả object lỗi/chi tiết theo chuẩn API của dự án.

**Sơ đồ tổng quan endpoint**

Sơ đồ này minh họa toàn bộ các endpoint của AccountController, phân loại theo quyền truy cập.

```mermaid
flowchart LR
  classDef public fill:#e6ffed,stroke:#2e7d32,stroke-width:1px;
  classDef auth fill:#e8f4ff,stroke:#1565c0,stroke-width:1px;
  classDef admin fill:#fff0f0,stroke:#c62828,stroke-width:1px;

  subgraph PublicEndpoints["Public"]
    FP["api_forgot_password_""/api/account/forgot-password"]:::public
    RP["api_reset_password_""/api/account/reset-password"]:::public
    CE["api_confirm_email_""/api/account/confirm-email"]:::public
    RT["api_refresh_token_""/api/account/refresh-token"]:::public
    SA["api_setup_admin_""/api/account/setup-admin"]:::public
  end

  subgraph AuthorizedEndpoints["Authorized"]
    CP["api_change_password_""/api/account/change-password"]:::auth
    ME_GET["api_me_get_""/api/account/me (GET)"]:::auth
    ME_PUT["api_me_put_""/api/account/me (PUT)"]:::auth
    DEL["api_account_delete_""/api/account (DELETE)"]:::auth
    LO["api_logout_""/api/account/logout"]:::auth
  end

  subgraph AdminEndpoints["Admin"]
    GR["api_roles_get_""/api/account/roles (GET)"]:::admin
    CR["api_roles_create_""/api/account/roles (POST)"]:::admin
    UR["api_roles_update_""/api/account/roles/{id} (PUT)"]:::admin
    DR["api_roles_delete_""/api/account/roles/{id} (DELETE)"]:::admin
  end

  FP --> RP
  RP --> RT
  RT --> LO
  SA --> CR
  PublicEndpoints --> AuthorizedEndpoints
  AuthorizedEndpoints --> AdminEndpoints
```

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

// Refresh token related DTOs
public record RefreshTokenRequest(string RefreshToken);                          // [CREATE]
public record LogoutRequest(string RefreshToken);                                // [CREATE]
```

**Khi nào dùng**:

- [EXISTING] — đã dùng trong controller hiện tại (Register/Login). Không tạo lại.
- [CREATE] — cần cho các flow: đổi mật khẩu, quên/mật khẩu/confirm email, quản lý role, setup admin, cập nhật profile, xóa tài khoản, refresh token/logout.

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

### 3.2 Dev stub (ConsoleEmailSender)

Mô tả: implementation đơn giản để phát triển cục bộ — ghi log token / link ra console hoặc Serilog.

```csharp
// LmsMini.Infrastructure/Services/ConsoleEmailSender.cs
public class ConsoleEmailSender : IEmailSender
{
    private readonly ILogger<ConsoleEmailSender> _logger;
    public ConsoleEmailSender(ILogger<ConsoleEmailSender> logger) => _logger = logger;

    public Task SendEmailAsync(string to, string subject, string html)
    {
        _logger.LogInformation("SendEmail to {To} subject {Subject} body: {Html}", to, subject, html);
        return Task.CompletedTask;
    }
}
```

### 3.3 Production implementations (SMTP / SendGrid)

Mô tả: ví dụ triển khai cho SMTP và SendGrid. Lưu cấu hình trong `appsettings.json` hoặc user-secrets.

#### SMTP (System.Net.Mail)

```csharp
public class SmtpEmailSender : IEmailSender
{
    private readonly SmtpOptions _opts;
    public SmtpEmailSender(IOptions<SmtpOptions> opts) => _opts = opts.Value;

    public async Task SendEmailAsync(string to, string subject, string html)
    {
        using var smtp = new SmtpClient(_opts.Host, _opts.Port)
        {
            Credentials = new NetworkCredential(_opts.Username, _opts.Password),
            EnableSsl = _opts.EnableSsl
        };
        var msg = new MailMessage(_opts.From, to, subject, html) { IsBodyHtml = true };
        await smtp.SendMailAsync(msg);
    }
}

public class SmtpOptions { public string Host {get;set;} public int Port {get;set;} public bool EnableSsl {get;set;} public string Username {get;set;} public string Password {get;set;} public string From {get;set;} }
```

Đăng ký DI:

```csharp
builder.Services.Configure<SmtpOptions>(configuration.GetSection("Smtp"));
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();
```

#### SendGrid (example)

```csharp
public class SendGridEmailSender : IEmailSender
{
    private readonly string _apiKey;
    private readonly string _from;
    public SendGridEmailSender(IConfiguration config)
    {
        _apiKey = config["SendGrid:ApiKey"];
        _from = config["SendGrid:From"];
    }
    public async Task SendEmailAsync(string to, string subject, string html)
    {
        var client = new SendGrid.SendGridClient(_apiKey);
        var msg = new SendGrid.Helpers.Mail.SendGridMessage()
        {
            From = new SendGrid.Helpers.Mail.EmailAddress(_from),
            Subject = subject,
            HtmlContent = html
        };
        msg.AddTo(new SendGrid.Helpers.Mail.EmailAddress(to));
        await client.SendEmailAsync(msg);
    }
}
```

Đăng ký DI:

```csharp
builder.Services.AddTransient<IEmailSender, SendGridEmailSender>();
```

> **Bảo mật:** lưu API keys và credentials trong user-secrets hoặc biến môi trường.

---

## 4. Program.cs — đăng ký Identity, JWT và DI

Trước khi sử dụng các API, cần đăng ký Identity, token providers và authentication.

### 4.1 AddIdentity & TokenProviders

```csharp
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options =>
{
    options.User.RequireUniqueEmail = true;
    options.Password.RequiredLength = 8; // production: tăng cường
})
.AddEntityFrameworkStores<LmsDbContext>()
.AddDefaultTokenProviders();
```

### 4.2 JWT configuration (AddAuthentication + AddJwtBearer)

Mô tả: cấu hình JWT để validate token trên request.

**appsettings.json** (mẫu):

```json
"Jwt": {
  "Key": "<YOUR_SECRET_KEY_>_use_user_secrets_or_env",
  "Issuer": "LmsMini",
  "Audience": "LmsMiniClient",
  "ExpiresInMinutes": "60"
}
```

**Program.cs** (mẫu):

```csharp
var key = Encoding.UTF8.GetBytes(configuration["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key is missing"));

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = true;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = configuration["Jwt:Issuer"],
        ValidAudience = configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero // optional: reduce default 5 minutes
    };

    // Event hooks - optional logging
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            // log
            return Task.CompletedTask;
        }
    };
});

app.UseAuthentication();
app.UseAuthorization();
```

> *Note:* Luôn dùng HTTPS trong production (RequireHttpsMetadata = true).

### 4.3 Đăng ký IEmailSender và RoleSeeder

```csharp
builder.Services.AddTransient<IEmailSender, ConsoleEmailSender>();
// hoặc SmtpEmailSender / SendGridEmailSender
```

Gọi seeder sau `var app = builder.Build();`:

```csharp
await RoleSeeder.SeedAsync(app.Services);
```

---

## 5. Mẫu code (AccountController) — snippets cho từng endpoint

> Mỗi đoạn code kèm mô tả ngắn. Phần này mở rộng code mẫu trước đó và bổ sung refresh token/logout.

### 5.1 Change password

**Code mẫu: Change Password**

Mẫu endpoint đổi mật khẩu cho user đã đăng nhập, sử dụng UserManager.ChangePasswordAsync.

```csharp
[HttpPost("change-password")]
[Authorize]
public async Task<IActionResult> ChangePassword(ChangePasswordRequest req)
{
    var user = await _userManager.GetUserAsync(User);
    if (user == null) return Unauthorized();

    var res = await _userManager.ChangePasswordAsync(user, req.CurrentPassword, req.NewPassword);
    if (!res.Succeeded)
    {
        return BadRequest(res.Errors);
    }

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

    var token = await _user_manager.GeneratePasswordResetTokenAsync(user);
    var encoded = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));
    var url = $"{_config["App:BaseUrl"]}/reset-password?email={Uri.EscapeDataString(user.Email)}&token={encoded}";

    await _emailSender.SendEmailAsync(user.Email, "Reset password", $"Click: {url}");
    return Ok();
}
```

**Luồng Forgot/Reset Password**

Minh họa các bước từ khi người dùng yêu cầu quên mật khẩu đến khi đặt lại mật khẩu thành công.

```mermaid
sequenceDiagram
  autonumber
  participant U as "User"
  participant API_Forgot as "API (Forgot)"
  participant Email as "EmailSender"
  participant API_Reset as "API (Reset)"

  U->>API_Forgot: POST /api/account/forgot-password { email }
  API_Forgot-->>API_Forgot: GeneratePasswordResetToken
  API_Forgot->>Email: SendEmail(link with token)
  Email-->>U: Email with reset link
  Note over U: User clicks link in email
  U->>API_Reset: GET/POST /reset-password (token)
  API_Reset-->>API_Reset: Decode token, ResetPasswordAsync
  API_Reset-->>U: 200 OK or 400 Error
```

### 5.3 Reset password

**Code mẫu: Reset Password**

Mẫu endpoint nhận token (Base64Url), decode và gọi ResetPasswordAsync.

```csharp
[HttpPost("reset-password")]
public async Task<IActionResult> ResetPassword(ResetPasswordRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return BadRequest("Invalid request");

    var token = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(req.Token));
    var res = await _userManager.ResetPasswordAsync(user, token, req.NewPassword);
    if (!res.Succeeded)
    {
        return BadRequest(res.Errors);
    }

    return Ok();
}
```

**Luồng Forgot/Reset Password**

Minh họa các bước từ khi người dùng yêu cầu quên mật khẩu đến khi đặt lại mật khẩu thành công.

```mermaid
sequenceDiagram
  autonumber
  participant U as "User"
  participant API_Forgot as "API (Forgot)"
  participant Email as "EmailSender"
  participant API_Reset as "API (Reset)"

  U->>API_Forgot: POST /api/account/forgot-password { email }
  API_Forgot-->>API_Forgot: GeneratePasswordResetToken
  API_Forgot->>Email: SendEmail(link with token)
  Email-->>U: Email with reset link
  U->>API_Reset: POST /api/account/reset-password { email, token, newPassword }
  API_Reset-->>API_Reset: ResetPasswordAsync(token, newPassword)
  API_Reset-->>U: 200 OK or 400 Error
```

### 5.4 Confirm email

**Code mẫu: Confirm Email**

Endpoint xác nhận email bằng token do Identity sinh ra.

```csharp
[HttpPost("confirm-email")]
public async Task<IActionResult> ConfirmEmail(ConfirmEmailRequest req)
{
    var user = await _userManager.FindByIdAsync(req.UserId.ToString());
    if (user == null) return BadRequest();

    var res = await _user_manager.ConfirmEmailAsync(user, req.Token);
    if (!res.Succeeded)
    {
        return BadRequest(res.Errors);
    }

    return Ok();
}
```

### 5.5 Delete account (self)

**Code mẫu: Delete Account**

Endpoint cho phép user tự xoá tài khoản; có thể yêu cầu nhập lại mật khẩu.

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
    if (!res.Succeeded)
    {
        return BadRequest(res.Errors);
    }

    return Ok();
}
```

### 5.6 Get / Update profile

**Code mẫu: Get / Update Profile**

Endpoints lấy và cập nhật thông tin profile của user hiện tại.

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
    if (!res.Succeeded)
    {
        return BadRequest(res.Errors);
    }

    return Ok();
}
```

### 5.7 Role endpoints (Admin only)

**Code mẫu: Role CRUD (Admin only)**

Endpoints quản lý role, bảo vệ bằng role Admin.

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

**Code mẫu: Setup Admin**

Endpoint dùng lần đầu để tạo role Admin và user admin mặc định.

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
        await _user_manager.AddToRoleAsync(user, adminRole.Name);
        return Ok();
    }
    return BadRequest(res.Errors);
}
```

### 5.9 Login / Register — cập nhật để phát refresh token và gán role

**Code mẫu: Register (thêm gán role)**

```csharp
[HttpPost("register")]
public async Task<IActionResult> Register(RegisterRequest req)
{
    var user = new AspNetUser
    {
        UserName = req.Email,
        Email = req.Email
    };
    var result = await _userManager.CreateAsync(user, req.Password);
    if (!result.Succeeded)
    {
        return BadRequest(result.Errors);
    }

    // Gán role mặc định
    await _userManager.AddToRoleAsync(user, "Learner");

    return Ok();
}
```

**Code mẫu: Login (trả access token + refresh token)**

```csharp
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return Unauthorized();

    var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
    if (!pwOk) return Unauthorized();

    var roles = await _userManager.GetRolesAsync(user);
    var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
        new Claim(ClaimTypes.Name, user.UserName ?? string.Empty)
    };
    claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));

    var jwtKey = _config["Jwt:Key"];
    if (string.IsNullOrWhiteSpace(jwtKey)) return StatusCode(500, "JWT key is not configured.");

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    var issuer = _config["Jwt:Issuer"];
    var audience = _config["Jwt:Audience"];
    var expiresInMinutes = 60;
    if (int.TryParse(_config["Jwt:ExpiresInMinutes"], out var minutes)) expiresInMinutes = minutes;

    var tokenDescriptor = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(expiresInMinutes),
        signingCredentials: creds
    );

    var accessToken = new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);

    // tạo refresh token và lưu vào DB
    var refreshToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    var rt = new RefreshToken { Token = refreshToken, UserId = user.Id, Expires = DateTime.UtcNow.AddDays(7) };
    _db.RefreshTokens.Add(rt);
    await _db.SaveChangesAsync();

    return Ok(new { accessToken, refreshToken });
}
```

> Ghi chú: `_db` là instance của `LmsDbContext` có `DbSet<RefreshToken> RefreshTokens`.

### 5.10 Refresh token & Logout (code mẫu hoàn chỉnh)

**Code mẫu: Refresh Token & Logout**

```csharp
[HttpPost("refresh-token")]
public async Task<IActionResult> RefreshToken(RefreshTokenRequest req)
{
    var stored = await _db.RefreshTokens.SingleOrDefaultAsync(r => r.Token == req.RefreshToken);
    if (stored == null || stored.IsRevoked || stored.Expires < DateTime.UtcNow) return Unauthorized();

    var user = await _userManager.FindByIdAsync(stored.UserId.ToString());
    if (user == null) return Unauthorized();

    var roles = await _userManager.GetRolesAsync(user);
    var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
        new Claim(ClaimTypes.Name, user.UserName ?? string.Empty)
    };
    claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
    var token = new JwtSecurityToken(
        issuer: _config["Jwt:Issuer"],
        audience: _config["Jwt:Audience"],
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(int.Parse(_config["Jwt:ExpiresInMinutes"] ?? "60")),
        signingCredentials: creds
    );
    var accessToken = new JwtSecurityTokenHandler().WriteToken(token);

    stored.IsRevoked = true;
    var newRt = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    var rtEntity = new RefreshToken { Token = newRt, UserId = stored.UserId, Expires = DateTime.UtcNow.AddDays(7) };
    _db.RefreshTokens.Add(rtEntity);
    await _db.SaveChangesAsync();

    return Ok(new { accessToken, refreshToken = newRt });
}

[HttpPost("logout")]
[Authorize]
public async Task<IActionResult> Logout(LogoutRequest req)
{
    var stored = await _db.RefreshTokens.SingleOrDefaultAsync(r => r.Token == req.RefreshToken);
    if (stored != null)
    {
        stored.IsRevoked = true;
        await _db.SaveChangesAsync();
    }
    return Ok();
}
```

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

**Ví dụ RoleSeeder:** (giữ nguyên đoạn mẫu ở trên)

**Gọi seeder** sau `var app = builder.Build();`:

```csharp
await RoleSeeder.SeedAsync(app.Services);
```

**AdminSeeder (tuỳ chọn)**: tạo user admin mặc định; lưu credentials trong config/user-secrets.

**Quy trình seed role và admin**

Sơ đồ mô tả các bước tạo role mặc định và tài khoản admin.

```mermaid
flowchart TD
  classDef seed fill:#fff7e6,stroke:#ff8f00,stroke-width:1px;
  classDef action fill:#e8f4ff,stroke:#1565c0,stroke-width:1px;

  Start("Start")
  CheckRoles{Roles exist?}
  CreateRoles["Create Admin, Instructor, Learner"]
  CheckAdmin{Admin user exists?}
  CreateAdmin["Create admin user & assign Admin role"]
  End("End")

  Start --> CheckRoles
  CheckRoles -- no --> CreateRoles
  CreateRoles --> CheckAdmin
  CheckRoles -- yes --> CheckAdmin
  CheckAdmin -- no --> CreateAdmin
  CreateAdmin --> End
  CheckAdmin -- yes --> End

  class CreateRoles,CreateAdmin action
  class CheckRoles,CheckAdmin seed
```

---

## 8. Migration & cập nhật database schema

### 8.1 Tạo migration

- Cài đặt tools nếu chưa có: `dotnet tool install --global dotnet-ef`.
- Tạo migration cho project Infrastructure (nơi chứa DbContext):

```bash
dotnet ef migrations add InitIdentity -p LmsMini.Infrastructure -s LmsMini.Api
```

Trong lệnh trên: `-p` chỉ định project chứa DbContext; `-s` chỉ định startup project để load configuration.

### 8.2 Áp dụng migration (update DB)

```bash
dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api
```

### 8.3 Lưu ý với DB‑first

- Nếu database đã có bảng `AspNetUsers`, xem xét tạo migration baseline rỗng hoặc dùng approach DB‑first.
- Kiểm tra SQL script `dotnet ef migrations script -p ...` trước khi apply lên production.

---

## 9. Tests (xUnit) — ví dụ mẫu

Mô tả: ví dụ test integration cơ bản dùng `WebApplicationFactory<TEntryPoint>`.

### 9.1 Test Register + Login (xUnit)

```csharp
public class AccountControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    public AccountControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Register_Then_Login_Returns_Tokens()
    {
        var register = new { Email = "testuser@example.com", Password = "P@ssw0rd!" };
        var rRes = await _client.PostAsJsonAsync("/api/account/register", register);
        rRes.EnsureSuccessStatusCode();

        var login = new { Email = "testuser@example.com", Password = "P@ssw0rd!" };
        var lRes = await _client.PostAsJsonAsync("/api/account/login", login);
        lRes.EnsureSuccessStatusCode();

        var json = await lRes.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("token", out _));
    }
}
```

### 9.2 Test ForgotPassword (mock IEmailSender)

- Sử dụng DI overrides in WebApplicationFactory để inject mock `IEmailSender` and assert SendEmailAsync called.

```csharp
// Pseudocode: register mock and verify called
```

> Viết test đầy đủ cần cấu hình test host, in-memory DB hoặc test container DB.

---

## 10. Security & Best practices

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

## 11. Checklist thực hiện (chi tiết hành động)

1. Tạo DTOs [CREATE] trong `LmsMini.Api/Models` nếu chưa có.
2. Tạo `IEmailSender` + `ConsoleEmailSender` trong `LmsMini.Infrastructure/Services`; đăng ký DI.
3. Cập nhật `Program.cs`: AddIdentity, AddDefaultTokenProviders, AddAuthentication (JwtBearer), đăng ký IEmailSender.
4. Thêm `RoleSeeder` (và tuỳ chọn `AdminSeeder`) và gọi sau `builder.Build()`.
5. Mở `LmsMini.Api/Controllers/AccountController.cs`, inject thêm `RoleManager<IdentityRole<Guid>>` và `LmsDbContext` (nếu cần) và thêm endpoint code theo mẫu.
6. Thêm `RefreshToken` entity vào `LmsMini.Infrastructure` và migration.
7. Thêm `using Microsoft.AspNetCore.WebUtilities;` cho Base64Url encode/decode.
8. Chạy `dotnet ef migrations add` và `dotnet ef database update` để cập nhật schema.
9. Chạy `dotnet build` và `dotnet run`; kiểm tra bằng Postman/Swagger.
10. Viết integration tests (mock hoặc test server) cho các flow quan trọng.

**Quy trình triển khai tổng thể**

Minh họa các bước triển khai từ khâu chuẩn bị đến kiểm thử.

```mermaid
flowchart TD
  classDef step fill:#e8f4ff,stroke:#1565c0,stroke-width:1px;
  classDef action fill:#fff7e6,stroke:#ff8f00,stroke-width:1px;
  classDef done fill:#e6ffed,stroke:#2e7d32,stroke-width:1px;

  DTO["1. Tạo DTOs & Models"]:::step --> CFG["2. Cấu hình Program.cs (Identity, JWT, Email)"]:::action
  CFG --> MIG["3. Tạo migration & update DB"]:::action
  MIG --> CONT["4. Cập nhật AccountController (endpoints, refresh token)"]:::action
  CONT --> SEED["5. Chạy RoleSeeder & AdminSeeder"]:::action
  SEED --> TEST["6. Viết & chạy tests (xUnit)"]:::action
  TEST --> DONE["Hoàn thành"]:::done
```

---

Nếu bạn muốn, tôi có thể:

- **A**: Thực hiện tự động các bước: tạo DTOs [CREATE], tạo `IEmailSender` stub, thêm `RefreshToken` entity + migration skeleton, cập nhật `AccountController` với các endpoint mẫu và chạy build.
- **B**: Chỉ giữ tài liệu (xong) — bạn thực hiện các bước tiếp theo.

Chọn A hoặc B để tôi thực hiện tiếp.
