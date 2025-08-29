# Clean Architecture - LmsMini

T�i li?u t�m t?t c�ch t? ch?c d? �n LmsMini theo Clean Architecture, c�c tham chi?u ch�nh, l?nh c?n thi?t v� v? tr� file �? d? n?m b?t v� ph�t tri?n.

## M?c ti�u
- T�ch bi?t r? r�ng Presentation / Application / Domain / Infrastructure
- D? d�ng m? r?ng, test v� deploy
- Quy �?c v? tr� file gi�p developer nhanh ch�ng t?m ��?c code li�n quan

## Projects (gi?i th�ch)
- LmsMini.Api (Presentation)
  - Web API, Controllers, Swagger, Authentication
  - Tham chi?u: LmsMini.Application, LmsMini.Infrastructure
- LmsMini.Application (Application)
  - CQRS (MediatR), DTOs, Commands, Queries, Handlers, Business Rules
  - Tham chi?u: LmsMini.Domain
- LmsMini.Domain (Domain)
  - Entities, Value Objects, Domain Services, Enums, Exceptions
  - Kh�ng tham chi?u project kh�c
- LmsMini.Infrastructure (Infrastructure)
  - EF Core DbContext, Repositories, File storage, Email adapters, Migrations
  - Tham chi?u: LmsMini.Domain
- LmsMini.Tests (Unit / Integration tests)
  - Ki?m th? c�c l?p trong Application / Domain / Infrastructure (th�ng qua interfaces)

## Recommended Project References
- LmsMini.Api -> LmsMini.Application, LmsMini.Infrastructure
- LmsMini.Application -> LmsMini.Domain
- LmsMini.Infrastructure -> LmsMini.Domain
- LmsMini.Tests -> LmsMini.Application, LmsMini.Domain, LmsMini.Infrastructure

## C?u tr�c th� m?c chi?n l�?c
(S?p x?p theo nh�m ch?c n�ng �? d? �i?u h�?ng)

LmsMini/
?? LmsMini.Api/
?  ?? Controllers/            # API Controllers
?  ?? DTOs/                   # DTOs cho presentation (n?u c?n)
?  ?? Configuration/          # Settings, DI registration modules
?  ?? docs/                   # T�i li?u - n�i file n�y n?m
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

Ghi ch�: �?t entities scaffolded t? database v�o LmsMini.Domain/Entities v� DbContext v�o LmsMini.Infrastructure/Persistence.

## Key files & v? tr�
- DbContext: LmsMini.Infrastructure/Persistence/LmsDbContext.cs
- Entities: LmsMini.Domain/Entities/*.cs
- Controllers: LmsMini.Api/Controllers/*.cs
- Commands/Handlers: LmsMini.Application/Commands/**, LmsMini.Application/Handlers/**
- AutoMapper profiles: LmsMini.Application/Mapping/
- FluentValidation validators: LmsMini.Application/Validators/

## Dependency Injection & Program.cs (example)
- ��ng k? DbContext, MediatR, AutoMapper, FluentValidation, Serilog trong Program.cs

V� d? (t�m t?t):
```csharp
// Services registration
services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
services.AddMediatR(cfg => cfg.RegisterServicesFromAssemblies(typeof(SomeCommand).Assembly));
services.AddAutoMapper(typeof(MappingProfile).Assembly);
services.AddValidatorsFromAssembly(typeof(SomeValidator).Assembly);
```

## C�c l?nh th�?ng d�ng
- Restore packages:
  - dotnet restore
- Build:
  - dotnet build
- Run API:
  - dotnet run --project LmsMini.Api
- Run tests:
  - dotnet test

- Th�m package (v� d?):
  - dotnet add LmsMini.Application package MediatR
  - dotnet add LmsMini.Application package AutoMapper
  - dotnet add LmsMini.Application package FluentValidation
  - dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.SqlServer
  - dotnet add LmsMini.Infrastructure package Microsoft.EntityFrameworkCore.Design

- Scaffold t? database (Database-first) (�? c� h�?ng d?n trong docs/ScaffoldFromDatabase.md):
  - dotnet ef dbcontext scaffold "Server=.\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;" Microsoft.EntityFrameworkCore.SqlServer --output-dir ../LmsMini.Domain/Entities --context-dir ../LmsMini.Infrastructure/Persistence --context LmsDbContext --namespace LmsMini.Domain.Entities --use-database-names --no-onconfiguring --project ./LmsMini.Infrastructure/LmsMini.Infrastructure.csproj --startup-project ./LmsMini.Api/LmsMini.Api.csproj

- Migrations (Code-first workflow):
  - dotnet ef migrations add InitialCreate --project LmsMini.Infrastructure --startup-project LmsMini.Api
  - dotnet ef database update --project LmsMini.Infrastructure --startup-project LmsMini.Api

## Guidance - How it works (flow)
1. Client -> Controller (LmsMini.Api)
2. Controller t?o Command/Query -> g?i cho MediatR
3. Handler trong LmsMini.Application x? l? logic, t��ng t�c v?i Repository interfaces
4. Repository concrete trong LmsMini.Infrastructure t��ng t�c v?i LmsDbContext
5. Domain entities ? LmsMini.Domain ch?a c�c quy t?c nghi?p v? c?t l?i
6. K?t qu? tr? v? DTO cho Controller -> Response

## Testing & Separation
- Unit test business rules in Application / Domain using mocked repositories (IRepository interfaces)
- Integration tests can run against in-memory or test SQL instance using real LmsDbContext

## Best practices
- Keep Domain free of framework dependencies
- Application defines contracts (interfaces) that Infrastructure implements
- Use DTOs for crossing process boundaries
- Centralize cross-cutting concerns in Application Behaviors (validation, logging, transaction)
- Keep Controllers thin � orchestration only

---
T�i li?u n�y n?m t?i: LmsMini.Api/docs/CleanArchitecture.md
