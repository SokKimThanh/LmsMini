# Quản lý Tài khoản (Dành cho Học sinh lớp 5)

> 📜 Bản quyền © [2025] [Sok Kim Thanh] – Tài liệu này do [Sok Kim Thanh] biên soạn. Mọi quyền được bảo lưu. Không được sao chép hoặc sử dụng cho mục đích thương mại nếu không được phép.

🎯 Mục tiêu: Giúp bạn hiểu cách một ứng dụng web quản lý tài khoản. Chúng ta biến mọi thứ phức tạp thành những "nhiệm vụ" vui như trò chơi.

---

## Giới thiệu ngắn (dành cho bạn)

- Bạn sẽ học cách: đăng ký, đăng nhập, đổi mật khẩu, quên mật khẩu, xác nhận email, quản lý hồ sơ, vai trò (role), dùng vé (token) để vào phòng, và đăng xuất.
- Mỗi phần là một "nhiệm vụ" (task). Bạn làm xong sẽ thấy "Bạn đã làm được gì".

📚 Gợi ý: đọc từng phần, xem sơ đồ, làm theo các bước. Nếu bạn không hiểu từ nào, xem phần "Từ mới".

---

## Từ mới (giải thích dễ hiểu)

- **Identity**: giống như sổ danh sách tên và mật khẩu của mọi người. (Ai là ai?)
- **Endpoint**: là địa chỉ trên internet mà bạn gửi yêu cầu (ví dụ: /login). Giống như cửa vào nhà.
- **Token (🎟️)**: tấm vé để vào phòng. Nếu bạn có vé, bạn được phép làm một số việc.
- **JWT**: là một loại vé (token) thông minh, có chữ ký để không bị giả.

---

## Sơ đồ minh họa (dễ hiểu)

Sơ đồ này cho thấy các chức năng và ai có thể dùng chúng.

```mermaid
flowchart LR
  classDef public fill:#d7f0ff,stroke:#2b8bd4,stroke-width:1px;
  classDef auth fill:#fff6d0,stroke:#e5b800,stroke-width:1px;
  classDef admin fill:#ffe6e6,stroke:#e03b3b,stroke-width:1px;

  subgraph Public["Ai cũng dùng (Xanh dương)"]
    pub_register["👤 Đăng ký\n/register"]:::public
    pub_login["🔐 Đăng nhập\n/login"]:::public
    pub_forgot["📧 Quên mật khẩu\n/forgot"]:::public
    pub_reset["🔑 Đặt lại mật khẩu\n/reset"]:::public
    pub_confirm["📩 Xác nhận email\n/confirm-email"]:::public
  end

  subgraph Authorized["Cần đăng nhập (Vàng)"]
    auth_change["🔒 Đổi mật khẩu\n/change-password"]:::auth
    auth_profile["👤 Hồ sơ của bạn\n/me"]:::auth
    auth_logout["🚪 Đăng xuất\n/logout"]:::auth
    auth_refresh["🎟️ Refresh token\n/refresh-token"]:::auth
  end

  subgraph AdminOnly["Chỉ Admin (Đỏ)"]
    admin_roles["🛡️ Quản lý vai trò\n/roles"]:::admin
    admin_setup["⚙️ Tạo Admin ban đầu\n/setup-admin"]:::admin
  end

  pub_register --> pub_login
  pub_forgot --> pub_reset
  pub_login --> auth_profile
  auth_profile --> auth_change
  auth_profile --> auth_logout
  auth_refresh --> auth_profile
  admin_setup --> admin_roles

  class pub_register,pub_login,pub_forgot,pub_reset,pub_confirm public;
  class auth_change,auth_profile,auth_logout,auth_refresh auth;
  class admin_roles,admin_setup admin;
```

> 📜 Bản quyền © [2025] [Sok Kim Thanh] – Sơ đồ này do [Sok Kim Thanh] biên soạn. Không sao chép hoặc sử dụng cho mục đích thương mại nếu không được phép.

---

## Nhiệm vụ 1: Đăng ký (Create Account) 👤

Mục tiêu: tạo một tài khoản mới, giống như làm thẻ thành viên câu lạc bộ.

Bước 1: Nhập email và mật khẩu.  
Bước 2: Ứng dụng lưu tên và mật khẩu.  
Bước 3: Bạn đã có tài khoản, có thể đăng nhập.

> 🔎 Giải thích đơn giản: Đăng ký giống như viết tên vào sổ. Khi cần, sổ sẽ kiểm tra tên và mật khẩu.

> ⚠️ Lưu ý: mật khẩu giống chìa khóa, không cho ai mượn.

Code mẫu (chỉ để tham khảo):

```csharp
// Code này tạo một tài khoản mới trong máy chủ
[HttpPost("register")]
public async Task<IActionResult> Register(RegisterRequest req)
{
    // Tạo người dùng mới với email và mật khẩu
    var user = new AspNetUser { UserName = req.Email, Email = req.Email };
    var result = await _userManager.CreateAsync(user, req.Password);
    if (!result.Succeeded)
    {
        // Nếu có lỗi, thông báo
        return BadRequest(result.Errors);
    }
    return Ok(); // Thành công
}
```

Bạn đã làm được gì

- ✅ Biết đăng ký giống như ghi tên vào sổ.
- ✅ Hiểu rằng mật khẩu là chìa khóa riêng.

---

## Nhiệm vụ 2: Đăng nhập (Log in) 🔐

Mục tiêu: vào được bên trong ứng dụng giống như mở cửa bằng chìa khóa.

Bước 1: Nhập email và mật khẩu.  
Bước 2: Ứng dụng kiểm tra sổ xem có tên đó và mật khẩu đúng không.  
Bước 3: Nếu đúng, ứng dụng cho bạn một "vé" (token) để đi tiếp.

Ví dụ: token giống như vé vào rạp. Có vé mới được vào.

Code mẫu (làm gì):

```csharp
// Code này kiểm tra email và mật khẩu; nếu đúng thì trả về token (vé)
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return Unauthorized();

    var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
    if (!pwOk) return Unauthorized();

    // Tạo token (vé) và trả về
    var token = "<a JWT token string>"; // Trong thực tế, máy chủ sẽ tạo token an toàn
    return Ok(new { token });
}
```

Bạn đã làm được gì

- ✅ Biết đăng nhập giống như dùng chìa khóa.
- ✅ Hiểu token là vé vào cửa.

---

## Nhiệm vụ 3: Đổi mật khẩu 🔑

Mục tiêu: thay chìa khóa cũ bằng chìa khóa mới.

Bước 1: Bạn cần đăng nhập.  
Bước 2: Nhập mật khẩu cũ và mật khẩu mới.  
Bước 3: Ứng dụng kiểm tra mật khẩu cũ, nếu đúng, thay mật khẩu.

Code mẫu (mục đích):

```csharp
// Code này đổi mật khẩu của người đang đăng nhập
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

Bạn đã làm được gì

- ✅ Biết cách đổi mật khẩu an toàn.

---

## Nhiệm vụ 4: Quên mật khẩu & Đặt lại 📧🔑

Mục tiêu: nếu bạn quên chìa khóa, bạn có thể xin vé mới qua email.

Bước 1: Nhấn "Quên mật khẩu" và nhập email.  
Bước 2: Máy chủ gửi email có liên kết chứa token (tấm vé tạm).  
Bước 3: Bạn nhấn link, nhập mật khẩu mới.

So sánh vui: nếu mất vé, bạn xin vé tạm qua email rồi đổi vé mới.

Code mẫu (làm gì):

```csharp
// Gửi email có link để đặt lại mật khẩu
[HttpPost("forgot-password")]
public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return Ok(); // Không nói là email có hay không

    var token = await _userManager.GeneratePasswordResetTokenAsync(user);
    // Gửi token qua email (ví dụ: https://site/reset?token=...)
    await _emailSender.SendEmailAsync(user.Email, "Reset password", "Link đặt lại mật khẩu");
    return Ok();
}
```

Bạn đã làm được gì

- ✅ Hiểu cách xin và dùng liên kết để đặt lại mật khẩu.

---

## Nhiệm vụ 5: Xác nhận email 📩

Mục tiêu: chứng minh email là của bạn (giống như đóng dấu xác nhận).

Bước 1: Sau khi đăng ký, bạn nhận email chứa link xác nhận.  
Bước 2: Nhấn link để xác nhận.  
Bước 3: Ứng dụng ghi lại là email đã được xác thực.

Code mẫu (làm gì):

```csharp
// Xác nhận email của người dùng bằng token
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

Bạn đã làm được gì

- ✅ Hiểu vì sao phải xác nhận email.

---

## Nhiệm vụ 6: Hồ sơ của bạn (Profile) 👤

Mục tiêu: xem và sửa thông tin của bạn như tên hiển thị.

Bước 1: Đăng nhập.  
Bước 2: Vào "Hồ sơ" để xem thông tin.  
Bước 3: Thay đổi tên hiển thị rồi lưu.

Code mẫu (làm gì):

```csharp
// Lấy thông tin người dùng đang đăng nhập
[HttpGet("me")]
[Authorize]
public async Task<IActionResult> Me()
{
    var user = await _userManager.GetUserAsync(User);
    var roles = await _userManager.GetRolesAsync(user);
    return Ok(new { user.Id, user.Email, user.UserName, Roles = roles });
}

// Cập nhật tên hiển thị
[HttpPut("me")]
[Authorize]
public async Task<IActionResult> UpdateProfile(UpdateProfileRequest req)
{
    var user = await _userManager.GetUserAsync(User);
    if (!string.IsNullOrWhiteSpace(req.UserName)) user.UserName = req.UserName;
    var res = await _userManager.UpdateAsync(user);
    if (!res.Succeeded) return BadRequest(res.Errors);
    return Ok();
}
```

Bạn đã làm được gì

- ✅ Biết cách xem và cập nhật hồ sơ cá nhân.

---

## Nhiệm vụ 7: Quản lý vai trò (Role) 🛡️

Mục tiêu: hiểu có người bình thường và người quản trị (Admin).

- **Vai trò** là nhãn gắn vào tài khoản: **Admin** (người quản lý) hoặc **Learner** (học sinh).
- Chỉ **Admin** mới được thay đổi vai trò hoặc tạo vai trò mới.

Code mẫu (làm gì):

```csharp
// Lấy danh sách vai trò (Admin only)
[HttpGet("roles")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> GetRoles() { ... }

// Tạo vai trò mới (Admin only)
[HttpPost("roles")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> CreateRole(RoleRequest req) { ... }
```

Bạn đã làm được gì

- ✅ Hiểu vai trò là gì và ai có quyền làm gì.

---

## Nhiệm vụ 8: Refresh token (Gia hạn vé) 🎟️

Mục tiêu: khi vé (token) hết hạn, bạn dùng "refresh token" để xin vé mới mà không cần đăng nhập lại.

So sánh: vé xem phim hết hạn, bạn đưa vé phụ để lấy vé mới.

Code ý tưởng (đơn giản):

```csharp
// Đổi refresh token lấy access token mới
[HttpPost("refresh-token")]
public async Task<IActionResult> RefreshToken(RefreshTokenRequest req)
{
    // Kiểm tra refresh token trong cơ sở dữ liệu
    // Nếu hợp lệ, tạo access token mới và trả về
    return Ok(new { accessToken = "<new token>", refreshToken = "<new refresh>" });
}
```

Bạn đã làm được gì

- ✅ Biết refresh token giúp không phải đăng nhập lại nhiều lần.

---

## Nhiệm vụ 9: Đăng xuất (Logout) 🚪

Mục tiêu: thu hồi vé (token) khi bạn muốn ra về.

Bước 1: Nhấn "Logout".  
Bước 2: Ứng dụng đánh dấu vé là không còn hiệu lực.  
Bước 3: Bạn phải đăng nhập lại để lấy vé mới.

Code mẫu (làm gì):

```csharp
// Hủy refresh token khi logout
[HttpPost("logout")]
[Authorize]
public async Task<IActionResult> Logout(LogoutRequest req)
{
    // Tìm refresh token và đánh dấu là bị thu hồi
    return Ok();
}
```

Bạn đã làm được gì

- ✅ Hiểu vì sao cần logout.

---

## Nhiệm vụ 10: Thiết lập Admin ban đầu (Setup Admin) ⚙️

Mục tiêu: tạo người quản trị đầu tiên cho hệ thống.

Bước 1: Chạy chức năng tạo Admin (chỉ dùng 1 lần).  
Bước 2: Tạo tài khoản, gán vai trò **Admin**.  
Bước 3: Sau đó người này có thể quản lý vai trò và người dùng khác.

Code mẫu (làm gì):

```csharp
// Tạo tài khoản admin khi mới cài đặt (dùng 1 lần)
[HttpPost("setup-admin")]
public async Task<IActionResult> SetupAdmin(SetupAdminRequest req) { ... }
```

Bạn đã làm được gì

- ✅ Hiểu vai trò của admin và cách thiết lập ban đầu.

---

## Muốn làm tiếp? 🛠️

- Bạn có thể thử: tạo một trang HTML đơn giản với form đăng ký và đăng nhập.  
- Dùng Postman (hoặc trang web) gửi yêu cầu đến các địa chỉ /register, /login để thử.

---

## Ghi chú an toàn cho phụ huynh/giáo viên

- Tài liệu này là để học và thử nghiệm. Không dùng các mật khẩu thật khi thử.  
- Luôn bảo vệ thông tin cá nhân của học sinh.

---

## Giấy phép & Bản quyền

> 📜 Bản quyền © [2025] [Sok Kim Thanh] – Tài liệu này do [Sok Kim Thanh] biên soạn. Mọi quyền được bảo lưu. Không được sao chép hoặc sử dụng cho mục đích thương mại nếu không được phép.

Giấy phép: CC BY-NC-SA 4.0 (Chi tiết: https://creativecommons.org/licenses/by-nc-sa/4.0/)

---

Chúc bạn học vui! 🎉
