# Clean Architecture - LmsMini

Tài li?u tóm t?t cách t? ch?c d? án LmsMini theo Clean Architecture, các tham chi?u chính, l?nh c?n thi?t và v? trí file ð? d? n?m b?t và phát tri?n.

## M?c tiêu
- Tách bi?t r? ràng Presentation / Application / Domain / Infrastructure
- D? dàng m? r?ng, test và deploy
- Quy ý?c v? trí file giúp developer nhanh chóng t?m ðý?c code liên quan

## Projects (gi?i thích)
- LmsMini.Api (Presentation)
  - Web API, Controllers, Swagger, Authentication
  - Tham chi?u: LmsMini.Application, LmsMini.Infrastructure
- LmsMini.Application (Application)
  - CQRS (MediatR), DTOs, Commands, Queries, Handlers, Business Rules
  - Tham chi?u: LmsMini.Domain
- LmsMini.Domain (Domain)
  - Entities, Value Objects, Domain Services, Enums, Exceptions
  - Không tham chi?u project khác
- LmsMini.Infrastructure (Infrastructure)
  - EF Core DbContext, Repositories, File storage, Email adapters, Migrations
  - Tham chi?u: LmsMini.Domain
- LmsMini.Tests (Unit / Integration tests)
  - Ki?m th? các l?p trong Application / Domain / Infrastructure (thông qua interfaces)

## Recommended Project References
- LmsMini.Api -> LmsMini.Application, LmsMini.Infrastructure
- LmsMini.Application -> LmsMini.Domain
- LmsMini.Infrastructure -> LmsMini.Domain
- LmsMini.Tests -> LmsMini.Application, LmsMini.Domain, LmsMini.Infrastructure

## C?u trúc thý m?c chi?n lý?c
(S?p x?p theo nhóm ch?c nãng ð? d? ði?u hý?ng)

LmsMini/
?? LmsMini.Api/
?  ?? Controllers/            # API Controllers
?  ?? DTOs/                   # DTOs cho presentation (n?u c?n)
?  ?? Configuration/          # Settings, DI registration modules
?  ?? docs/                   # Tài li?u - nõi file này n?m
?? LmsMini.Application/
?  ?? Common/                 # Shared utilities, interfaces
?  ?? Commands/               # Command handlers (Write)
?  ?? Queries/                # Query handlers (Read)
?  ?? DTOs/                   # Contract DTOs between layers
?  ?? Behaviors/              # MediatR pipeline behaviors (validation, logging)
?  ?? Mapping/                # AutoMapper profiles
?? LmsMini.Domain/
?  ?? Entities/               # Entity classes (Course, Module, Lesson, ...)
?  ?? ValueObjects/
?  ?? Exceptions/
?? LmsMini.Infrastructure/
?  ?? Persistence/
?  ?  ?? LmsDbContext.cs      # EF Core DbContext
?  ?  ?? Migrations/
?  ?? Repositories/           # Concrete repository implementations
?  ?? Services/               # File storage, Email, External integrations
?? LmsMini.Tests/
   ?? Unit/
   ?? Integration/

Ghi chú: ð?t entities scaffolded t? database vào LmsMini.Domain/Entities và DbContext vào LmsMini.Infrastructure/Persistence.

## Key files & v? trí
- DbContext: LmsMini.Infrastructure/Persistence/LmsDbContext.cs
- Entities: LmsMini.Domain/Entities/*.cs
- Controllers: LmsMini.Api/Controllers/*.cs
- Commands/Handlers: LmsMini.Application/Commands/**, LmsMini.Application/Handlers/**
- AutoMapper profiles: LmsMini.Application/Mapping/
- FluentValidation validators: LmsMini.Application/Validators/

## Dependency Injection & Program.cs (example)
- Ðãng k? DbContext, MediatR, AutoMapper, FluentValidation, Serilog trong Program.cs

Ví d? (tóm t?t):
```csharp
// Services registration
services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
services.AddMediatR(cfg => cfg.RegisterServicesFromAssemblies(typeof(SomeCommand).Assembly));
services.AddAutoMapper(typeof(MappingProfile).Assembly);
services.AddValidatorsFromAssembly(typeof(SomeValidator).Assembly);
```

## Các l?nh thý?ng dùng
- Restore packages:
  - dotnet restore
- Build:
  - dotnet build
- Run API:
  - dotnet run --project LmsMini.Api
- Run tests:
  - dotnet test

- Thêm package (ví d?):
  - dotnet add LmsMini.Application package MediatR
  - dotnet add LmsMini.Application package AutoMapper
  - dotnet add LmsMini.Application package FluentValidation
  - dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.SqlServer
  - dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.Design

- Scaffold t? database (Database-first) (ð? có hý?ng d?n trong docs/ScaffoldFromDatabase.md):
  - dotnet ef dbcontext scaffold "Server=.\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;" Microsoft.EntityFrameworkCore.SqlServer --output-dir ../LmsMini.Domain/Entities --context-dir ../LmsMini.Infrastructure/Persistence --context LmsDbContext --namespace LmsMini.Domain.Entities --use-database-names --no-onconfiguring --project ./LmsMini.Infrastructure/LmsMini.Infrastructure.csproj --startup-project ./LmsMini.Api/LmsMini.Api.csproj

- Migrations (Code-first workflow):
  - dotnet ef migrations add InitialCreate --project LmsMini.Infrastructure --startup-project LmsMini.Api
  - dotnet ef database update --project LmsMini.Infrastructure --startup-project LmsMini.Api

## Guidance - How it works (flow)
1. Client -> Controller (LmsMini.Api)
2. Controller t?o Command/Query -> g?i cho MediatR
3. Handler trong LmsMini.Application x? l? logic, týõng tác v?i Repository interfaces
4. Repository concrete trong LmsMini.Infrastructure týõng tác v?i LmsDbContext
5. Domain entities ? LmsMini.Domain ch?a các quy t?c nghi?p v? c?t l?i
6. K?t qu? tr? v? DTO cho Controller -> Response

## Testing & Separation
- Unit test business rules in Application / Domain using mocked repositories (IRepository interfaces)
- Integration tests can run against in-memory or test SQL instance using real LmsDbContext

## Best practices
- Keep Domain free of framework dependencies
- Application defines contracts (interfaces) that Infrastructure implements
- Use DTOs for crossing process boundaries
- Centralize cross-cutting concerns in Application Behaviors (validation, logging, transaction)
- Keep Controllers thin – orchestration only

---
Tài li?u này n?m t?i: LmsMini.Api/docs/CleanArchitecture.md
