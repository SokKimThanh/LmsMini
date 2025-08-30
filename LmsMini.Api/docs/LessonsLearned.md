# Bài Học Đúc Kết Từ Clean Architecture

## 1. **Tầm Quan Trọng Của Phân Tầng**
- Phân tách rõ ràng các tầng Presentation, Application, Domain, và Infrastructure giúp:
  - Dễ dàng mở rộng và bảo trì.
  - Đảm bảo mỗi tầng có trách nhiệm riêng biệt.
  - Giảm sự phụ thuộc giữa các tầng.

## 2. **Domain Là Trung Tâm**
- Domain Layer không phụ thuộc vào bất kỳ framework hay tầng nào khác.
- Chứa các quy tắc nghiệp vụ cốt lõi, đảm bảo tính đúng đắn của hệ thống.

## 3. **Sử Dụng CQRS Để Tối Ưu Hóa**
- Command và Query được tách biệt:
  - Command: Xử lý thay đổi trạng thái.
  - Query: Xử lý truy vấn dữ liệu.
- Giúp code dễ đọc, dễ kiểm thử và tối ưu hóa hiệu suất.

## 4. **Dependency Injection Là Chìa Khóa**
- Sử dụng Dependency Injection để quản lý sự phụ thuộc giữa các lớp.
- Giúp dễ dàng thay thế và kiểm thử các thành phần.

## 5. **Tài Liệu Rõ Ràng Là Cần Thiết**
- Một tài liệu chi tiết giúp:
  - Lập trình viên mới dễ dàng nắm bắt cấu trúc dự án.
  - Đảm bảo mọi người trong nhóm hiểu rõ cách tổ chức và quy tắc.

## 6. **Kiểm Thử Là Một Phần Không Thể Thiếu**
- Unit Test và Integration Test đảm bảo chất lượng code:
  - Unit Test: Kiểm tra logic nghiệp vụ.
  - Integration Test: Kiểm tra sự tương tác giữa các thành phần.

## 7. **Quy Ước Đặt Tên Rõ Ràng**
- Đặt tên file, class, và phương thức theo đúng chức năng:
  - Command: `CreateCourseCommand`
  - Query: `GetCoursesQuery`
  - DTO: `CourseDto`
- Giúp code dễ đọc và dễ hiểu.

## 8. **Sử Dụng Công Cụ Hiện Đại**
- Các công cụ như MediatR, AutoMapper, FluentValidation, và Serilog giúp tăng năng suất và giảm lỗi.

## 9. **Mã Hóa UTF-8 Không BOM**
- Đảm bảo tài liệu sử dụng mã hóa UTF-8 không BOM để tránh lỗi hiển thị ký tự đặc biệt.

## 🏗 Các tầng và nhiệm vụ
| Tầng | Nhiệm vụ chính | Tham chiếu |
|------|---------------|------------|
| **LmsMini.Api** (Presentation) | Web API, Controllers, Swagger, Auth | Application, Infrastructure |
| **LmsMini.Application** | CQRS, DTOs, Commands/Queries, Logic nghiệp vụ | Domain |
| **LmsMini.Domain** | Entities, Value Objects, Rules cốt lõi | _(không tham chiếu)_ |
| **LmsMini.Infrastructure** | DbContext, Repos, File/Email services | Domain |
| **LmsMini.Tests** | Unit + Integration tests | Application, Domain, Infrastructure |

## 📂 Cấu trúc chính (ghi nhớ theo cụm)
- `Api/Controllers` → điểm vào API  
- `Application/Features` → CQRS logic  
- `Domain/Entities` → quy tắc nghiệp vụ  
- `Infrastructure/Persistence` → EF Core DbContext, Migrations  
- `Tests/Unit` & `Tests/Integration` → kiểm thử

## 🔄 Luồng hoạt động (Data Flow)
1 Client gọi API.

2 Controller nhận request → tạo Command hoặc Query.

3 MediatR định tuyến đến Handler tương ứng.

4 Handler xử lý nghiệp vụ, gọi Repository nếu cần.

5 Repository truy cập DB.

6 Kết quả trả về qua DTO → Controller → Client.
<img width="1000" height="580" alt="image" src="https://github.com/user-attachments/assets/89bf43ab-101b-4fe7-bd4f-b9d28c4cb314" />
<img width="748" height="480" alt="image" src="https://github.com/user-attachments/assets/c6c01084-8024-4de9-a473-f87665cc67ca" />
<img width="1216" height="509" alt="image" src="https://github.com/user-attachments/assets/2a526c43-07a5-445c-ba4b-ae648ddef6b9" />
<img width="783" height="451" alt="image" src="https://github.com/user-attachments/assets/43d8820e-cda1-4a8e-a5e8-3e4776079409" />

## Ví dụ hoạt động Clean Architecture

### 1. **Ví dụ về Command và Handler**
#### Command: CreateCourseCommand
```csharp
public class CreateCourseCommand : IRequest<Guid>
{
    public string Title { get; set; }
    public string Description { get; set; }
}
```

#### Handler: CreateCourseCommandHandler
```csharp
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

        await _courseRepository.AddAsync(course);
        return course.Id;
    }
}
```

### 2. **Ví dụ về Query và Handler**
#### Query: GetCoursesQuery
```csharp
public class GetCoursesQuery : IRequest<List<CourseDto>>
{
}
```

#### Handler: GetCoursesQueryHandler
```csharp
public class GetCoursesQueryHandler : IRequestHandler<GetCoursesQuery, List<CourseDto>>
{
    private readonly ICourseRepository _courseRepository;

    public GetCoursesQueryHandler(ICourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    public async Task<List<CourseDto>> Handle(GetCoursesQuery request, CancellationToken cancellationToken)
    {
        var courses = await _courseRepository.GetAllAsync();
        return courses.Select(c => new CourseDto
        {
            Id = c.Id,
            Title = c.Title,
            Description = c.Description
        }).ToList();
    }
}
```

### 3. **Ví dụ về Repository Interface và Implementation**
#### Interface: ICourseRepository
```csharp
public interface ICourseRepository
{
    Task AddAsync(Course course);
    Task<List<Course>> GetAllAsync();
}
```

#### Implementation: CourseRepository
```csharp
public class CourseRepository : ICourseRepository
{
    private readonly LmsDbContext _context;

    public CourseRepository(LmsDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(Course course)
    {
        _context.Courses.Add(course);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Course>> GetAllAsync()
    {
        return await _context.Courses.ToListAsync();
    }
}
```

### 4. **Ví dụ về Entity**
```csharp
public class Course
{
    public Guid Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

### 5. **Ví dụ về DTO**
```csharp
public class CourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
}
```

### 6. **Ví dụ về Controller**
```csharp
[ApiController]
[Route("api/[controller]")]
public class CoursesController : ControllerBase
{
    private readonly IMediator _mediator;

    public CoursesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    public async Task<IActionResult> CreateCourse([FromBody] CreateCourseCommand command)
    {
        var courseId = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetCourses), new { id = courseId }, null);
    }

    [HttpGet]
    public async Task<IActionResult> GetCourses()
    {
        var courses = await _mediator.Send(new GetCoursesQuery());
        return Ok(courses);
    }
}
```

## 🧪 Chiến lược kiểm thử
- **Unit test**: Domain rules, Application handlers, Infra repos  
- **Integration test**: API endpoints, DB config, External services

## 💡 Best Practices
- **Domain**: Không phụ thuộc framework  
- **Controller**: Chỉ orchestration, không chứa business logic  
- **Handler**: 1 handler = 1 use case  
- **Repo**: Interface trong Application, implement ở Infrastructure  
- **DTO**: Chỉ để truyền data qua boundaries  
- **Tên chuẩn**: `CreateCourseCommand`, `GetCoursesQuery`, `CourseDto`…

## ⚙️ Lệnh thường dùng
```bash
dotnet restore       # Khôi phục packages
dotnet build         # Build solution
dotnet run --project LmsMini.Api   # Chạy API
dotnet test          # Chạy tests
``` 
## **Tóm Lại:**
- Clean Architecture không chỉ là một mô hình tổ chức code, mà còn là một triết lý giúp xây dựng phần mềm dễ bảo trì, dễ mở rộng và chất lượng cao.
