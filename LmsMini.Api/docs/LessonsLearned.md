# Bài Học Đúc Kết Từ Clean Architecture

## Mục lục
- [Tổng quan](#tổng-quan)
- [Các bài học chính](#các-bài-học-chính)
- [Kiến trúc và tầng](#kiến-trúc-và-tầng)
- [Luồng hoạt động (UI → API → DB)](#luồng-hoạt-động-ui---api---db)
- [Ví dụ minh họa (có thể copy/paste)](#ví-dụ-minh-họa-có-thể-copypaste)
  - [Command + Handler](#command--handler)
  - [Query + Handler](#query--handler)
  - [Repository interface & implementation](#repository-interface--implementation)
  - [Entity & DTO](#entity--dto)
  - [Controller (điểm vào API)](#controller-điểm-vào-api)
  - [Đăng ký DI (Program.cs)](#đăng-ký-di-programcs)
  - [Validator (FluentValidation)](#validator-fluentvalidation)
- [Kiểm thử](#kiểm-thử)
- [Ghi chú & bước tiếp theo](#ghi-chú--bước-tiếp-theo)

---

## Tổng quan
Tài liệu này tóm tắt các bài học chính khi áp dụng Clean Architecture cho dự án LmsMini, kèm ví dụ minh họa luồng xử lý từ UI đến Database và các mẫu code có thể dùng làm tham khảo.

## Các bài học chính
- Phân tách rõ ràng các tầng (Presentation / Application / Domain / Infrastructure).
- Domain là trung tâm: không phụ thuộc framework.
- Sử dụng CQRS (MediatR) để tách command và query.
- Dependency Injection giúp quản lý phụ thuộc và dễ test.
- Document rõ ràng (README, docs) để developer mới nắm bắt nhanh.
- Viết Unit test và Integration test.
- Dùng mã hóa UTF-8 (không BOM) cho tài liệu.

## Kiến trúc và tầng
- LmsMini.Api (Presentation): Controllers, Swagger, Auth.
- LmsMini.Application: Commands/Queries, Handlers, DTOs, Interfaces.
- LmsMini.Domain: Entities, ValueObjects, Domain logic (không tham chiếu các tầng khác).
- LmsMini.Infrastructure: EF Core DbContext, Repositories, Implementations.
- LmsMini.Tests: Unit & Integration tests.

> Vị trí file tham khảo (ví dụ):
- CreateCourseCommand → LmsMini.Application/Features/Courses/Commands/CreateCourseCommand.cs
- CreateCourseCommandHandler → LmsMini.Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs
- ICourseRepository → LmsMini.Application/Interfaces/ICourseRepository.cs
- CourseRepository → LmsMini.Infrastructure/Repositories/CourseRepository.cs
- Course entity → LmsMini.Domain/Entities/Course.cs
- CoursesController → LmsMini.Api/Controllers/CoursesController.cs

## Luồng hoạt động (UI → API → DB)
1. Người dùng nhập form (Title, Description) và bấm Create.
2. Frontend gửi POST /api/courses với body JSON.
3. Controller nhận request, map vào Command và gửi qua MediatR.
4. Handler nhận Command, tạo Entity, gọi Repository.
5. Repository dùng EF Core để lưu vào DB.
6. DB ghi dữ liệu; handler trả về Id.
7. Controller trả response (201 Created) cho client.

![flow](https://github.com/user-attachments/assets/89bf43ab-101b-4fe7-bd4f-b9d28c4cb314)
![flow2](https://github.com/user-attachments/assets/c6c01084-8024-4de9-a473-f87665cc67ca)

---

## Ví dụ minh họa (có thể copy/paste)
Các ví dụ dưới đây là mẫu tối giản, bao gồm namespace/usings và lưu ý nơi đặt file.

### Command + Handler
File: LmsMini.Application/Features/Courses/Commands/CreateCourseCommand.cs
```csharp
using MediatR;

public class CreateCourseCommand : IRequest<Guid>
{
    public string Title { get; set; }
    public string Description { get; set; }
}
```

File: LmsMini.Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs
```csharp
using MediatR;
using System.Threading;
using System.Threading.Tasks;

public class CreateCourseCommandHandler : IRequestHandler<CreateCourseCommand, Guid>
{
    private readonly ICourseRepository _courseRepository;

    public CreateCourseCommandHandler(ICourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    public async Task<Guid> Handle(CreateCourseCommand request, CancellationToken cancellationToken)
    {
        var course = new Course
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Description = request.Description,
            CreatedAt = DateTime.UtcNow
        };

        await _courseRepository.AddAsync(course, cancellationToken);
        return course.Id;
    }
}
```

### Query + Handler
File: LmsMini.Application/Features/Courses/Queries/GetCoursesQuery.cs
```csharp
using MediatR;
using System.Collections.Generic;

public class GetCoursesQuery : IRequest<List<CourseDto>> { }
```

File: LmsMini.Application/Features/Courses/Handlers/GetCoursesQueryHandler.cs
```csharp
using MediatR;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

public class GetCoursesQueryHandler : IRequestHandler<GetCoursesQuery, List<CourseDto>>
{
    private readonly ICourseRepository _courseRepository;

    public GetCoursesQueryHandler(ICourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    public async Task<List<CourseDto>> Handle(GetCoursesQuery request, CancellationToken cancellationToken)
    {
        var courses = await _courseRepository.GetAllAsync(cancellationToken);
        return courses.Select(c => new CourseDto { Id = c.Id, Title = c.Title, Description = c.Description }).ToList();
    }
}
```

### Repository interface & implementation
File: LmsMini.Application/Interfaces/ICourseRepository.cs
```csharp
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public interface ICourseRepository
{
    Task AddAsync(Course course, CancellationToken cancellationToken = default);
    Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Course> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
```

File: LmsMini.Infrastructure/Repositories/CourseRepository.cs
```csharp
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public class CourseRepository : ICourseRepository
{
    private readonly LmsDbContext _context;

    public CourseRepository(LmsDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(Course course, CancellationToken cancellationToken = default)
    {
        _context.Courses.Add(course);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Courses.AsNoTracking().ToListAsync(cancellationToken);
    }

    public async Task<Course> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Courses.FindAsync(new object[] { id }, cancellationToken);
    }
}
```

### Entity & DTO
File: LmsMini.Domain/Entities/Course.cs
```csharp
public class Course
{
    public Guid Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

File: LmsMini.Application/DTOs/CourseDto.cs
```csharp
public class CourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
}
```

### Controller (điểm vào API)
File: LmsMini.Api/Controllers/CoursesController.cs
```csharp
using Microsoft.AspNetCore.Mvc;
using MediatR;
using System.Threading.Tasks;

[ApiController]
[Route("api/[controller]")]
public class CoursesController : ControllerBase
{
    private readonly IMediator _mediator;

    public CoursesController(IMediator mediator) => _mediator = mediator;

    [HttpPost]
    public async Task<IActionResult> CreateCourse([FromBody] CreateCourseCommand command)
    {
        var courseId = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetCourseById), new { id = courseId }, null);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetCourseById(Guid id)
    {
        var course = await _mediator.Send(new GetCourseByIdQuery { Id = id });
        if (course == null) return NotFound();
        return Ok(course);
    }

    [HttpGet]
    public async Task<IActionResult> GetCourses()
    {
        var courses = await _mediator.Send(new GetCoursesQuery());
        return Ok(courses);
    }
}
```

### Đăng ký DI (Program.cs)
```csharp
// Program.cs (excerpts)
builder.Services.AddScoped<ICourseRepository, CourseRepository>();
builder.Services.AddMediatR(typeof(CreateCourseCommand).Assembly);
builder.Services.AddAutoMapper(typeof(CourseProfile).Assembly);
builder.Services.AddValidatorsFromAssembly(typeof(CreateCourseValidator).Assembly);
```

### Validator (FluentValidation)
File: LmsMini.Application/Validators/CreateCourseValidator.cs
```csharp
using FluentValidation;

public class CreateCourseValidator : AbstractValidator<CreateCourseCommand>
{
    public CreateCourseValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(4000);
    }
}
```

---

## Kiểm thử
- Unit test: test domain rules, handlers (mock repository), validators.
- Integration test: test API endpoints (in-memory DB or test DB), repository implementations.

## Ghi chú & bước tiếp theo
- Sửa CreatedAtAction để trỏ đúng action trả resource theo id (đã cập nhật trong ví dụ).
- Thêm handling cho lỗi/duplicate (ví dụ trả 400/409) trong handler hoặc repository khi cần.
- Cân nhắc thêm AutoMapper profile ví dụ và test cases mẫu.
- Di chuyển các hình ảnh vào `LmsMini.Api/docs/assets` và dùng đường dẫn tương đối nếu muốn giữ trong repo.

---

**Tóm Lại:**
Tài liệu này đã được sắp xếp lại, gộp các phần trùng, chuẩn hoá ví dụ để có thể copy/paste vào project. Bạn muốn tôi: (A) commit thay đổi này, (B) thêm AutoMapper profile mẫu, hoặc (C) di chuyển ảnh vào thư mục docs/assets và cập nhật đường dẫn?
