# Hướng dẫn triển khai luồng CreateCourse (UI → API → Application → Domain → Infrastructure → DB)

Tài liệu này hướng dẫn từng bước triển khai tính năng tạo khóa học (CreateCourse). Nội dung đã được biên tập để dễ quét (easy scanning) và có phần "Phần 2" chứa các bước tiếp theo cần thực hiện kèm mã mẫu.

---

## 0. Tóm tắt nhanh (1 phút)
- Luồng: UI → Controller → MediatR (Command) → Handler → Repository → DbContext → DB.
- Mục tiêu: POST /api/courses tạo course, trả 201 Created với Location tới GET /api/courses/{id}.

---

## 1. Chuẩn bị
- .NET SDK (9/8/7), EF Core, SQL Server hoặc SQLite
- Packages gợi ý:
  - MediatR, MediatR.Extensions.Microsoft.DependencyInjection
  - FluentValidation.AspNetCore
  - AutoMapper.Extensions.Microsoft.DependencyInjection
  - Microsoft.EntityFrameworkCore, Microsoft.EntityFrameworkCore.Design, Microsoft.EntityFrameworkCore.SqlServer (hoặc SQLite)

---

## 2. Cấu trúc gợi ý
- LmsMini.Api (Presentation)
- LmsMini.Application (Commands/Queries, DTOs, Interfaces, Validators, Mappings)
- LmsMini.Domain (Entities)
- LmsMini.Infrastructure (DbContext, Repositories)

---

## 3. Những gì đã có (quick status)
- CreateCourseCommand — OK
- CreateCourseCommandHandler — OK
- CreateCourseValidator — OK (và đã đăng ký)
- ICourseRepository + CourseRepository — OK
- Program.cs: đăng ký DbContext (connection string), MediatR, AutoMapper, FluentValidation, DI cho ICourseRepository — OK
- CoursesController: POST /api/courses — OK; GET endpoints gọi query/handler nhưng một số query/handler và DbContext còn thiếu


---

## 4. Các file/khái niệm bắt buộc để hoàn thiện
1. LmsDbContext (DbSet<Course>, cấu hình RowVersion)
2. CourseDto (DTO trả về cho query)
3. GetCoursesQuery / GetCourseByIdQuery + handlers
4. AutoMapper Profile (Course → CourseDto)
5. Sửa controller GetCourseById để nhận Guid id và gọi query
6. Tạo migration & cập nhật DB

---

## 5. Phần 2 — Hướng dẫn thực hiện tiếp theo (actionable, có mã mẫu)
Mục tiêu: thêm các file thiếu, build, tạo migration và test. Thực hiện theo thứ tự sau.

### Bước A — Tạo/hoàn thiện LmsDbContext (Infrastructure)
- File: `LmsMini.Infrastructure/LmsDbContext.cs`
- Việc cần làm: thêm `DbSet<Course> Courses` và cấu hình `RowVersion` để EF hiểu concurrency token.

Mẫu:

```csharp
using Microsoft.EntityFrameworkCore;
using LmsMini.Domain.Entities;

namespace LmsMini.Infrastructure;

public class LmsDbContext : DbContext
{
    public LmsDbContext(DbContextOptions<LmsDbContext> options) : base(options) { }

    public DbSet<Course> Courses { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Course>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Code)
                  .HasMaxLength(50)
                  .IsRequired();

            entity.Property(e => e.Title)
                  .HasMaxLength(200)
                  .IsRequired();

            entity.Property(e => e.Description)
                  .HasMaxLength(4000);

            entity.Property(e => e.RowVersion)
                  .IsRowVersion();

            // Optional: soft-delete filter
            // entity.HasQueryFilter(e => !e.IsDeleted);
        });
    }
}
```

> Lưu ý: chỉnh namespace nếu dự án của bạn khác.


### Bước B — Tạo CourseDto (Application)
- File: `LmsMini.Application/DTOs/CourseDto.cs`
- Mục đích: DTO nhẹ trả cho client thay vì entity trực tiếp.

Mẫu:

```csharp
using System;

namespace LmsMini.Application.DTOs;

public class CourseDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
```


### Bước C — Tạo Queries (Application)
- Files:
  - `LmsMini.Application/Features/Courses/Queries/GetCoursesQuery.cs`
  - `LmsMini.Application/Features/Courses/Queries/GetCourseByIdQuery.cs`

Mẫu:

```csharp
// GetCoursesQuery.cs
using MediatR;
using LmsMini.Application.DTOs;
using System.Collections.Generic;

namespace LmsMini.Application.Features.Courses.Queries;

public record GetCoursesQuery() : IRequest<List<CourseDto>>;

// GetCourseByIdQuery.cs
using MediatR;
using LmsMini.Application.DTOs;
using System;

namespace LmsMini.Application.Features.Courses.Queries;

public record GetCourseByIdQuery(Guid Id) : IRequest<CourseDto?>;
```


### Bước D — Tạo Handlers cho Queries (Application)
- Files:
  - `GetCoursesQueryHandler.cs`
  - `GetCourseByIdQueryHandler.cs`
- Handler lấy dữ liệu từ `ICourseRepository` và map bằng AutoMapper.

Mẫu:

```csharp
// GetCoursesQueryHandler.cs
using MediatR;
using AutoMapper;
using LmsMini.Application.DTOs;
using LmsMini.Application.Interfaces;

public class GetCoursesQueryHandler : IRequestHandler<GetCoursesQuery, List<CourseDto>>
{
    private readonly ICourseRepository _repo;
    private readonly IMapper _mapper;

    public GetCoursesQueryHandler(ICourseRepository repo, IMapper mapper)
    {
        _repo = repo;
        _mapper = mapper;
    }

    public async Task<List<CourseDto>> Handle(GetCoursesQuery request, CancellationToken cancellationToken)
    {
        var courses = await _repo.GetAllAsync(cancellationToken);
        return _mapper.Map<List<CourseDto>>(courses);
    }
}

// GetCourseByIdQueryHandler.cs
using MediatR;
using AutoMapper;
using LmsMini.Application.DTOs;
using LmsMini.Application.Interfaces;

public class GetCourseByIdQueryHandler : IRequestHandler<GetCourseByIdQuery, CourseDto?>
{
    private readonly ICourseRepository _repo;
    private readonly IMapper _mapper;

    public GetCourseByIdQueryHandler(ICourseRepository repo, IMapper mapper)
    {
        _repo = repo;
        _mapper = mapper;
    }

    public async Task<CourseDto?> Handle(GetCourseByIdQuery request, CancellationToken cancellationToken)
    {
        var course = await _repo.GetByIdAsync(request.Id, cancellationToken);
        if (course == null) return null;
        return _mapper.Map<CourseDto>(course);
    }
}
```


### Bước E — AutoMapper Profile (Application)
- File: `LmsMini.Application/Mappings/CourseProfile.cs`

Mẫu:

```csharp
using AutoMapper;
using LmsMini.Application.DTOs;
using LmsMini.Domain.Entities;

namespace LmsMini.Application.Mappings;

public class CourseProfile : Profile
{
    public CourseProfile()
    {
        CreateMap<Course, CourseDto>();
    }
}
```


### Bước F — Cập nhật Controller (Api)
- File: `LmsMini.Api/Controllers/CoursesController.cs`
- Việc cần làm: sửa `GetCourseById` để nhận `Guid id` và gọi `GetCourseByIdQuery`.

Mẫu:

```csharp
[HttpGet("{id:guid}")]
public async Task<IActionResult> GetCourseById(Guid id)
{
    var course = await _mediator.Send(new GetCourseByIdQuery(id));
    if (course == null) return NotFound();
    return Ok(course);
}
```


### Bước G — Build, Migrations & cập nhật DB
- Build project: `dotnet build` (hoặc build trong IDE)
- Tạo migration:
  `dotnet ef migrations add Init_Courses -s LmsMini.Api -p LmsMini.Infrastructure`
- Cập nhật DB:
  `dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure`


### Bước H — Kiểm thử nhanh
- Chạy API: `dotnet run --project LmsMini.Api`
- Test POST create:

```bash
curl -i -X POST http://localhost:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{"title":"Lập trình C# cơ bản","description":"Cho người mới bắt đầu"}'
```
- Kỳ vọng: 201 Created, Location header `/api/courses/{id}`; GET /api/courses và GET /api/courses/{id} trả dữ liệu đúng.


---

## 6. Checklist ngắn để tick khi xong
- [ ] LmsDbContext có DbSet<Course> và build ok
- [ ] CourseDto tồn tại
- [ ] GetCourses / GetCourseById queries + handlers tồn tại và build ok
- [ ] AutoMapper profile có mapping Course → CourseDto
- [ ] CoursesController.GetCourseById nhận Guid id và trả Ok/NotFound
- [ ] Migration tạo và database update thành công
- [ ] Test POST & GET hoạt động

---

## 7. Các đề xuất nâng cao (sau khi feature chạy ổn)
- Thêm DTO/DTO validation chi tiết, trả lỗi 400 rõ ràng
- Xử lý duplicate (409 Conflict) nếu cần unique constraint
- Thêm logging chi tiết trong handlers
- Viết unit tests cho handlers (mock ICourseRepository) và integration tests cho controller

---

Tôi có thể tạo các file mẫu (LmsDbContext, DTO, queries, handlers, mapping) trực tiếp trong repo và commit với thông điệp ngắn nếu bạn muốn. Chỉ cần xác nhận và tôi sẽ tạo các file đó.