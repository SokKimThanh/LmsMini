# Ki?n Tr�c Clean Architecture - LmsMini

T�i li?u h�?ng d?n c�ch t? ch?c d? �n LmsMini theo m� h?nh Clean Architecture, bao g?m c�c tham chi?u gi?a c�c project, l?nh c?n thi?t v� v? tr� c�c file �? d? d�ng n?m b?t v� ph�t tri?n.

## ?? M?c Ti�u

- **T�ch bi?t r? r�ng** c�c t?ng: Presentation / Application / Domain / Infrastructure
- **D? d�ng m? r?ng**, ki?m th? v� tri?n khai
- **Quy �?c v? tr� file** gi�p l?p tr?nh vi�n nhanh ch�ng t?m ��?c code li�n quan

## ??? C�c Project v� Nhi?m V?

### ?? LmsMini.Api (T?ng Tr?nh B�y - Presentation Layer)
- **Nhi?m v?**: Web API, Controllers, Swagger, Authentication
- **Tham chi?u**: LmsMini.Application, LmsMini.Infrastructure
- **Ch?c n�ng**: Ti?p nh?n HTTP requests, x�c th?c, ?y quy?n v� tr? v? responses

### ?? LmsMini.Application (T?ng ?ng D?ng - Application Layer)
- **Nhi?m v?**: CQRS (MediatR), DTOs, Commands, Queries, Handlers, Quy t?c nghi?p v?
- **Tham chi?u**: LmsMini.Domain
- **Ch?c n�ng**: X? l? logic nghi?p v?, orchestration, use cases

### ?? LmsMini.Domain (T?ng Mi?n - Domain Layer)
- **Nhi?m v?**: Entities, Value Objects, Domain Services, Enums, Exceptions
- **Tham chi?u**: **KH�NG tham chi?u project n�o kh�c**
- **Ch?c n�ng**: Ch?a c�c quy t?c nghi?p v? c?t l?i, logic mi?n

### ?? LmsMini.Infrastructure (T?ng H? T?ng - Infrastructure Layer)
- **Nhi?m v?**: EF Core DbContext, Repositories, File storage, Email adapters, Migrations
- **Tham chi?u**: LmsMini.Domain
- **Ch?c n�ng**: Tri?n khai c? th? cho database, file system, external services

### ?? LmsMini.Tests (Ki?m Th? - Testing)
- **Nhi?m v?**: Unit tests, Integration tests
- **Tham chi?u**: LmsMini.Application, LmsMini.Domain, LmsMini.Infrastructure
- **Ch?c n�ng**: Ki?m th? c�c t?ng th�ng qua interfaces

## ?? S� �? Tham Chi?u Project

```
LmsMini.Api
    ? (references)
LmsMini.Application ? LmsMini.Infrastructure
    ? (references)      ? (references)
LmsMini.Domain ? ? ? ? ?
```

**Chi ti?t tham chi?u:**
- `LmsMini.Api` ? `LmsMini.Application`, `LmsMini.Infrastructure`
- `LmsMini.Application` ? `LmsMini.Domain`
- `LmsMini.Infrastructure` ? `LmsMini.Domain`
- `LmsMini.Tests` ? `LmsMini.Application`, `LmsMini.Domain`, `LmsMini.Infrastructure`

## ?? C?u Tr�c Th� M?c Chi Ti?t

```
LmsMini/
??? LmsMini.Api/
?   ??? Controllers/            # C�c API Controllers
?   ??? DTOs/                   # DTOs cho t?ng presentation (n?u c?n)
?   ??? Configuration/          # C?u h?nh, ��ng k? DI
?   ??? Middleware/             # Custom middleware
?   ??? docs/                   # T�i li?u d? �n
?
??? LmsMini.Application/
?   ??? Common/                 # Utilities chung, interfaces
?   ??? Features/               # T? ch?c theo t�nh n�ng
?   ?   ??? Courses/            # Qu?n l? kh�a h?c
?   ?   ?   ??? Commands/       # L?nh t?o, s?a, x�a
?   ?   ?   ??? Queries/        # Truy v?n d? li?u
?   ?   ?   ??? DTOs/           # Data Transfer Objects
?   ?   ??? Users/              # Qu?n l? ng�?i d�ng
?   ?   ??? Assessments/        # ��nh gi�, ki?m tra
?   ??? Behaviors/              # MediatR pipeline behaviors
?   ??? Mapping/                # AutoMapper profiles
?   ??? Validators/             # FluentValidation validators
?
??? LmsMini.Domain/
?   ??? Entities/               # C�c entity ch�nh
?   ?   ??? Identity/           # AspNetUser
?   ?   ??? CourseManagement/   # Course, Module, Lesson, Enrollment
?   ?   ??? Assessment/         # Quiz, Question, Option, QuizAttempt
?   ?   ??? Tracking/           # Progress, Notification, AuditLog
?   ?   ??? FileManagement/     # FileAsset
?   ?   ??? Infrastructure/     # OutboxMessage
?   ??? ValueObjects/           # Value objects
?   ??? Enums/                  # C�c enum
?   ??? Exceptions/             # Domain exceptions
?   ??? Interfaces/             # Domain service interfaces
?
??? LmsMini.Infrastructure/
?   ??? Persistence/
?   ?   ??? LmsDbContext.cs     # EF Core DbContext ch�nh
?   ?   ??? Configurations/     # Entity configurations
?   ?   ??? Migrations/         # Database migrations
?   ??? Repositories/           # Tri?n khai repository pattern
?   ??? Services/               # External services
?   ?   ??? FileStorage/        # Qu?n l? file
?   ?   ??? Email/              # Email service
?   ?   ??? Authentication/     # JWT, Identity
?   ??? Extensions/             # Extension methods
?
??? LmsMini.Tests/
?   ??? Unit/                   # Unit tests
?   ?   ??? Application/
?   ?   ??? Domain/
?   ?   ??? Infrastructure/
?   ??? Integration/            # Integration tests
?       ??? Api/
?       ??? Repositories/
```

**?? Ghi ch� quan tr?ng:** 
- Entities ��?c scaffold t? database �?t trong `LmsMini.Domain/Entities`
- DbContext �?t trong `LmsMini.Infrastructure/Persistence`

## ?? V? Tr� C�c File Quan Tr?ng

| **Lo?i File** | **��?ng D?n** | **M� T?** |
|---------------|----------------|-----------|
| **DbContext** | `LmsMini.Infrastructure/Persistence/LmsDbContext.cs` | Context ch�nh c?a EF Core |
| **Entities** | `LmsMini.Domain/Entities/*.cs` | C�c entity domain |
| **Controllers** | `LmsMini.Api/Controllers/*.cs` | API Controllers |
| **Commands** | `LmsMini.Application/Features/*/Commands/` | CQRS Commands |
| **Queries** | `LmsMini.Application/Features/*/Queries/` | CQRS Queries |
| **Handlers** | `LmsMini.Application/Features/*/Handlers/` | Command/Query handlers |
| **DTOs** | `LmsMini.Application/Features/*/DTOs/` | Data Transfer Objects |
| **Mapping** | `LmsMini.Application/Mapping/` | AutoMapper profiles |
| **Validators** | `LmsMini.Application/Validators/` | FluentValidation |
| **Repositories** | `LmsMini.Infrastructure/Repositories/` | Repository implementations |

## ?? C?u H?nh Dependency Injection

### V� d? trong `Program.cs`:

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

// Logging v?i Serilog
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration));

var app = builder.Build();
```

## ??? C�c L?nh Th�?ng D�ng

### **L?nh C� B?n**
```bash
# Kh�i ph?c packages
dotnet restore

# Build solution
dotnet build

# Ch?y API
dotnet run --project LmsMini.Api

# Ch?y tests
dotnet test

# Clean solution
dotnet clean
```

### **Qu?n L? Package**
```bash
# Th�m packages cho Application layer
dotnet add LmsMini.Application package MediatR
dotnet add LmsMini.Application package AutoMapper
dotnet add LmsMini.Application package FluentValidation

# Th�m packages cho Infrastructure layer
dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.SqlServer
dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.Design

# Th�m packages cho API layer
dotnet add LmsMini.Api package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add LmsMini.Api package Serilog.AspNetCore
```

### **Entity Framework Core**

#### **Scaffold t? Database (Database-first)**
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
# T?o migration m?i
dotnet ef migrations add TenMigration \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api

# C?p nh?t database
dotnet ef database update \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api

# Xem danh s�ch migrations
dotnet ef migrations list \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api

# Rollback migration
dotnet ef database update TenMigrationTruoc \
--project LmsMini.Infrastructure \
--startup-project LmsMini.Api
```

## ?? Lu?ng Ho?t �?ng (Data Flow)

```
1. ?? Client g?i HTTP Request
         ?
2. ?? Controller nh?n request
         ?
3. ?? Controller t?o Command/Query
         ?
4. ?? G?i qua MediatR
         ?
5. ?? Handler x? l? logic nghi?p v?
         ?
6. ?? Repository t��ng t�c v?i Database
         ?
7. ?? Domain entities �p d?ng business rules
         ?
8. ?? K?t qu? tr? v? qua DTO
         ?
9. ?? Controller tr? v? HTTP Response
```

### **Chi Ti?t T?ng B�?c:**

1. **Client ? Controller**: HTTP request �?n API endpoint
2. **Controller**: Nh?n request, validate c� b?n, t?o Command/Query
3. **MediatR**: �?nh tuy?n �?n Handler ph� h?p
4. **Handler**: X? l? business logic, g?i Repository/Domain Services
5. **Repository**: Truy c?p database th�ng qua DbContext
6. **Domain**: �p d?ng business rules v� validation
7. **Response**: Mapping sang DTO v� tr? v? Controller
8. **HTTP Response**: Tr? v? client v?i format JSON

## ?? Chi?n L�?c Ki?m Th?

### **Unit Tests**
- **Domain**: Test business rules trong entities v� domain services
- **Application**: Test handlers v?i mocked repositories
- **Infrastructure**: Test repositories v?i in-memory database

### **Integration Tests**
- **API**: Test endpoints v?i real database
- **Database**: Test Entity Framework configurations
- **External Services**: Test v?i mock external dependencies

### **V� d? Structure Tests:**
```
LmsMini.Tests/
??? Unit/
?   ??? Domain/
?   ?   ??? Entities/
?   ?   ?   ??? CourseTests.cs
?   ?   ?   ??? UserTests.cs
?   ?   ??? Services/
?   ?       ??? CourseServiceTests.cs
?   ??? Application/
?   ?   ??? Commands/
?   ?   ?   ??? CreateCourseCommandHandlerTests.cs
?   ?   ??? Queries/
?   ?       ??? GetCoursesQueryHandlerTests.cs
?   ??? Infrastructure/
?       ??? Repositories/
?       ?   ??? CourseRepositoryTests.cs
?       ??? Services/
?           ??? FileStorageServiceTests.cs
??? Integration/
    ??? Api/
    ?   ??? CoursesControllerTests.cs
    ??? Database/
        ??? LmsDbContextTests.cs
```

## ?? Best Practices (Th?c H�nh T?t Nh?t)

### **Nguy�n T?c Clean Architecture**
- **Domain Layer**: Kh�ng ph? thu?c v�o framework n�o
- **Application Layer**: �?nh ngh?a interfaces, Infrastructure implement
- **DTOs**: S? d?ng cho vi?c truy?n d? li?u qua boundaries
- **Cross-cutting Concerns**: T?p trung trong Application Behaviors

### **Quy T?c Code Organization**
- **Controllers**: Ch? l�m orchestration, kh�ng ch?a business logic
- **Handlers**: M?t handler cho m?t use case c? th?
- **Repositories**: Interface trong Application, implement trong Infrastructure
- **Entities**: Ch?a business rules, kh�ng ch?a framework dependencies

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
- **Global Exception Middleware**: X? l? t?t c? exceptions trong API

---

## ?? Tham Kh?o Th�m

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Microsoft .NET Application Architecture Guides](https://docs.microsoft.com/en-us/dotnet/architecture/)
- [MediatR Documentation](https://github.com/jbogard/MediatR)
- [Entity Framework Core Documentation](https://docs.microsoft.com/en-us/ef/core/)

---

**?? V? tr� t�i li?u**: `LmsMini.Api/docs/CleanArchitecture.md`
