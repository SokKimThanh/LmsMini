# Bài Học Đúc Kết Từ Clean Architecture

## Mục lục
- [Tổng quan](#tổng-quan)
- [Các bài học chính](#các-bài-học-chính)
- [Kiến trúc và tầng](#kiến-trúc-và-tầng)
- [Luồng hoạt động (UI → API → DB)](#luồng-hoạt-động-ui---api---db)
- [Ví dụ minh họa sát với mã nguồn (kèm giải thích)](#ví-dụ-minh-họa-sát-với-mã-nguồn-kèm-giải-thích)
  - [CreateCourseCommand (Application)](#createcoursecommand-application)
  - [CreateCourseCommandHandler (Application)](#createcoursecommandhandler-application)
  - [ICourseRepository (Application interface)](#icourserepository-application-interface)
  - [CourseRepository (Infrastructure implementation)](#courserepository-infrastructure-implementation)
  - [Course entity (Domain)](#course-entity-domain)
  - [CourseDto (Application DTO)](#coursedto-application-dto)
  - [CoursesController (API)](#coursescontroller-api)
  - [CreateCourseValidator (FluentValidation)](#createcoursevalidator-fluentvalidation)
- [Kiểm thử](#kiểm-thử)
- [Ghi chú & bước tiếp theo](#ghi-chú--bước-tiếp-theo)

---

## Tổng quan
Tài liệu này tóm tắt các bài học chính và cung cấp mã mẫu sát với luồng xử lý hiện có trong project, kèm giải thích ngắn sau mỗi đoạn mã để dễ theo dõi.

## Các bài học chính
- Phân tách rõ ràng các tầng (Presentation / Application / Domain / Infrastructure).
- Domain là trung tâm: không phụ thuộc framework.
- Sử dụng CQRS (MediatR) để tách command và query.
- Dependency Injection giúp quản lý phụ thuộc và dễ kiểm thử.

## Kiến trúc và tầng
- LmsMini.Api (Presentation): Controllers, Swagger, Auth.
- LmsMini.Application: Commands/Queries, Handlers, DTOs, Interfaces, Validators.
- LmsMini.Domain: Entities, ValueObjects, Domain logic.
- LmsMini.Infrastructure: EF Core DbContext, Repositories.

## Luồng hoạt động (UI → API → DB)
1. UI gửi POST /api/courses với JSON body.
2. Controller nhận request, map vào CreateCourseCommand và _Send_ qua MediatR.
3. CreateCourseCommandHandler xử lý, tạo Course entity và gọi ICourseRepository.AddAsync.
4. CourseRepository lưu entity vào DB qua LmsDbContext.
5. Handler trả về Id; Controller trả 201 Created cho client.

![flow](https://github.com/user-attachments/assets/89bf43ab-101b-4fe7-bd4f-b9d28c4cb314)
![flow2](https://github.com/user-attachments/assets/c6c01084-8024-4de9-a473-f87665cc67ca)
<img width="1288" height="613" alt="image" src="https://github.com/user-attachments/assets/9896b6e9-5cd4-4e15-ba75-ac86dfe14d58" />

---

## Ví dụ minh họa sát với mã nguồn (kèm giải thích)

### CreateCourseCommand (Application)
File: LmsMini.Application/Features/Courses/Commands/CreateCourseCommand.cs
```csharp
using MediatR;

namespace LmsMini.Application.Features.Courses.Commands;

public class CreateCourseCommand : IRequest<Guid>
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
```
Giải thích: Command là DTO tại lớp Application chứa dữ liệu từ client. `IRequest<Guid>` cho biết handler trả về Guid (ID khóa học mới).

### CreateCourseCommandHandler (Application)
File: LmsMini.Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs
```csharp
using MediatR;
using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;

namespace LmsMini.Application.Features.Courses.Handlers;

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
            Code = Guid.NewGuid().ToString("N").Substring(0, 8),
            Title = request.Title,
            Description = request.Description,
            Status = "Draft",
            CreatedBy = Guid.Empty, // TODO: set current user id
            CreatedAt = DateTime.UtcNow,
            IsDeleted = false
        };

        await _courseRepository.AddAsync(course, cancellationToken);
        return course.Id;
    }
}
```
Giải thích: Handler thực hiện business logic đơn giản: khởi tạo entity, gán giá trị mặc định và gọi repository để lưu. CancellationToken được truyền xuống repository.

### ICourseRepository (Application interface)
File: LmsMini.Application/Interfaces/ICourseRepository.cs
```csharp
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LmsMini.Domain.Entities;

namespace LmsMini.Application.Interfaces;

public interface ICourseRepository
{
    Task AddAsync(Course course, CancellationToken cancellationToken = default);
    Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Course?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
```
Giải thích: Interface định nghĩa các thao tác cần có cho repository; đặt trong Application để các handler phụ thuộc vào abstraction.

### CourseRepository (Infrastructure implementation)
File: LmsMini.Infrastructure/Repositories/CourseRepository.cs
```csharp
using Microsoft.EntityFrameworkCore;
using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;

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

    public async Task<Course?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Courses.FindAsync(new object[] { id }, cancellationToken);
    }
}
```
Giải thích: Triển khai thực tế sử dụng EF Core DbContext (LmsDbContext) để truy xuất/ghi dữ liệu.

### Course entity (Domain)
File: LmsMini.Domain/Entities/CourseManagement/Course.cs
```csharp
public partial class Course
{
    public Guid Id { get; set; }
    public string Code { get; set; } = null!;
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public string Status { get; set; } = null!;
    public Guid CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public byte[] RowVersion { get; set; } = null!;
}
```
Giải thích: Entity phản ánh schema DB (RowVersion, soft delete flag, audit fields). Các business rule nên được đặt trong Domain hoặc Domain Services.

### CourseDto (Application DTO)
File: LmsMini.Application/DTOs/CourseDto.cs
```csharp
public class CourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
```
Giải thích: DTO dùng để trả về dữ liệu cho client; tách biệt với entity để tránh leak domain internals.

### CoursesController (API)
File: LmsMini.Api/Controllers/CoursesController.cs
```csharp
using Microsoft.AspNetCore.Mvc;
using MediatR;
using LmsMini.Application.Features.Courses.Commands;
using LmsMini.Application.Features.Courses.Queries;

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
        // Example placeholder: use a GetCourseByIdQuery to retrieve a single course DTO
        return NotFound();
    }

    [HttpGet]
    public async Task<IActionResult> GetCourses()
    {
        var courses = await _mediator.Send(new GetCoursesQuery());
        return Ok(courses);
    }
}
```
Giải thích: Controller làm orchestration: nhận request, tạo command/query và gửi tới MediatR; không chứa business logic.

### CreateCourseValidator (FluentValidation)
File: LmsMini.Application/Validators/CreateCourseValidator.cs
```csharp
using FluentValidation;
using LmsMini.Application.Features.Courses.Commands;

public class CreateCourseValidator : AbstractValidator<CreateCourseCommand>
{
    public CreateCourseValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(4000);
    }
}
```
Giải thích: Validator chạy trước handler (via pipeline) để đảm bảo dữ liệu đầu vào hợp lệ và trả BadRequest nếu không.

---

## Kiểm thử
- Unit test: Test handlers với mock ICourseRepository; test validator rules.
- Integration test: Khởi chạy API với test DB (in-memory hoặc SQL), gọi endpoint để kiểm tra flow end-to-end.

## Ghi chú & bước tiếp theo
- Thêm handler/query cho GetCourseById và mapping (AutoMapper) nếu cần.
- Đăng ký DI trong Program.cs: ICourseRepository -> CourseRepository, MediatR, FluentValidation, AutoMapper.
- Bổ sung xử lý lỗi (duplicate code → trả 409) và audit user id.
 