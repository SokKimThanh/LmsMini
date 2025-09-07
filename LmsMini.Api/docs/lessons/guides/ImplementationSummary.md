# Tóm tắt triển khai — LmsMini (ghi chú ngắn + giải thích cho trẻ em)

Tài liệu này tóm tắt mã nguồn và cấu hình trong repo, giải thích tổng quan bằng tiếng Việt ngắn gọn. Ở mỗi mục có phần giải thích kỹ thuật và phần giải thích đơn giản dành cho học sinh lớp 5.

---

## 1. Cấu trúc dự án (tổng quan)
- LmsMini.Api — phần trình bày / Web API (Program.cs, controllers)
- LmsMini.Application — logic ứng dụng (Commands, Queries, DTOs, handlers, mappings)
- LmsMini.Domain — các thực thể miền (Course, Quiz, ...)
- LmsMini.Infrastructure — hạ tầng dữ liệu (DbContext), repositories
- LmsMini.Tests — bộ test

Giải thích cho học sinh lớp 5: Hãy tưởng tượng đây là một trường học — mỗi thư mục là một phòng: phòng hiển thị (Api), phòng quy tắc (Domain), phòng làm việc (Application), phòng lưu hồ sơ (Infrastructure).

---

## 2. Program.cs (LmsMini.Api)
Kỹ thuật (ngắn):
- Khởi tạo web host và đăng ký dịch vụ: Serilog, DbContext, DI (ICourseRepository...), AutoMapper, MediatR, FluentValidation, Swagger, controllers và middleware pipeline.
- Dòng quan trọng:
  - builder.Services.AddDbContext<LmsDbContext>(...)
  - builder.Services.AddScoped<ICourseRepository, CourseRepository>()
  - builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies())
  - builder.Services.AddMediatR(AppDomain.CurrentDomain.GetAssemblies())

Giải thích cho học sinh lớp 5: Program.cs giống như cô hiệu trưởng chuẩn bị mọi thứ trước giờ học — giáo viên, thư viện, và quy tắc.

Lưu ý về mã hóa (encoding):
- File markdown và tệp nguồn tiếng Việt nên lưu bằng UTF-8 (without BOM) để tránh lỗi ký tự hiển thị như ô vuông hoặc ký tự lạ khi hiển thị trên một số hệ thống.
- Trong repo bạn có thể thêm file .gitattributes để khuyến nghị encoding cho các file văn bản; mình đề xuất thêm file .gitattributes ở thư mục gốc để chuẩn hóa.

---

## 3. MediatR: Request và Handler
Kỹ thuật:
- Dùng IRequest<T> cho message (Commands/Queries). Handler (IRequestHandler<TRequest,TResponse>) thực thi logic.
- Ví dụ: GetCoursesQuery (record) và GetCoursesQueryHandler (dùng repository + AutoMapper để trả DTO).

Giải thích cho học sinh lớp 5: MediatR giống người đưa thư — bạn viết một tờ giấy yêu cầu, người đưa thư đưa đến đúng người làm.

Lưu ý:
- Mỗi IRequest thường cần một handler đăng ký; nếu không có handler, IMediator.Send sẽ lỗi.
- Nếu cần nhiều bên phản ứng cùng lúc, dùng INotification (pub/sub).

---

## 4. AutoMapper (IMapper & Profile)
Kỹ thuật:
- AutoMapper giúp chuyển đổi giữa entity và DTO, giảm mã gán thủ công.
- Cần tạo Profile với CreateMap<TSource, TDestination>() (ví dụ Course -> CourseDto).
- AddAutoMapper(...) sẽ quét assembly để tìm các Profile.

Giải thích cho học sinh lớp 5: AutoMapper là một máy copy thông minh — Profile là hướng dẫn cách copy từ hộp A sang hộp B.

Cảnh báo:
- Nếu không có Profile tương ứng, gọi _mapper.Map<T>() sẽ gây lỗi runtime.
- Nên dùng ProjectTo cho truy vấn EF Core để SQL thực hiện projection khi cần.

---

## 5. DTO (Data Transfer Object)
Kỹ thuật:
- DTO (ví dụ CourseDto) là đối tượng trả về cho client; tách biệt entity thực tế khỏi hợp đồng API.

Giải thích cho học sinh lớp 5: DTO giống một tấm thẻ ghi thông tin để chia sẻ — an toàn để chia sẻ mà không lộ dữ liệu nhạy cảm.

---

## 6. Repository và DbContext
Kỹ thuật:
- ICourseRepository là abstraction; CourseRepository triển khai với LmsDbContext.
- LmsDbContext chứa DbSet<Course> và cấu hình mapping (RowVersion, soft-delete, v.v.).
- RowVersion dùng để tránh tranh chấp khi 2 người cùng sửa (optimistic concurrency).

Giải thích cho học sinh lớp 5: Repository giống người thủ thư biết cách lấy và cất sách; DbContext giống giá sách và danh mục.

Lưu ý:
- Nếu dùng soft-delete, áp dụng global query filter để ẩn bản ghi đã xóa.
- Cấu hình RowVersion để EF Core xử lý concurrency token đúng.

---

## 7. FluentValidation
Kỹ thuật:
- FluentValidation dùng để kiểm tra dữ liệu input trước khi handler xử lý. Đăng ký validator qua AddValidatorsFromAssemblies.

Giải thích cho học sinh lớp 5: FluentValidation giống cô giáo kiểm tra bài trước khi nộp — nếu thiếu thông tin thì cô sẽ báo lỗi.

---

## 8. Serilog & Logging
Kỹ thuật:
- Serilog thay logger mặc định, ghi log theo cấu trúc. Dùng UseSerilog() và UseSerilogRequestLogging().

Giải thích cho học sinh lớp 5: Serilog giống nhật ký của trường, ghi lại mọi việc đã xảy ra.

---

## 9. Swagger / OpenAPI
Kỹ thuật:
- Swagger tạo tài liệu API và UI thử nghiệm (AddSwaggerGen).

Giải thích cho học sinh lớp 5: Swagger giống bảng hướng dẫn cho lập trình viên biết có những dịch vụ nào và dùng thế nào.

Lưu ý: ở môi trường production cần ẩn/sửa cấu hình để không lộ thông tin nhạy cảm.

---

## 10. Ví dụ: Luồng GetCourseById (từ đầu đến cuối)
1. Controller nhận GET /api/courses/{id} và tạo GetCourseByIdQuery rồi gọi _mediator.Send(query).
2. MediatR tìm handler tương ứng và gọi Handle.
3. Handler gọi _courseRepository.GetByIdAsync(id) để lấy entity.
4. Handler dùng _mapper.Map<CourseDto>(course) để trả DTO.
5. Controller trả 200 OK hoặc 404 NotFound nếu null.

Giải thích cho học sinh lớp 5: Học sinh hỏi thư viện (controller), người đưa thư (MediatR) đưa tờ yêu cầu cho thủ thư (handler), thủ thư lấy sách (repository), viết tóm tắt thông tin ra tấm thẻ (DTO) và trả lại.

Lưu ý:
- Cần có CourseProfile để AutoMapper hoạt động; nếu không sẽ lỗi runtime.
- Handler nên trả kiểu nullable và controller chuyển thành NotFound khi cần.

---

## 11. Hỏi đáp đơn giản cho học sinh (FAQ ngắn)
- Tại sao dùng record cho query? Vì ngắn gọn và không thay đổi (immutable). (Giải thích cho lớp 5: một tờ giấy nhỏ không thể sửa)
- Có cần handler cho mỗi request không? Có — nếu không có handler, người đưa thư không biết đưa đến ai.
- AutoMapper tự map chăng? Chỉ khi bạn có "bản hướng dẫn" (Profile) và đã đăng ký nó.

---

## 12. Checklist hành động (cần thêm / kiểm tra)
- [ ] LmsDbContext có DbSet<Course> và RowVersion.
- [ ] CourseDto tồn tại và có trường cần thiết.
- [ ] AutoMapper Profile cho Course -> CourseDto có và nằm trong assembly được quét.
- [ ] Queries & Handlers (GetCoursesQuery, GetCourseByIdQuery và handlers) đã tồn tại.
- [ ] Repository có các phương thức GetAllAsync, GetByIdAsync.
- [ ] Program.cs đã đăng ký DI, AutoMapper, MediatR, FluentValidation, Serilog.
- [ ] Tạo và chạy EF migrations sau khi model hoàn chỉnh.

Giải thích cho học sinh lớp 5: Đánh dấu từng mục như checklist để biết đã sẵn sàng.

---

## 13. Tài liệu tham khảo trong repo
- docs/for-kids.md — giải thích rất đơn giản cho trẻ em
- docs/ImplementCreateCourseGuide.md — hướng dẫn thực hiện CreateCourse từng bước
- docs/SDD.txt — Software Design Document (chi tiết)

---

## 14. Lưu ý về encoding và cách sửa lỗi ký tự
- Nếu thấy tiếng Việt hiển thị sai (ký tự lạ, dấu hỏi, ô vuông), hãy đảm bảo file được lưu dưới mã hóa UTF-8 without BOM.
- Trong Windows/VSCode, dùng "Save with Encoding -> UTF-8" hoặc chạy PowerShell script sau để ghi lại file bằng UTF-8 no BOM:

```powershell
$p = 'LmsMini.Api\docs\guides\ImplementationSummary.md'
$c = Get-Content $p -Raw
[System.IO.File]::WriteAllText($p, $c, New-Object System.Text.UTF8Encoding($false))
```

- Để chuẩn hóa cho toàn repo, nên thêm file `.gitattributes` ở thư mục gốc khuyến nghị encoding và EOL cho file .md và .cs.

---

Nếu bạn muốn mình tự tạo các file thiếu (CourseDto, CourseProfile, LmsDbContext skeleton) mình có thể tạo ngay. Mình cũng có thể chuyển mã hóa file này sang UTF-8 without BOM tự động nếu bạn muốn mình thực hiện.

