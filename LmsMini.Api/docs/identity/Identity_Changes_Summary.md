# T�m t?t nh?ng thay �?i �? th?c hi?n cho ASP.NET Identity

Xin ch�o c�c em, c� �? th?c hi?n m?t s? ch?nh s?a �? t�ch h?p ASP.NET Identity v�o d? �n theo ki?n tr�c Clean Architecture. D�?i ��y l� b?n t�m t?t ng?n g?n, gi?i th�ch t?ng ph?n b?ng gi?ng c� nh? nh�ng, d? hi?u �? c�c em n?m nhanh.

---

## M?c ��ch
M?c ti�u c?a nh?ng thay �?i n�y l�: cho ph�p ?ng d?ng d�ng ASP.NET Identity (UserManager, RoleManager, token providers) l�u d? li?u ng�?i d�ng v�o `LmsDbContext` v� h? tr? JWT authentication.

---

## Nh?ng file �? s?a v� l? do (m?i ph?n gi?i th�ch ng?n)

1) LmsMini.Domain/Entities/Identity/AspNetUser.cs
- Th?c hi?n: chuy?n l?p `AspNetUser` �? k? th?a `IdentityUser<Guid>`.
- V? sao: `IdentityUser<Guid>` �? cung c?p s?n c�c thu?c t�nh chu?n c?a Identity (Id, UserName, Email, PasswordHash, Normalized...); vi?c n�y gi�p s? d?ng tr?c ti?p `UserManager`/`SignInManager` v� tr�nh tr�ng l?p thu?c t�nh.
- H?u qu?: c�c quan h? domain (navigation properties) gi? nguy�n �? li�n k?t v?i c�c b?ng kh�c (Courses, Enrollments, AuditLogs, ...).

2) LmsMini.Infrastructure/Persistence/LmsDbContext.cs
- Th?c hi?n: cho `LmsDbContext` k? th?a `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>` v� g?i `base.OnModelCreating(modelBuilder)`.
- V? sao: �? Entity Framework hi?u c�c b?ng Identity chu?n (AspNetUsers, AspNetRoles, AspNetUserRoles, ...) v� v?n gi? c?u h?nh hi?n c� cho c�c entity kh�c.
- L�u ?: ph?n c?u h?nh model c? ��?c gi?, nh�ng kh?i t?o Identity c?n `base.OnModelCreating` tr�?c khi b? sung mapping ri�ng.

3) LmsMini.Api/Program.cs
- Th?c hi?n: ��ng k? Identity b?ng `AddIdentity<AspNetUser, IdentityRole<Guid>>()` v� n?i v?i EF store b?ng `.AddEntityFrameworkStores<LmsDbContext>()`; th�m c?u h?nh JWT (`AddAuthentication().AddJwtBearer(...)`); g?i `app.UseAuthentication()` tr�?c `app.UseAuthorization()`.
- V? sao: �? runtime bi?t c�ch qu?n l? user/role v� �? middleware x? l? authentication (JWT token) cho c�c request.
- G?i ?: c?n �?t `Jwt:Key` trong user-secrets / appsettings.Development.json tr�?c khi ch?y.

4) Thay �?i project files (.csproj)
- Th?c hi?n: th�m package references c?n thi?t v�o c�c project:
  - `LmsMini.Infrastructure` �? c� `Microsoft.AspNetCore.Identity.EntityFrameworkCore`.
  - `LmsMini.Domain` th�m `Microsoft.AspNetCore.Identity.EntityFrameworkCore` �? domain c� th? tham chi?u `IdentityUser<Guid>` type.
  - `LmsMini.Api` th�m `Microsoft.AspNetCore.Authentication.JwtBearer` v� `Microsoft.AspNetCore.Identity.EntityFrameworkCore`.
- V? sao: �?m b?o m? compile khi s? d?ng ki?u Identity trong c�c project kh�c nhau.

5) T�i li?u h�?ng d?n (docs)
- Th?c hi?n: c� �? c?p nh?t `LmsMini.Api/docs/identity/Identity_For_Grade5.md` v?i h�?ng d?n ��n gi?n, v� d? Program.cs, seed roles/admin, checklist migration v� thao t�c th?c h�nh.
- V? sao: �? c�c em (v� c�c b?n dev) c� t�i li?u tham kh?o khi th?c hi?n migration v� th? nghi?m flow ��ng k?/��ng nh?p.

---

## H�?ng d?n ng?n c�c b�?c ti?p theo (g?i ? cho c�c em l�m theo)
1. Ki?m tra `Jwt:Key` b?ng c�ch �?t user-secrets ho?c appsettings.Development.json.  
2. T?o migration cho Identity v� review file migration:
   - `dotnet ef migrations add Init_Identity -p LmsMini.Infrastructure -s LmsMini.Api`  
   - M? migration v� ki?m tra c�c `CreateTable` cho `AspNet*`  
3. �p migration: `dotnet ef database update -p LmsMini.Infrastructure -s LmsMini.Api`  
4. Ch?y ?ng d?ng v� seed roles/admin (theo snippet trong t�i li?u).  
5. D�ng Swagger/Postman �? th? ��ng k?/��ng nh?p.

---

## Nh?ng l�u ? an to�n v� ki?m tra
- KH�NG commit c�c b� m?t (Jwt:Key) l�n Git.  
- Lu�n review file migration tr�?c khi apply.  
- N?u d? �n d�ng `Guid` cho Id, gi? ki?u `IdentityUser<Guid>` cho �?ng nh?t; n?u mu?n d�ng `string` (m?c �?nh), c?n �i?u ch?nh l?i lo?i Id t��ng ?ng.

---

N?u c�c em mu?n, c� c� th? l�m ti?p c�c vi?c sau (ch?n m?t):
- A: T?o migration `Init_Identity` trong repo v� �?y file migration (ch? t?o, kh�ng apply).  
- B: T?o file seeder th?c thi (Infrastructure) v� t? �?ng g?i khi app kh?i �?ng.  
- C: Vi?t th�m v� d? endpoint Register/Login v� handler skeleton trong Application.

Tr? l?i A/B/C n?u c�c em mu?n c� l�m gi�p ph?n ti?p theo nh�. C� s? h�?ng d?n t?ng b�?c nh? nh�ng �? c�c em l�m theo.

---

T?p tin l�u t?i: `LmsMini.Api/docs/identity/Identity_Changes_Summary.md`

C� gi�o,
_C� tr? trung, th�n thi?n v� r?t t? m? � lu�n s?n s�ng gi�p c�c em h?c ti?p :)_