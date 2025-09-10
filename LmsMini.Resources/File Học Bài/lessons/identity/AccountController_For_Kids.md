# Qu?n l? T�i kho?n (D�nh cho H?c sinh l?p 5)

> ?? B?n quy?n � [2025] [Sok Kim Thanh] � T�i li?u n�y do [Sok Kim Thanh] bi�n so?n. M?i quy?n ��?c b?o l�u. Kh�ng ��?c sao ch�p ho?c s? d?ng cho m?c ��ch th��ng m?i n?u kh�ng ��?c ph�p.

?? M?c ti�u: Gi�p b?n hi?u c�ch m?t ?ng d?ng web qu?n l? t�i kho?n. Ch�ng ta bi?n m?i th? ph?c t?p th�nh nh?ng "nhi?m v?" vui nh� tr? ch�i.

---

## Gi?i thi?u ng?n (d�nh cho b?n)

- B?n s? h?c c�ch: ��ng k?, ��ng nh?p, �?i m?t kh?u, qu�n m?t kh?u, x�c nh?n email, qu?n l? h? s�, vai tr? (role), d�ng v� (token) �? v�o ph?ng, v� ��ng xu?t.
- M?i ph?n l� m?t "nhi?m v?" (task). B?n l�m xong s? th?y "B?n �? l�m ��?c g?".

?? G?i ?: �?c t?ng ph?n, xem s� �?, l�m theo c�c b�?c. N?u b?n kh�ng hi?u t? n�o, xem ph?n "T? m?i".

---

## T? m?i (gi?i th�ch d? hi?u)

- **Identity**: gi?ng nh� s? danh s�ch t�n v� m?t kh?u c?a m?i ng�?i. (Ai l� ai?)
- **Endpoint**: l� �?a ch? tr�n internet m� b?n g?i y�u c?u (v� d?: /login). Gi?ng nh� c?a v�o nh�.
- **Token (???)**: t?m v� �? v�o ph?ng. N?u b?n c� v�, b?n ��?c ph�p l�m m?t s? vi?c.
- **JWT**: l� m?t lo?i v� (token) th�ng minh, c� ch? k? �? kh�ng b? gi?.

---

## S� �? minh h?a (d? hi?u)

S� �? n�y cho th?y c�c ch?c n�ng v� ai c� th? d�ng ch�ng.

```mermaid
flowchart LR
  classDef public fill:#d7f0ff,stroke:#2b8bd4,stroke-width:1px;
  classDef auth fill:#fff6d0,stroke:#e5b800,stroke-width:1px;
  classDef admin fill:#ffe6e6,stroke:#e03b3b,stroke-width:1px;

  subgraph Public["Ai c?ng d�ng (Xanh d��ng)"]
    pub_register["?? ��ng k?\n/register"]:::public
    pub_login["?? ��ng nh?p\n/login"]:::public
    pub_forgot["?? Qu�n m?t kh?u\n/forgot"]:::public
    pub_reset["?? �?t l?i m?t kh?u\n/reset"]:::public
    pub_confirm["?? X�c nh?n email\n/confirm-email"]:::public
  end

  subgraph Authorized["C?n ��ng nh?p (V�ng)"]
    auth_change["?? �?i m?t kh?u\n/change-password"]:::auth
    auth_profile["?? H? s� c?a b?n\n/me"]:::auth
    auth_logout["?? ��ng xu?t\n/logout"]:::auth
    auth_refresh["??? Refresh token\n/refresh-token"]:::auth
  end

  subgraph AdminOnly["Ch? Admin (�?)"]
    admin_roles["??? Qu?n l? vai tr?\n/roles"]:::admin
    admin_setup["?? T?o Admin ban �?u\n/setup-admin"]:::admin
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

> ?? B?n quy?n � [2025] [Sok Kim Thanh] � S� �? n�y do [Sok Kim Thanh] bi�n so?n. Kh�ng sao ch�p ho?c s? d?ng cho m?c ��ch th��ng m?i n?u kh�ng ��?c ph�p.

---

## Nhi?m v? 1: ��ng k? (Create Account) ??

M?c ti�u: t?o m?t t�i kho?n m?i, gi?ng nh� l�m th? th�nh vi�n c�u l?c b?.

B�?c 1: Nh?p email v� m?t kh?u.  
B�?c 2: ?ng d?ng l�u t�n v� m?t kh?u.  
B�?c 3: B?n �? c� t�i kho?n, c� th? ��ng nh?p.

> ?? Gi?i th�ch ��n gi?n: ��ng k? gi?ng nh� vi?t t�n v�o s?. Khi c?n, s? s? ki?m tra t�n v� m?t kh?u.

> ?? L�u ?: m?t kh?u gi?ng ch?a kh�a, kh�ng cho ai m�?n.

Code m?u (ch? �? tham kh?o):

```csharp
// Code n�y t?o m?t t�i kho?n m?i trong m�y ch?
[HttpPost("register")]
public async Task<IActionResult> Register(RegisterRequest req)
{
    // T?o ng�?i d�ng m?i v?i email v� m?t kh?u
    var user = new AspNetUser { UserName = req.Email, Email = req.Email };
    var result = await _userManager.CreateAsync(user, req.Password);
    if (!result.Succeeded)
    {
        // N?u c� l?i, th�ng b�o
        return BadRequest(result.Errors);
    }
    return Ok(); // Th�nh c�ng
}
```

B?n �? l�m ��?c g?

- ? Bi?t ��ng k? gi?ng nh� ghi t�n v�o s?.
- ? Hi?u r?ng m?t kh?u l� ch?a kh�a ri�ng.

---

## Nhi?m v? 2: ��ng nh?p (Log in) ??

M?c ti�u: v�o ��?c b�n trong ?ng d?ng gi?ng nh� m? c?a b?ng ch?a kh�a.

B�?c 1: Nh?p email v� m?t kh?u.  
B�?c 2: ?ng d?ng ki?m tra s? xem c� t�n �� v� m?t kh?u ��ng kh�ng.  
B�?c 3: N?u ��ng, ?ng d?ng cho b?n m?t "v�" (token) �? �i ti?p.

V� d?: token gi?ng nh� v� v�o r?p. C� v� m?i ��?c v�o.

Code m?u (l�m g?):

```csharp
// Code n�y ki?m tra email v� m?t kh?u; n?u ��ng th? tr? v? token (v�)
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return Unauthorized();

    var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
    if (!pwOk) return Unauthorized();

    // T?o token (v�) v� tr? v?
    var token = "<a JWT token string>"; // Trong th?c t?, m�y ch? s? t?o token an to�n
    return Ok(new { token });
}
```

B?n �? l�m ��?c g?

- ? Bi?t ��ng nh?p gi?ng nh� d�ng ch?a kh�a.
- ? Hi?u token l� v� v�o c?a.

---

## Nhi?m v? 3: �?i m?t kh?u ??

M?c ti�u: thay ch?a kh�a c? b?ng ch?a kh�a m?i.

B�?c 1: B?n c?n ��ng nh?p.  
B�?c 2: Nh?p m?t kh?u c? v� m?t kh?u m?i.  
B�?c 3: ?ng d?ng ki?m tra m?t kh?u c?, n?u ��ng, thay m?t kh?u.

Code m?u (m?c ��ch):

```csharp
// Code n�y �?i m?t kh?u c?a ng�?i �ang ��ng nh?p
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

B?n �? l�m ��?c g?

- ? Bi?t c�ch �?i m?t kh?u an to�n.

---

## Nhi?m v? 4: Qu�n m?t kh?u & �?t l?i ????

M?c ti�u: n?u b?n qu�n ch?a kh�a, b?n c� th? xin v� m?i qua email.

B�?c 1: Nh?n "Qu�n m?t kh?u" v� nh?p email.  
B�?c 2: M�y ch? g?i email c� li�n k?t ch?a token (t?m v� t?m).  
B�?c 3: B?n nh?n link, nh?p m?t kh?u m?i.

So s�nh vui: n?u m?t v�, b?n xin v� t?m qua email r?i �?i v� m?i.

Code m?u (l�m g?):

```csharp
// G?i email c� link �? �?t l?i m?t kh?u
[HttpPost("forgot-password")]
public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest req)
{
    var user = await _userManager.FindByEmailAsync(req.Email);
    if (user == null) return Ok(); // Kh�ng n�i l� email c� hay kh�ng

    var token = await _userManager.GeneratePasswordResetTokenAsync(user);
    // G?i token qua email (v� d?: https://site/reset?token=...)
    await _emailSender.SendEmailAsync(user.Email, "Reset password", "Link �?t l?i m?t kh?u");
    return Ok();
}
```

B?n �? l�m ��?c g?

- ? Hi?u c�ch xin v� d�ng li�n k?t �? �?t l?i m?t kh?u.

---

## Nhi?m v? 5: X�c nh?n email ??

M?c ti�u: ch?ng minh email l� c?a b?n (gi?ng nh� ��ng d?u x�c nh?n).

B�?c 1: Sau khi ��ng k?, b?n nh?n email ch?a link x�c nh?n.  
B�?c 2: Nh?n link �? x�c nh?n.  
B�?c 3: ?ng d?ng ghi l?i l� email �? ��?c x�c th?c.

Code m?u (l�m g?):

```csharp
// X�c nh?n email c?a ng�?i d�ng b?ng token
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

B?n �? l�m ��?c g?

- ? Hi?u v? sao ph?i x�c nh?n email.

---

## Nhi?m v? 6: H? s� c?a b?n (Profile) ??

M?c ti�u: xem v� s?a th�ng tin c?a b?n nh� t�n hi?n th?.

B�?c 1: ��ng nh?p.  
B�?c 2: V�o "H? s�" �? xem th�ng tin.  
B�?c 3: Thay �?i t�n hi?n th? r?i l�u.

Code m?u (l�m g?):

```csharp
// L?y th�ng tin ng�?i d�ng �ang ��ng nh?p
[HttpGet("me")]
[Authorize]
public async Task<IActionResult> Me()
{
    var user = await _userManager.GetUserAsync(User);
    var roles = await _userManager.GetRolesAsync(user);
    return Ok(new { user.Id, user.Email, user.UserName, Roles = roles });
}

// C?p nh?t t�n hi?n th?
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

B?n �? l�m ��?c g?

- ? Bi?t c�ch xem v� c?p nh?t h? s� c� nh�n.

---

## Nhi?m v? 7: Qu?n l? vai tr? (Role) ???

M?c ti�u: hi?u c� ng�?i b?nh th�?ng v� ng�?i qu?n tr? (Admin).

- **Vai tr?** l� nh?n g?n v�o t�i kho?n: **Admin** (ng�?i qu?n l?) ho?c **Learner** (h?c sinh).
- Ch? **Admin** m?i ��?c thay �?i vai tr? ho?c t?o vai tr? m?i.

Code m?u (l�m g?):

```csharp
// L?y danh s�ch vai tr? (Admin only)
[HttpGet("roles")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> GetRoles() { ... }

// T?o vai tr? m?i (Admin only)
[HttpPost("roles")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> CreateRole(RoleRequest req) { ... }
```

B?n �? l�m ��?c g?

- ? Hi?u vai tr? l� g? v� ai c� quy?n l�m g?.

---

## Nhi?m v? 8: Refresh token (Gia h?n v�) ???

M?c ti�u: khi v� (token) h?t h?n, b?n d�ng "refresh token" �? xin v� m?i m� kh�ng c?n ��ng nh?p l?i.

So s�nh: v� xem phim h?t h?n, b?n ��a v� ph? �? l?y v� m?i.

Code ? t�?ng (��n gi?n):

```csharp
// �?i refresh token l?y access token m?i
[HttpPost("refresh-token")]
public async Task<IActionResult> RefreshToken(RefreshTokenRequest req)
{
    // Ki?m tra refresh token trong c� s? d? li?u
    // N?u h?p l?, t?o access token m?i v� tr? v?
    return Ok(new { accessToken = "<new token>", refreshToken = "<new refresh>" });
}
```

B?n �? l�m ��?c g?

- ? Bi?t refresh token gi�p kh�ng ph?i ��ng nh?p l?i nhi?u l?n.

---

## Nhi?m v? 9: ��ng xu?t (Logout) ??

M?c ti�u: thu h?i v� (token) khi b?n mu?n ra v?.

B�?c 1: Nh?n "Logout".  
B�?c 2: ?ng d?ng ��nh d?u v� l� kh�ng c?n hi?u l?c.  
B�?c 3: B?n ph?i ��ng nh?p l?i �? l?y v� m?i.

Code m?u (l�m g?):

```csharp
// H?y refresh token khi logout
[HttpPost("logout")]
[Authorize]
public async Task<IActionResult> Logout(LogoutRequest req)
{
    // T?m refresh token v� ��nh d?u l� b? thu h?i
    return Ok();
}
```

B?n �? l�m ��?c g?

- ? Hi?u v? sao c?n logout.

---

## Nhi?m v? 10: Thi?t l?p Admin ban �?u (Setup Admin) ??

M?c ti�u: t?o ng�?i qu?n tr? �?u ti�n cho h? th?ng.

B�?c 1: Ch?y ch?c n�ng t?o Admin (ch? d�ng 1 l?n).  
B�?c 2: T?o t�i kho?n, g�n vai tr? **Admin**.  
B�?c 3: Sau �� ng�?i n�y c� th? qu?n l? vai tr? v� ng�?i d�ng kh�c.

Code m?u (l�m g?):

```csharp
// T?o t�i kho?n admin khi m?i c�i �?t (d�ng 1 l?n)
[HttpPost("setup-admin")]
public async Task<IActionResult> SetupAdmin(SetupAdminRequest req) { ... }
```

B?n �? l�m ��?c g?

- ? Hi?u vai tr? c?a admin v� c�ch thi?t l?p ban �?u.

---

## Mu?n l�m ti?p? ???

- B?n c� th? th?: t?o m?t trang HTML ��n gi?n v?i form ��ng k? v� ��ng nh?p.  
- D�ng Postman (ho?c trang web) g?i y�u c?u �?n c�c �?a ch? /register, /login �? th?.

---

## Ghi ch� an to�n cho ph? huynh/gi�o vi�n

- T�i li?u n�y l� �? h?c v� th? nghi?m. Kh�ng d�ng c�c m?t kh?u th?t khi th?.  
- Lu�n b?o v? th�ng tin c� nh�n c?a h?c sinh.

---

## Gi?y ph�p & B?n quy?n

> ?? B?n quy?n � [2025] [Sok Kim Thanh] � T�i li?u n�y do [Sok Kim Thanh] bi�n so?n. M?i quy?n ��?c b?o l�u. Kh�ng ��?c sao ch�p ho?c s? d?ng cho m?c ��ch th��ng m?i n?u kh�ng ��?c ph�p.

Gi?y ph�p: CC BY-NC-SA 4.0 (Chi ti?t: https://creativecommons.org/licenses/by-nc-sa/4.0/)

---

Ch�c b?n h?c vui! ??
