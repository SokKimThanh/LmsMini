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

## Cấu hình (ví dụ)
Trong `appsettings.json` hoặc cấu hình tương đương, đặt `JwtOptions`:
- `Key`: chuỗi bí mật (luôn lưu ở nơi an toàn, đủ dài, ngẫu nhiên).
- `Issuer`: nhà phát hành (ví dụ: `"LmsMini"`).
- `Audience`: đối tượng nhận (ví dụ: `"LmsMiniClient"`).
- `ExpiresInMinutes`: thời lượng hiệu lực token.

Ví dụ (tóm tắt):
- Key nên được lưu trong biến môi trường hoặc Secret Manager, không commit vào kho mã.

---

## Ví dụ sử dụng nhanh
- Đăng ký DI:
  - `services.Configure<JwtOptions>(configuration.GetSection("Jwt"));`
  - `services.AddSingleton<IJwtService, JwtService>();`
- Tạo token:
  - `var token = jwtService.CreateToken(user, roles);`
- Xác thực token (server): `jwtService.ValidateToken(token)` trả về `ClaimsPrincipal` hoặc `null`.

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

Tài liệu ngắn này nhằm giúp nắm nhanh cách `JwtService` hoạt động trong `LmsMini`. Nếu cần, có thể mở rộng bằng ví dụ cụ thể với mã gọi thực tế hoặc test unit mẫu.