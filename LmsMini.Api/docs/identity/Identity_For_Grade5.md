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

## 5. Thêm đăng ký Identity vào Program.cs
- Trong file Program.cs, cô sẽ thêm lệnh để bật hệ thống quản lý người dùng:
  - `services.AddIdentity<...>().AddEntityFrameworkStores<LmsDbContext>();`
  - Nếu dùng token JWT, thêm `services.AddAuthentication(...).AddJwtBearer(...);`
- Khi chạy ứng dụng, nhớ gọi:
  - `app.UseAuthentication();` trước
  - `app.UseAuthorization();` sau

## 6. Tạo migration để tạo bảng trong database
- Tạo migration giống như bản vẽ để xây tủ lưu trong database.
- Tạo migration: `dotnet ef migrations add Init_Identity -s LmsMini.Api -p LmsMini.Infrastructure`
- Áp migration: `dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure`

## 7. Tạo sẵn Roles và tài khoản admin
- Tạo các vai trò: Admin (người quản lý), Instructor (giáo viên), Learner (học sinh).
- Tạo một tài khoản admin ban đầu để quản lý hệ thống.
- Viết đoạn mã seed dùng RoleManager và UserManager và chạy khi ứng dụng khởi động; làm sao để chạy nhiều lần vẫn an toàn.

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

---
Tập tin này lưu tại: `LmsMini.Api/docs/identity/Identity_For_Grade5.md`
