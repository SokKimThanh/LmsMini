# Hướng dẫn triển khai luồng CreateCourse (UI → API → Application → Domain → Infrastructure → DB)

Tài liệu này hướng dẫn từng bước triển khai tính năng tạo khóa học (CreateCourse) theo luồng UI → API → Application → Domain → Infrastructure → DB. Nội dung được biên tập, sửa lỗi và bổ sung so với bản gốc để dễ làm theo.

## Chuẩn bị
- Yêu cầu: .NET SDK (9/8/7), SQL Server hoặc SQLite, EF Core, MediatR, FluentValidation.
- Package (ví dụ .NET CLI):
  - MediatR, MediatR.Extensions.Microsoft.DependencyInjection
  - FluentValidation.AspNetCore
  - Microsoft.EntityFrameworkCore, Microsoft.EntityFrameworkCore.Design, Microsoft.EntityFrameworkCore.SqlServer (hoặc SQLite)

## Cấu trúc layer (gợi ý)
- LmsMini.Api (Presentation)
- LmsMini.Application (Application logic, Commands/Queries, Interfaces, DTOs, Validators)
- LmsMini.Domain (Entities, Domain rules)
- LmsMini.Infrastructure (EF Core, Repositories)

---

## Các bước triển khai
Các hướng dẫn bên dưới đi theo luồng và kèm snippet mã tương ứng (chỉ mang tính minh họa). Đảm bảo namespace và đường dẫn file phù hợp dự án của bạn.

### 1) Định nghĩa Entity (Domain)
File: LmsMini.Domain/Entities/CourseManagement/Course.cs
```csharp
public partial class Course
{
    public Guid Id { get; set; }
    public string Code { get; set; } = null!; // short unique code
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public string Status { get; set; } = "Draft";
    public Guid CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public byte[] RowVersion { get; set; } = null!; // concurrency token
}
```
Giải thích: entity phản ánh schema DB. Các rule phức tạp hơn (business validations) nên nằm trong Domain hoặc Domain Services.

---

### 2) Khai báo Repository interface (Application)
File: LmsMini.Application/Interfaces/ICourseRepository.cs
```csharp
public interface ICourseRepository
{
    Task AddAsync(Course course, CancellationToken cancellationToken = default);
    Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Course?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
```
Giải thích: interface đặt ở Application để handlers phụ thuộc vào abstraction, không phụ thuộc concrete implementation.

---

### 3) Triển khai Repository (Infrastructure)
File: LmsMini.Infrastructure/Repositories/CourseRepository.cs
```csharp
public class CourseRepository : ICourseRepository
{
    private readonly LmsDbContext _context;
    public CourseRepository(LmsDbContext context) => _context = context;

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
Giải thích: sử dụng EF Core qua LmsDbContext; dùng AsNoTracking cho các truy vấn đọc để tối ưu.

---

### 4) Tạo Command & Validator (Application)
File: LmsMini.Application/Features/Courses/Commands/CreateCourseCommand.cs
```csharp
public class CreateCourseCommand : IRequest<Guid>
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
```
File: LmsMini.Application/Validators/CreateCourseValidator.cs
```csharp
public class CreateCourseValidator : AbstractValidator<CreateCourseCommand>
{
    public CreateCourseValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(4000);
    }
}
```
Giải thích: Validator đảm bảo dữ liệu hợp lệ trước khi vào Handler. Đăng ký FluentValidation để nó chạy trong pipeline.

---

### 5) Viết Command Handler (Application)
File: LmsMini.Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs
```csharp
public class CreateCourseCommandHandler : IRequestHandler<CreateCourseCommand, Guid>
{
    private readonly ICourseRepository _courseRepository;

    public CreateCourseCommandHandler(ICourseRepository courseRepository) => _courseRepository = courseRepository;

    public async Task<Guid> Handle(CreateCourseCommand request, CancellationToken cancellationToken)
    {
        var course = new Course
        {
            Id = Guid.NewGuid(),
            Code = Guid.NewGuid().ToString("N").Substring(0, 8),
            Title = request.Title,
            Description = request.Description,
            Status = "Draft",
            CreatedBy = Guid.Empty, // TODO: set current user
            CreatedAt = DateTime.UtcNow,
            IsDeleted = false
        };

        await _courseRepository.AddAsync(course, cancellationToken);
        return course.Id;
    }
}
```
Giải thích: handler xây entity từ command, set mặc định rồi gọi repository. Trả về Id để controller trả 201 Created.

---

### 6) Đăng ký DI, MediatR, FluentValidation, DbContext (Api - Program.cs)
```csharp
builder.Services.AddDbContext<LmsDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(CreateCourseCommand).Assembly));
builder.Services.AddValidatorsFromAssembly(typeof(CreateCourseValidator).Assembly);

builder.Services.AddScoped<ICourseRepository, CourseRepository>();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
```
Giải thích: đảm bảo scan assembly Application cho MediatR, đăng ký validator và mapping interface→implementation.

---

### 7) Tạo API Controller (Presentation)
File: LmsMini.Api/Controllers/CoursesController.cs
```csharp
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
        // TODO: implement GetCourseByIdQuery and handler
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
Giải thích: controller không chứa business logic; chỉ orchestration và trả HTTP response thích hợp.

---

### 8) Migrations & cập nhật DB
- Tạo migration:
  `dotnet ef migrations add Init_Courses -s LmsMini.Api -p LmsMini.Infrastructure`
- Cập nhật database:
  `dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure`

Giải thích: `-s` chỉ startup project (Api), `-p` chỉ project chứa DbContext (Infrastructure).

---

### 9) Kiểm thử nhanh (run + curl)
- Chạy API: `dotnet run --project LmsMini.Api`
- Gửi request (ví dụ):
```bash
curl -X POST http://localhost:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{"title":"Lập trình C# cơ bản","description":"Cho người mới bắt đầu"}' -i
```
- Kỳ vọng: HTTP 201 Created, header Location: `/api/courses/{id}`; bản ghi mới có Status="Draft", Code 8 ký tự, CreatedAt UTC, IsDeleted=false.

---

## Mẹo & bước tiếp theo
- Thêm Query `GetCourseById` và `GetCourses` + handlers trả `CourseDto`.
- Dùng AutoMapper để map Entity → DTO.
- Xử lý duplicate/unique constraint (trả 409 Conflict) và validation business (nếu cần).
- Thêm unit tests cho handlers (mock ICourseRepository) và integration tests cho API.

---

Nội dung trên đã được biên tập để rõ ràng, chính xác và sát với cấu trúc mã hiện tại trong repository. Muốn tôi tạo file này trong docs và commit với mô tả ngắn không?