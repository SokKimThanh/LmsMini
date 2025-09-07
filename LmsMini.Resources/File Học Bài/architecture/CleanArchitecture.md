# Kiến Trúc Clean Architecture - LmsMini

Tài liệu hướng dẫn cách tổ chức dự án LmsMini theo mô hình Clean Architecture, bao gồm các tham chiếu giữa các project, lệnh cần thiết và vị trí các file để dễ dàng nắm bắt và phát triển.

## 🎯 Mục Tiêu

- **Tách biệt rõ ràng** các tầng: Presentation / Application / Domain / Infrastructure
- **Dễ dàng mở rộng**, kiểm thử và triển khai
- **Quy ước vị trí file** giúp lập trình viên nhanh chóng tìm được code liên quan

## 🏗️ Các Project và Nhiệm Vụ

### 📂 LmsMini.Api (Tầng Trình Bày - Presentation Layer)
- **Nhiệm vụ**: Web API, Controllers, Swagger, Authentication
- **Tham chiếu**: LmsMini.Application, LmsMini.Infrastructure
- **Chức năng**: Tiếp nhận HTTP requests, xác thực, ủy quyền và trả về responses

### 📂 LmsMini.Application (Tầng Ứng Dụng - Application Layer)
- **Nhiệm vụ**: CQRS (MediatR), DTOs, Commands, Queries, Handlers, Quy tắc nghiệp vụ
- **Tham chiếu**: LmsMini.Domain
- **Chức năng**: Xử lý logic nghiệp vụ, orchestration, use cases

### 📂 LmsMini.Domain (Tầng Miền - Domain Layer)
- **Nhiệm vụ**: Entities, Value Objects, Domain Services, Enums, Exceptions
- **Tham chiếu**: **KHÔNG tham chiếu project nào khác**
- **Chức năng**: Chứa các quy tắc nghiệp vụ cốt lõi, logic miền

### 📂 LmsMini.Infrastructure (Tầng Hạ Tầng - Infrastructure Layer)
- **Nhiệm vụ**: EF Core DbContext, Repositories, File storage, Email adapters, Migrations
- **Tham chiếu**: LmsMini.Domain
- **Chức năng**: Triển khai cụ thể cho database, file system, external services

### 📂 LmsMini.Tests (Kiểm Thử - Testing)
- **Nhiệm vụ**: Unit tests, Integration tests
- **Tham chiếu**: LmsMini.Application, LmsMini.Domain, LmsMini.Infrastructure
- **Chức năng**: Kiểm thử các tầng thông qua interfaces

## 🔗 Sơ Đồ Tham Chiếu Project

```
LmsMini.Api
    ↳ (references)
LmsMini.Application ↔ LmsMini.Infrastructure
    ↳ (references)      ↳ (references)
LmsMini.Domain ↔ ↔ ↔ ↔ ↔
```

**Chi tiết tham chiếu:**
- `LmsMini.Api` → `LmsMini.Application`, `LmsMini.Infrastructure`
- `LmsMini.Application` → `LmsMini.Domain`
- `LmsMini.Infrastructure` → `LmsMini.Domain`
- `LmsMini.Tests` → `LmsMini.Application`, `LmsMini.Domain`, `LmsMini.Infrastructure`

## 📂 Cấu Trúc Thư Mục Chi Tiết

```
LmsMini/
├── LmsMini.Api/
│   ├── Controllers/            # Các API Controllers
│   ├── DTOs/                   # DTOs cho tầng presentation (nếu cần)
│   ├── Configuration/          # Cấu hình, đăng ký DI
│   ├── Middleware/             # Custom middleware
│   ├── docs/                   # Tài liệu dự án
│
├── LmsMini.Application/
│   ├── Common/                 # Utilities chung, interfaces
│   ├── Features/               # Tổ chức theo tính năng
│   │   ├── Courses/            # Quản lý khóa học
│   │   │   ├── Commands/       # Lệnh tạo, sửa, xóa
│   │   │   ├── Queries/        # Truy vấn dữ liệu
│   │   │   ├── DTOs/           # Data Transfer Objects
│   │   ├── Users/              # Quản lý người dùng
│   │   ├── Assessments/        # Đánh giá, kiểm tra
│   ├── Behaviors/              # MediatR pipeline behaviors
│   ├── Mapping/                # AutoMapper profiles
│   ├── Validators/             # FluentValidation validators
│
├── LmsMini.Domain/
│   ├── Entities/               # Các entity chính
│   │   ├── Identity/           # AspNetUser
│   │   ├── CourseManagement/   # Course, Module, Lesson, Enrollment
│   │   ├── Assessment/         # Quiz, Question, Option, QuizAttempt
│   │   ├── Tracking/           # Progress, Notification, AuditLog
│   │   ├── FileManagement/     # FileAsset
│   │   ├── Infrastructure/     # OutboxMessage
│   ├── ValueObjects/           # Value objects
│   ├── Enums/                  # Các enum
│   ├── Exceptions/             # Domain exceptions
│   ├── Interfaces/             # Domain service interfaces
│
├── LmsMini.Infrastructure/
│   ├── Persistence/
│   │   ├── LmsDbContext.cs     # EF Core DbContext chính
│   │   ├── Configurations/     # Entity configurations
│   │   ├── Migrations/         # Database migrations
│   ├── Repositories/           # Triển khai repository pattern
│   ├── Services/               # External services
│   │   ├── FileStorage/        # Quản lý file
│   │   ├── Email/              # Email service
│   │   ├── Authentication/     # JWT, Identity
│   ├── Extensions/             # Extension methods
│
├── LmsMini.Tests/
│   ├── Unit/                   # Unit tests
│   │   ├── Application/
│   │   ├── Domain/
│   │   ├── Infrastructure/
│   ├── Integration/            # Integration tests
│       ├── Api/
│       ├── Repositories/
```

**📌 Ghi chú quan trọng:** 
- Entities được scaffold từ database đặt trong `LmsMini.Domain/Entities`
- DbContext đặt trong `LmsMini.Infrastructure/Persistence`

## 📍 Vị Trí Các File Quan Trọng

| **Loại File** | **Đường Dẫn** | **Mô Tả** |
|---------------|----------------|-----------|
| **DbContext** | `LmsMini.Infrastructure/Persistence/LmsDbContext.cs` | Context chính của EF Core |
| **Entities** | `LmsMini.Domain/Entities/*.cs` | Các entity domain |
| **Controllers** | `LmsMini.Api/Controllers/*.cs` | API Controllers |
| **Commands** | `LmsMini.Application/Features/*/Commands/` | CQRS Commands |
| **Queries** | `LmsMini.Application/Features/*/Queries/` | CQRS Queries |
| **Handlers** | `LmsMini.Application/Features/*/Handlers/` | Command/Query handlers |
| **DTOs** | `LmsMini.Application/Features/*/DTOs/` | Data Transfer Objects |
| **Mapping** | `LmsMini.Application/Mapping/` | AutoMapper profiles |
| **Validators** | `LmsMini.Application/Validators/` | FluentValidation |
| **Repositories** | `LmsMini.Infrastructure/Repositories/` | Repository implementations |

## ⚙️ Cấu Hình Dependency Injection

### Ví dụ trong `Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Database Context
builder.Services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// MediatR cho CQRS
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(CreateCourseCommand).Assembly));

// AutoMapper cho object mapping
builder.Services.AddAutoMapper(typeof(CourseProfile).Assembly);

// FluentValidation cho validation
builder.Services.AddValidatorsFromAssembly(typeof(CreateCourseValidator).Assembly);

// Repository pattern
builder.Services.AddScoped<ICourseRepository, CourseRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();

// Domain services
builder.Services.AddScoped<ICourseService, CourseService>();

// Infrastructure services
builder.Services.AddScoped<IFileStorageService, FileStorageService>();
builder.Services.AddScoped<IEmailService, EmailService>();

// Authentication & Authorization
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => { /* JWT config */ });

// Logging với Serilog
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration));

var app = builder.Build();
```

## 🛠️ Các Lệnh Thường Dùng

### **Lệnh Cơ Bản**
```bash
# Khôi phục packages
dotnet restore

# Build solution
dotnet build

# Chạy API
dotnet run --project LmsMini.Api

# Chạy tests
dotnet test

# Clean solution
dotnet clean
```

### **Quản Lý Package**
```bash
# Thêm packages cho Application layer
dotnet add LmsMini.Application package MediatR
dotnet add LmsMini.Application package AutoMapper
dotnet add LmsMini.Application package FluentValidation

# Thêm packages cho Infrastructure layer
dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.SqlServer
dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.Design

# Thêm packages cho API layer
dotnet add LmsMini.Api package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add LmsMini.Api package Serilog.AspNetCore
```

### **Entity Framework Core**

#### **Scaffold từ Database (Database-first)**
```bash
dotnet ef dbcontext scaffold \
"Server=.\\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;" \
Microsoft.EntityFrameworkCore.SqlServer \
--output-dir ../LmsMini.Domain/Entities \
--context-dir ../LmsMini.Infrastructure/Persistence \
--context LmsDbContext \
--namespace LmsMini.Domain.Entities \
--use-database-names \
--no-onconfiguring \
--project ./LmsMini.Infrastructure/LmsMini.Infrastructure.csproj \
--startup-project ./LmsMini.Api/LmsMini.Api.csproj
```

#### **Migrations (Code-first)**
```bash
# Tạo migration mới
dotnet ef migrations add TenMigration \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api

# Cập nhật database
dotnet ef database update \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api

# Xem danh sách migrations
dotnet ef migrations list \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api

# Rollback migration
dotnet ef database update TenMigrationTruoc \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api
```

## 🔄 Luồng Hoạt Động (Data Flow)

```
1. 🟢 Client gửi HTTP Request
         ↓
2. 🟢 Controller nhận request
         ↓
3. 🟢 Controller tạo Command/Query
         ↓
4. 🟢 Gửi qua MediatR
         ↓
5. 🟢 Handler xử lý logic nghiệp vụ
         ↓
6. 🟢 Repository tương tác với Database
         ↓
7. 🟢 Domain entities áp dụng business rules
         ↓
8. 🟢 Kết quả trả về qua DTO
         ↓
9. 🟢 Controller trả về HTTP Response
```

### **Chi Tiết Từng Bước:**

1. **Client → Controller**: HTTP request đến API endpoint
2. **Controller**: Nhận request, validate cơ bản, tạo Command/Query
3. **MediatR**: Định tuyến đến Handler phù hợp
4. **Handler**: Xử lý business logic, gọi Repository/Domain Services
5. **Repository**: Truy cập database thông qua DbContext
6. **Domain**: Áp dụng business rules và validation
7. **Response**: Mapping sang DTO và trả về Controller
8. **HTTP Response**: Trả về client với format JSON

## 🧪 Chiến Lược Kiểm Thử

### **Unit Tests**
- **Domain**: Test business rules trong entities và domain services
- **Application**: Test handlers với mocked repositories
- **Infrastructure**: Test repositories với in-memory database

### **Integration Tests**
- **API**: Test endpoints với real database
- **Database**: Test Entity Framework configurations
- **External Services**: Test với mock external dependencies

### **Ví dụ Structure Tests:**
```
LmsMini.Tests/
├── Unit/
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── CourseTests.cs
│   │   │   ├── UserTests.cs
│   │   ├── Services/
│   │       ├── CourseServiceTests.cs
│   ├── Application/
│   │   ├── Commands/
│   │   │   ├── CreateCourseCommandHandlerTests.cs
│   │   ├── Queries/
│   │       ├── GetCoursesQueryHandlerTests.cs
│   ├── Infrastructure/
│       ├── Repositories/
│       │   ├── CourseRepositoryTests.cs
│       ├── Services/
│           ├── FileStorageServiceTests.cs
├── Integration/
    ├── Api/
    │   ├── CoursesControllerTests.cs
    ├── Database/
        ├── LmsDbContextTests.cs
```

## 🌟 Best Practices (Thực Hành Tốt Nhất)

### **Nguyên Tắc Clean Architecture**
- **Domain Layer**: Không phụ thuộc vào framework nào
- **Application Layer**: Định nghĩa interfaces, Infrastructure implement
- **DTOs**: Sử dụng cho việc truyền dữ liệu qua boundaries
- **Cross-cutting Concerns**: Tập trung trong Application Behaviors

### **Quy Tắc Code Organization**
- **Controllers**: Chỉ làm orchestration, không chứa business logic
- **Handlers**: Một handler cho một use case cụ thể
- **Repositories**: Interface trong Application, implement trong Infrastructure
- **Entities**: Chứa business rules, không chứa framework dependencies

### **Naming Conventions**
- **Commands**: `CreateCourseCommand`, `UpdateCourseCommand`
- **Queries**: `GetCoursesQuery`, `GetCourseByIdQuery`
- **Handlers**: `CreateCourseCommandHandler`, `GetCoursesQueryHandler`
- **DTOs**: `CourseDto`, `CreateCourseDto`, `UpdateCourseDto`
- **Validators**: `CreateCourseValidator`, `UpdateCourseValidator`

### **Error Handling**
- **Domain Exceptions**: Cho business rule violations
- **Application Exceptions**: Cho application logic errors
- **Infrastructure Exceptions**: Cho external service failures
- **Global Exception Middleware**: Xử lý tất cả exceptions trong API

---

## 📚 Tham Khảo Thêm

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Microsoft .NET Application Architecture Guides](https://docs.microsoft.com/en-us/dotnet/architecture/)
- [MediatR Documentation](https://github.com/jbogard/MediatR)
- [Entity Framework Core Documentation](https://docs.microsoft.com/en-us/ef/core/)

---

**📍 Vị trí tài liệu**: `LmsMini.Api/docs/CleanArchitecture.md`
