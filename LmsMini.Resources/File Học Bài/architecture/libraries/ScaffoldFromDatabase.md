# 📦 Scaffold Entity từ Database cho LMS Mini (.NET 9)

## 🎯 Mục tiêu
Hướng dẫn sinh mã C# (Entity + DbContext) từ cơ sở dữ liệu LMSMini bằng Entity Framework Core 9, theo hướng **Database-first**, và tổ chức vào cấu trúc thư mục Clean Architecture của dự án LmsMini.

---

## 🧱 Yêu cầu trước khi thực hiện

### 1. Cài đặt công cụ EF Core
```bash
dotnet tool install --global dotnet-ef
```

### 2. Kiểm tra packages cần thiết
- **LmsMini.Infrastructure**: Đã có EF Core packages
- **LmsMini.Api**: Đã có `Microsoft.EntityFrameworkCore.Design`

### 3. Cấu trúc thư mục hiện tại
```
LmsMini/
├── LmsMini.Api/                     # Presentation Layer
├── LmsMini.Application/             # Application Layer  
├── LmsMini.Domain/                  # Domain Layer
│   └── Entities/                    # <-- Entities sẽ được tạo ở đây
├── LmsMini.Infrastructure/          # Infrastructure Layer
│   └── Persistence/                 # <-- DbContext sẽ được tạo ở đây
└── LmsMini.Tests/                   # Testing
```

---

## ⚙️ Lệnh scaffold cho LmsMini

### Lệnh đầy đủ đã được test thành công:
```bash
dotnet ef dbcontext scaffold "Server=.\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;" Microsoft.EntityFrameworkCore.SqlServer \
--output-dir ../LmsMini.Domain/Entities \
--context-dir ../LmsMini.Infrastructure/Persistence \
--context LmsDbContext \
--namespace LmsMini.Domain.Entities \
--use-database-names \
--no-onconfiguring \
--project ./LmsMini.Infrastructure/LmsMini.Infrastructure.csproj \
--startup-project ./LmsMini.Api/LmsMini.Api.csproj
```

---

## 🔍 Giải thích tham số chi tiết

| **Tham số** | **Giá trị** | **Ý nghĩa** |
|-------------|-------------|-------------|
| **Connection String** | `Server=.\SQLEXPRESS;Database=LMSMini;...` | Kết nối đến SQL Server Express với SSL trust |
| **Provider** | `Microsoft.EntityFrameworkCore.SqlServer` | Provider cho SQL Server |
| `--output-dir` | `../LmsMini.Domain/Entities` | Thư mục chứa các entity classes |
| `--context-dir` | `../LmsMini.Infrastructure/Persistence` | Thư mục chứa DbContext |
| `--context` | `LmsDbContext` | Tên class DbContext |
| `--namespace` | `LmsMini.Domain.Entities` | Namespace cho entities |
| `--use-database-names` | | Giữ nguyên tên bảng từ database |
| `--no-onconfiguring` | | Không tạo OnConfiguring method |
| `--project` | `./LmsMini.Infrastructure/...` | Project chứa EF Core packages |
| `--startup-project` | `./LmsMini.Api/...` | Project startup có Design package |

---

## 📁 Cấu trúc sau khi scaffold

### Entities được tạo trong `LmsMini.Domain/Entities/`:
```
LmsMini.Domain/Entities/
├── AspNetUser.cs              # Identity user
├── Course.cs                  # Core course entity
├── Module.cs                  # Course modules
├── Lesson.cs                  # Individual lessons
├── Quiz.cs                    # Assessment quizzes
├── Question.cs                # Quiz questions
├── Option.cs                  # Question options
├── QuizAttempt.cs            # Student attempts
├── AttemptAnswer.cs          # Answer details
├── Enrollment.cs             # Student enrollments
├── Progress.cs               # Learning progress
├── Notification.cs           # System notifications
├── FileAsset.cs              # File management
├── AuditLog.cs               # Audit logging
└── OutboxMessage.cs          # Event sourcing
```

### DbContext trong `LmsMini.Infrastructure/Persistence/`:
```
LmsMini.Infrastructure/Persistence/
└── LmsDbContext.cs           # Complete EF Core context
```

---

## 🏗️ Tổ chức thư mục theo Domain (Tùy chọn)

Sau khi scaffold, bạn có thể tổ chức entities theo domain modules:

### Cấu trúc được khuyến nghị:
```
LmsMini.Domain/Entities/
├── Identity/
│   └── AspNetUser.cs
├── CourseManagement/
│   ├── Course.cs
│   ├── Module.cs
│   ├── Lesson.cs
│   └── Enrollment.cs
├── Assessment/
│   ├── Quiz.cs
│   ├── Question.cs
│   ├── Option.cs
│   ├── QuizAttempt.cs
│   └── AttemptAnswer.cs
├── Tracking/
│   ├── Progress.cs
│   ├── Notification.cs
│   └── AuditLog.cs
├── FileManagement/
│   └── FileAsset.cs
└── Infrastructure/
    └── OutboxMessage.cs
```

### Lệnh di chuyển files (PowerShell):
```powershell
# Tạo thư mục
mkdir LmsMini.Domain/Entities/Identity
mkdir LmsMini.Domain/Entities/CourseManagement
mkdir LmsMini.Domain/Entities/Assessment
mkdir LmsMini.Domain/Entities/Tracking
mkdir LmsMini.Domain/Entities/FileManagement
mkdir LmsMini.Domain/Entities/Infrastructure

# Di chuyển files (ví dụ)
mv LmsMini.Domain/Entities/AspNetUser.cs LmsMini.Domain/Entities/Identity/
mv LmsMini.Domain/Entities/Course.cs LmsMini.Domain/Entities/CourseManagement/
# ... các file khác
```

---

## 🧪 Kiểm tra sau scaffold

### 1. Verify DbContext
```bash
# Kiểm tra DbContext đã được tạo
ls LmsMini.Infrastructure/Persistence/LmsDbContext.cs
```

### 2. Build solution
```bash
dotnet build
```

### 3. Kiểm tra entities count
```bash
# Đếm số entities được tạo (PowerShell)
(Get-ChildItem LmsMini.Domain/Entities/*.cs).Count
# Kết quả mong đợi: 15 files
```

### 4. Verify namespaces
Mở một vài entity files và kiểm tra:
- Namespace: `LmsMini.Domain.Entities`
- Using statements phù hợp
- Relationships được mapping đúng

---

## 🔧 Tùy chỉnh sau scaffold

### 1. Cập nhật appsettings.json
Connection string trong API project đã được cấu hình:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.\\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

### 2. Đăng ký DbContext trong DI Container
```csharp
// Program.cs hoặc Startup.cs
services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(connectionString));
```

### 3. Base Entity Classes (Tùy chọn)
Tạo base classes cho common properties:
```csharp
public abstract class BaseEntity
{
    public Guid Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public abstract class AuditableEntity : BaseEntity
{
    public Guid CreatedBy { get; set; }
    public Guid? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }
}
```

---

## 📌 Lưu ý quan trọng

### ✅ **Đã được verify:**
- Connection string với `TrustServerCertificate=True`
- Project references đã được cấu hình
- EF Core packages phiên bản 9.0.8
- Target framework .NET 9

### ⚠️ **Lưu ý:**
- **Backup trước khi scaffold** nếu đã có entities
- Sử dụng `--force` để overwrite files existing
- Kiểm tra Git changes sau scaffold
- Test DbContext với simple query

### 🚫 **Tránh:**
- Chạy scaffold multiple lần mà không backup
- Thay đổi namespace manually sau scaffold
- Xóa generated files mà không hiểu dependencies

---

## 🔄 Re-scaffold khi DB thay đổi

### Lệnh update khi có thay đổi database:
```bash
# Sử dụng --force để ghi đè files existing
dotnet ef dbcontext scaffold "Server=.\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;" Microsoft.EntityFrameworkCore.SqlServer \
--output-dir ../LmsMini.Domain/Entities \
--context-dir ../LmsMini.Infrastructure/Persistence \
--context LmsDbContext \
--namespace LmsMini.Domain.Entities \
--use-database-names \
--no-onconfiguring \
--project ./LmsMini.Infrastructure/LmsMini.Infrastructure.csproj \
--startup-project ./LmsMini.Api/LmsMini.Api.csproj \
--force
```

---

## ✅ Kết luận

Scaffold từ database cho LmsMini đã được tối ưu để:
- **Tuân thủ Clean Architecture** với entities trong Domain layer
- **DbContext trong Infrastructure** layer phù hợp
- **Namespace consistency** across project
- **Dễ dàng maintain** và extend
- **Hỗ trợ team development** với cấu trúc rõ ràng

Cấu trúc này giúp team 2 developers dễ dàng collaboration và maintain codebase một cách hiệu quả.