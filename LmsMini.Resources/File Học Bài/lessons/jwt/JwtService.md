# Bài học: `JwtService` — Tạo và xác thực JWT trong LmsMini

## Mục tiêu
Tài liệu này giải thích chức năng của `JwtService` trong dự án `LmsMini`. Nội dung trình bày bằng tiếng Việt, bao gồm:
- Mô tả ngắn gọn class và trách nhiệm.
- Giải thích chi tiết cách `CreateToken` hoạt động (các bước và claim).
- Mô tả `ValidateToken`.
- Cấu hình `JwtOptions`, lưu ý bảo mật và ví dụ sử dụng ngắn.

---

## Tổng quan
`JwtService` chịu trách nhiệm tạo và xác thực JSON Web Tokens (JWT) dùng HMAC-SHA256. Service lấy cấu hình từ `JwtOptions` (issuer, audience, key, expires) để:
- Tạo token có các claim cơ bản (id, email, username) và claim vai trò (`ClaimTypes.Role`).
- Ký token bằng `SymmetricSecurityKey` dựa trên `JwtOptions.Key`.
- Xác thực token bằng `TokenValidationParameters` (kiểm tra issuer, audience, signature, thời hạn).

---

## Cấu trúc chính

### 1. Constructor
- Nạp `JwtOptions` từ DI (`IOptions<JwtOptions>`).
- Chuyển `Key` thành bytes (`Encoding.UTF8.GetBytes(_opts.Key)`) và tạo `IssuerSigningKey`.
- Thiết lập `TokenValidationParameters`:
  - `ValidateIssuer = true`, `ValidateAudience = true`, `ValidateLifetime = true`, `ValidateIssuerSigningKey = true`.
  - `ClockSkew = TimeSpan.Zero` (không cho phép dung sai mặc định 5 phút).

Lưu ý: nếu `JwtOptions.Key` không có giá trị, constructor sẽ ném ngoại lệ — đảm bảo cấu hình hợp lệ trước khi chạy.

### 2. `CreateToken(AspNetUser user, IEnumerable<string> roles)`
Mục đích: tạo chuỗi JWT đã ký chứa thông tin người dùng và vai trò.

Các bước thực hiện (giữ nguyên logic hiện tại):
1. Tạo danh sách claim cơ bản:
   - `sub` = `user.Id.ToString()` (claim `JwtRegisteredClaimNames.Sub`)
   - `email` = `user.Email` hoặc chuỗi rỗng (claim `JwtRegisteredClaimNames.Email`)
   - `name` = `user.UserName` hoặc chuỗi rỗng (claim `ClaimTypes.Name`)
2. Chuyển các role (tên role) thành claim `ClaimTypes.Role`:
   - Mỗi role -> `new Claim(ClaimTypes.Role, role)`
   - Nối các role claims vào danh sách claim hiện có (sử dụng `claims.Concat(...)`)
3. Tạo `SymmetricSecurityKey` từ `_opts.Key`:
   - `new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_opts.Key))`
4. Tạo `SigningCredentials` với thuật toán HMAC SHA256:
   - `new SigningCredentials(key, SecurityAlgorithms.HmacSha256)`
5. Tạo `JwtSecurityToken` với:
   - `issuer` = `_opts.Issuer`
   - `audience` = `_opts.Audience`
   - `claims` = danh sách claims (bao gồm role claims)
   - `expires` = `DateTime.UtcNow.AddMinutes(_opts.ExpiresInMinutes)`
   - `signingCredentials` = creds
6. Trả về chuỗi token đã ký:
   - `new JwtSecurityTokenHandler().WriteToken(token)`

Ghi chú: logic tạo token giữ nguyên để tương thích với cấu hình JWT của ứng dụng.

### 3. `ValidateToken(string token)`
Mục đích: xác thực token và trả về `ClaimsPrincipal` nếu hợp lệ, ngược lại trả về `null`.

Cách hoạt động:
- Dùng `JwtSecurityTokenHandler.ValidateToken(token, _validationParams, out validatedToken)` để kiểm tra chữ ký, issuer, audience và thời hạn.
- Kiểm tra thêm rằng `validatedToken` là `JwtSecurityToken` và header `Alg` là `HmacSha256` (tránh tấn công thay đổi thuật toán).
- Nếu mọi kiểm tra hợp lệ -> trả về `ClaimsPrincipal`.
- Bất kỳ lỗi nào trong quá trình validate -> trả về `null`.

---

## Cấu hình (chi tiết — ví dụ và bước thực hiện)
Phần này hướng dẫn chi tiết cách cấu hình JWT trong ứng dụng để `JwtService` hoạt động đúng: gồm cách đặt giá trị trong `appsettings.json` (chỉ để tham khảo), cách lưu an toàn với *user-secrets* hoặc *environment variables*, và cách cập nhật `Program.cs` để đăng ký authentication và `JwtService`.

LƯU Ý: KHÔNG commit khóa bí mật thật vào mã nguồn.

### 1) appsettings.json (ví dụ chỉ để tham khảo)

```json
"Jwt": {
  "Key": "<DO_NOT_COMMIT_REAL_KEY>",
  "Issuer": "LmsMini",
  "Audience": "LmsMiniClient",
  "ExpiresInMinutes": 60
}
```

### 2) Lưu secret an toàn
- Development: dùng dotnet user-secrets
  - Khởi tạo (chạy trong thư mục chứa `.csproj` của API):

    dotnet user-secrets init

  - Thiết lập giá trị (ví dụ PowerShell):

    dotnet user-secrets set "Jwt:Key" "your_development_secret_here"

- Production: dùng biến môi trường (hoặc secret manager)
  - Mapping: `Jwt:Key` => `JWT__Key`, v.v.
  - Ví dụ (bash):

    export JWT__Key="your_production_secret_here"

### 3) Kiểm tra fail-fast khi ứng dụng khởi động

```csharp
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException("Jwt:Key is not configured. Set it using user-secrets or environment variables.");
}
```

### 4) Program.cs — đăng ký JwtOptions, Authentication và JwtService

```csharp
// 1. Bind JwtOptions (trong builder.Services)
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

// 2. Fail-fast check (tùy chọn nhưng khuyến nghị)
var key = Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key is missing"));

// 3. Add Authentication + JwtBearer
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = true; // production: true
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero
    };
});

// 4. Register JwtService implementation and IJwtService contract
builder.Services.AddSingleton<IJwtService, JwtService>();
```

### 5) Môi trường container / production
- Đặt biến môi trường `JWT__Key` trong secret manager hoặc pipeline CI/CD.
- Sử dụng HTTPS và cấu hình reverse-proxy phù hợp.

---

## Ví dụ sử dụng nhanh
- Đăng ký DI:
  - `services.Configure<JwtOptions>(configuration.GetSection("Jwt"));`
  - `services.AddSingleton<IJwtService, JwtService>();`
- Tạo token:
  - `var token = jwtService.CreateToken(user, roles);`
- Xác thực token (server): `jwtservice.ValidateToken(token)` trả về `ClaimsPrincipal` hoặc `null`.

---

## Ví dụ: Đoạn mã `Program.cs` (mẫu)
Dưới đây là đoạn mã mẫu `Program.cs` chứa các phần chính: bind `JwtOptions`, fail-fast kiểm tra `Jwt:Key`, đăng ký authentication với JwtBearer và đăng ký `JwtService`.

```csharp
using LmsMini.Application.Auth;
using LmsMini.Application.Interfaces;
using LmsMini.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Bind JwtOptions từ cấu hình (appsettings / user-secrets / env vars)
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

// Fail-fast: đảm bảo Jwt:Key đã được cấu hình
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
    throw new InvalidOperationException("Jwt:Key is not configured. Set it using user-secrets or environment variables.");

var keyBytes = Encoding.UTF8.GetBytes(jwtKey);

// Đăng ký Authentication với JWT Bearer
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = true; // production: true
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ClockSkew = TimeSpan.Zero
    };

    // Optional: event hooks for logging
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = ctx =>
        {
            // optional logging
            return Task.CompletedTask;
        }
    };
});

// Đăng ký JwtService
builder.Services.AddSingleton<IJwtService, JwtService>();

// Các dịch vụ khác (Identity, DbContext, Controllers...) nên được đăng ký ở đây
builder.Services.AddControllers();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();
```

---

## Lưu ý bảo mật & vận hành
- Bảo vệ `JwtOptions.Key`: dùng Secret Manager hoặc biến môi trường trong production.
- Đảm bảo `Key` đủ dài và ngẫu nhiên (không dùng chuỗi ngắn).
- `ClockSkew = TimeSpan.Zero` giảm dung sai thời gian; cân nhắc nếu có client/server lệch giờ.
- Nếu cần thu hồi token, bổ sung `jti` claim và cơ chế blacklist/refresh token.
- Tránh đưa dữ liệu nhạy cảm vào claim.

---

## Kiểm thử
- Kiểm thử `CreateToken`:
  - Tạo token cho người dùng mẫu, giải mã (parse) token để kiểm tra các claim.
- Kiểm thử `ValidateToken`:
  - Test token hợp lệ, token hết hạn, token với `alg` khác, token bị sửa đổi.
- Unit test có thể dùng `JwtSecurityTokenHandler` để giải mã token và so sánh claims mong đợi.

---

## Có cần học không? Những điểm chính cần nhớ
- Mục đích chính: `JwtService` tạo token (`CreateToken`) và xác thực token (`ValidateToken`).
- Claims cơ bản: `sub` (user id), `email`, `name` và các `ClaimTypes.Role` cho vai trò.
- Cách ký token: dùng `SymmetricSecurityKey` từ `JwtOptions.Key` và `SigningCredentials` với `HmacSha256`.
- Thời hạn token: cấu hình qua `JwtOptions.ExpiresInMinutes`.
- Validate token: kiểm tra issuer, audience, lifetime và signature.

---

## Sơ đồ minh họa (Mermaid sequence)

### CreateToken (sequence)
CreateToken: "Khi client đăng nhập, controller kiểm chứng, gọi JwtService tạo token. JwtService lấy cấu hình issuer, audience, key và thời hạn, dựng claim chủ thể sub cùng email và tên, biến danh sách roles thành các role claim, tạo khoá đối xứng từ key và credentials HMAC SHA256, ghép tất cả vào JwtSecurityToken, ký và trả chuỗi token đã ký về cho controller — controller trả token cho client." 

```mermaid
sequenceDiagram
    participant Client
    participant AuthController
    participant JwtService
    participant JwtOptions

    Client->>AuthController: POST /login (credentials)
    AuthController->>AuthController: Validate credentials
    AuthController->>JwtService: CreateToken(user, roles)
    JwtService->>JwtOptions: Read Issuer/Audience/Key/Expires
    JwtService->>JwtService: Build claims (sub, email, name) and role claims
    JwtService->>JwtService: Create symmetric key and signing credentials
    JwtService->>JwtService: Create JwtSecurityToken and WriteToken
    JwtService-->>AuthController: return signed token
    AuthController-->>Client: 200 OK { token }
```

### ValidateToken (sequence)
ValidateToken: "Client gửi request kèm Bearer token, API gọi JwtService xác thực; handler kiểm tra chữ ký, issuer, audience và thời hạn, thêm bước kiểm tra header alg là HmacSha256; nếu mọi thứ hợp lệ trả về ClaimsPrincipal để API sử dụng, còn không thì trả null và API trả 401." 

```mermaid
sequenceDiagram
    participant Client
    participant Api
    participant JwtService

    Client->>Api: Request with Authorization: Bearer <token>
    Api->>JwtService: ValidateToken(token)
    JwtService->>JwtService: Validate signature, issuer, audience, lifetime
    JwtService->>JwtService: Check header alg == HmacSha256
    alt token valid
        JwtService-->>Api: ClaimsPrincipal
        Api-->>Client: 200 OK (resource)
    else token invalid
        JwtService-->>Api: null
        Api-->>Client: 401 Unauthorized
    end
```

---

## Danh sách file liên quan
- `LmsMini.Infrastructure/Services/JwtService.cs`
- `LmsMini.Application/Auth/JwtOptions.cs`
- `LmsMini.Application/Interfaces/IJwtService.cs`
- `LmsMini.Domain/Entities/Identity/AspNetUser.cs`
- `LmsMini.Infrastructure/Persistence/LmsDbContext.cs`
- `LmsMini.Resources/File Học Bài/lessons/jwt/JwtService.md`

---
Tài liệu ngắn này nhằm giúp nắm nhanh cách `JwtService` hoạt động trong `LmsMini`. Nếu cần checklist thực hiện hoặc chèn code trực tiếp vào `Program.cs`, tôi có thể sửa file đó theo yêu cầu.

---

## Mã nguồn (thực tế): `CreateToken` và `ValidateToken`
Dưới đây là triển khai thực tế của hai phương thức `CreateToken` và `ValidateToken` lấy từ `LmsMini.Infrastructure/Services/JwtService.cs`. Bạn có thể sao chép trực tiếp vào project nếu cần tham khảo.

```csharp
public string CreateToken(AspNetUser user, IEnumerable<string> roles)
{
    // Tạo danh sách các claim cơ bản cho token:
    // - sub: id của người dùng
    // - email: email của người dùng (nếu có)
    // - name: username (nếu có)
    var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
        new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
    };

    // Chuyển các role thành claim kiểu ClaimTypes.Role và nối vào danh sách claim
    // (claims.Concat(...) được truyền trực tiếp vào JwtSecurityToken constructor).
    // Tạo khoá ký (symmetric key) từ _opts.Key (chuỗi ký).
    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_opts.Key));

    // Tạo SigningCredentials sử dụng HMAC SHA256
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    // Tạo token với issuer, audience, claims (bao gồm role claims), thời hạn và signing credentials
    var token = new JwtSecurityToken(
        issuer: _opts.Issuer,
        audience: _opts.Audience,
        claims: claims.Concat(roles.Select(role => new Claim(ClaimTypes.Role, role))),
        expires: DateTime.UtcNow.AddMinutes(_opts.ExpiresInMinutes),
        signingCredentials: creds
    );

    // Chuyển JwtSecurityToken thành chuỗi JWT đã ký và trả về
    return new JwtSecurityTokenHandler().WriteToken(token);
}

public ClaimsPrincipal? ValidateToken(string token)
{
    try
    {
        var handler = new JwtSecurityTokenHandler();
        var principal = handler.ValidateToken(token, _validationParams, out var validatedToken);
        // Kiểm tra xem token đã được ký đúng thuật toán chưa
        if (validatedToken is not JwtSecurityToken jwtToken ||
            !jwtToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
        {
            return null; // Token không hợp lệ
        }
        return principal; // Trả về ClaimsPrincipal nếu token hợp lệ
    }
    catch
    {
        return null; // Trả về null nếu có lỗi trong quá trình xác thực (token không hợp lệ hoặc hết hạn)
    }
}
```

---

## Ví dụ: sử dụng `IJwtService` trong `AccountController` (mã mẫu)
Dưới đây là ví dụ mã `AccountController` (chỉ các endpoint liên quan) minh họa cách sử dụng `IJwtService.CreateToken(...)` để phát access token và cách quản lý refresh token (lưu, thu hồi, rotate). Bạn có thể copy-paste đoạn này vào controller thực tế và chỉnh sửa theo schema `RefreshToken` trong dự án.

```csharp
// AccountController (chỉ trích xuất các phương thức chính liên quan tới JWT/refresh)
[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly UserManager<AspNetUser> _userManager;
    private readonly IJwtService _jwtService;
    private readonly LmsDbContext _dbContext;
    private readonly RoleManager<IdentityRole<Guid>> _roleManager;

    public AccountController(UserManager<AspNetUser> userManager,
                             IJwtService jwtService,
                             LmsDbContext dbContext,
                             RoleManager<IdentityRole<Guid>> roleManager)
    {
        _userManager = userManager;
        _jwtService = jwtService;
        _dbContext = dbContext;
        _roleManager = roleManager;
    }

    // Register (ví dụ gán role Learner nếu tồn tại)
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        var user = new AspNetUser { UserName = req.Email, Email = req.Email };
        var result = await _userManager.CreateAsync(user, req.Password);
        if (!result.Succeeded) return BadRequest(result.Errors);

        if (await _roleManager.RoleExistsAsync("Learner"))
        {
            await _userManager.AddToRoleAsync(user, "Learner");
        }

        return Ok();
    }

    // Login -> trả access token + refresh token (lưu trong DB)
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user == null) return Unauthorized();

        var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
        if (!pwOk) return Unauthorized();

        var roles = await _userManager.GetRolesAsync(user);
        var accessToken = _jwtService.CreateToken(user, roles);

        // Tạo refresh token mạnh và lưu vào DB
        var refreshToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var rtEntity = new RefreshToken
        {
            Token = refreshToken,
            UserId = user.Id,
            CreatedAt = DateTime.UtcNow,
            Expires = DateTime.UtcNow.AddDays(7),
            IsRevoked = false
        };
        _dbContext.Set<RefreshToken>().Add(rtEntity);
        await _dbContext.SaveChangesAsync();

        return Ok(new { accessToken, refreshToken });
    }

    // Refresh token: đổi refresh lấy access mới, revoke old và phát refresh mới (rotate)
    [HttpPost("refresh-token")]
    public async Task<IActionResult> RefreshToken(RefreshTokenRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.RefreshToken)) return BadRequest();

        var stored = await _dbContext.Set<RefreshToken>().SingleOrDefaultAsync(r => r.Token == req.RefreshToken);
        if (stored == null || stored.IsRevoked || stored.Expires < DateTime.UtcNow) return Unauthorized();

        var user = await _userManager.FindByIdAsync(stored.UserId.ToString());
        if (user == null) return Unauthorized();

        var roles = await _userManager.GetRolesAsync(user);
        var accessToken = _jwtService.CreateToken(user, roles);

        // Revoke old refresh token and issue new one
        stored.IsRevoked = true;
        var newRefresh = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var newRtEntity = new RefreshToken
        {
            Token = newRefresh,
            UserId = stored.UserId,
            CreatedAt = DateTime.UtcNow,
            Expires = DateTime.UtcNow.AddDays(7),
            IsRevoked = false
        };
        _dbContext.Set<RefreshToken>().Add(newRtEntity);
        await _dbContext.SaveChangesAsync();

        return Ok(new { accessToken, refreshToken = newRefresh });
    }

    // Logout: thu hồi refresh token
    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout(LogoutRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.RefreshToken)) return BadRequest();

        var stored = await _dbContext.Set<RefreshToken>().SingleOrDefaultAsync(r => r.Token == req.RefreshToken);
        if (stored != null)
        {
            stored.IsRevoked = true;
            await _dbContext.SaveChangesAsync();
        }

        return Ok();
    }
}
```

Ghi chú ngắn:
- Đảm bảo trong domain có entity `RefreshToken` và DbContext có DbSet tương ứng (hoặc dùng `_dbContext.Set<RefreshToken>()`).
- Ở production nên lưu refresh token hashed thay vì plaintext, và lưu thêm metadata (ip, userAgent) để hỗ trợ audit.
- DTOs `RefreshTokenRequest` / `LogoutRequest` đơn giản chỉ cần chứa `string RefreshToken`.

---