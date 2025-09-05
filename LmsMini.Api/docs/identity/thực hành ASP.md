# ASP.NET Identity - Hướng Dẫn Thực Hành (Clean Architecture + Scaffold DB)

## 1. Giới thiệu
ASP.NET Identity là hệ thống quản lý người dùng tích hợp sẵn trong ASP.NET Core, hỗ trợ:
- Đăng ký / Đăng nhập
- Quản lý vai trò (Role) và quyền (Claim)
- Bảo mật mật khẩu, xác thực hai bước (2FA)
- Lưu trữ thông tin người dùng qua Entity Framework Core

Tài liệu này hướng dẫn triển khai ASP.NET Identity trong dự án **Clean Architecture** đã có sẵn cấu trúc và entity từ **scaffolding DB**.

---

## 2. Kiến trúc tổng thể

### 2.1 Các Layer
| Layer | Nhiệm vụ | Ví dụ |
|-------|----------|-------|
| **Domain** | Entity thuần (POCO), interface nghiệp vụ | `Course.cs`, `ICourseRepository.cs` |
| **Application** | Use case, service, DTO, validation | `CreateCourseHandler.cs` |
| **Infrastructure** | DbContext, EF mapping, repository implementation, Identity config | `ApplicationDbContext.cs`, `CourseRepository.cs` |
| **Presentation** | Controller, API endpoint, Razor Pages | `CourseController.cs` |

### 2.2 Nguyên tắc phụ thuộc
- **Presentation** → **Application** → **Domain**
- **Infrastructure** triển khai interface từ **Domain**, được inject vào **Application**

---

## 3. Tích hợp ASP.NET Identity

### 3.1 Cấu hình trong `Program.cs`
```csharp
builder.Services.AddDefaultIdentity<ApplicationUser>(options =>
    options.SignIn.RequireConfirmedAccount = false)
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>();
