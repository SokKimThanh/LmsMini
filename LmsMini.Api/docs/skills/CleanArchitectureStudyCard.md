# Study Card: Luồng Backend API theo Clean Architecture (LmsMini)

Mục tiêu: nhớ nhanh luồng UI → API → Application → Domain → Infrastructure → DB, các khái niệm chính và các bước thực hành để tạo API CreateCourse mà không cần phụ thuộc nhiều vào AI.

---

## 1 trang tóm tắt (One‑page)
- Luồng chính: UI → Controller → Command/Query → MediatR → Handler → Domain (Entities/Rules) / Application (Interfaces) → Repository impl (Infrastructure) → LmsDbContext → DB.
- Vai trò: Controller = orchestration; Command/Query = DTO cho use‑case; Handler = use‑case logic; Repository interface ở Application; Implementation ở Infrastructure; Entity ở Domain.
- Conventions: files theo tính năng: Application/Features/Courses/{Commands,Queries,Handlers}; Domain/Entities; Infrastructure/Repositories; Api/Controllers.
- HTTP: POST → tạo Command trả Guid + 201 Created (CreatedAtAction → GetById).

---

## Thuật ngữ ngắn cần nhớ (12–20)
- Command, Query, Handler, IRequest<T>
- MediatR, Pipeline Behavior
- ICourseRepository (Application) vs CourseRepository (Infrastructure)
- DTO (CourseDto), Entity (Course)
- DbContext (LmsDbContext), AsNoTracking
- RowVersion, IsDeleted (soft delete)
- CancellationToken
- FluentValidation
- AutoMapper
- 201 Created / 404 / 400 / 409
- Unit Test, Integration Test

---

## 15 Flashcards (Q/A ngắn)
1. Q: Repository interface nên đặt ở đâu? A: Application.
2. Q: Implementation repository đặt ở đâu? A: Infrastructure.
3. Q: Command trả loại gì khi tạo resource? A: Guid (ID).
4. Q: Handler nhận gì từ MediatR? A: Command/Query instance.
5. Q: Controller có business logic không? A: Không — chỉ orchestration.
6. Q: Dùng gì để validate Command? A: FluentValidation.
7. Q: Dùng gì để map Entity → DTO? A: AutoMapper hoặc manual mapping.
8. Q: Làm sao trả location resource mới? A: CreatedAtAction(nameof(GetById), new { id = id }, null).
9. Q: AsNoTracking khi nào? A: Truy vấn đọc để tăng hiệu năng.
10. Q: RowVersion dùng để làm gì? A: Concurrency token.
11. Q: Soft delete flag tên thường dùng? A: IsDeleted.
12. Q: MediatR giúp gì? A: Định tuyến request tới handler, giảm coupling.
13. Q: Đăng ký DI repository ở đâu? A: Program.cs (Api project).
14. Q: Test handler nên mock gì? A: ICourseRepository.
15. Q: Lệnh EF tạo migration? A: dotnet ef migrations add <Name> -p LmsMini.Infrastructure -s LmsMini.Api

---

## Checklist thực hành nhanh (CreateCourse) — 7 bước
1. Tạo Command file: Application/Features/Courses/Commands/CreateCourseCommand.cs
2. Tạo Validator: Application/Validators/CreateCourseValidator.cs; viết rules.
3. Tạo Handler: Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs (injected ICourseRepository).
4. Tạo ICourseRepository trong Application/Interfaces và CourseRepository trong Infrastructure/Repositories.
5. Đăng ký DI & MediatR & Validators trong Program.cs (Api): AddScoped, AddMediatR, AddValidatorsFromAssembly.
6. Tạo Controller endpoint POST /api/courses gửi command qua _mediator.Send(command) và trả CreatedAtAction.
7. Migration & update DB nếu cần; test bằng curl/Swagger.

---

## 3 ví dụ HTTP (curl + JSON minimal)
1) POST create
```bash
curl -i -X POST http://localhost:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{"title":"Lập trình C# cơ bản","description":"Cho người mới"}'
```
Response: 201 Created, Header Location: /api/courses/{id}

2) GET list
```bash
curl http://localhost:5000/api/courses
```
Response: 200 OK, body: [ { "id":"...", "title":"..." } ]

3) GET by id
```bash
curl http://localhost:5000/api/courses/{id}
```
Response: 200 OK or 404 NotFound

---

## 5 câu quiz nhanh (self-check)
1. (T/F) Repository interface nên nằm ở Infrastructure. (F)
2. (MC) CreatedAtAction nên trỏ tới: A) GetList B) GetById C) Create → (B)
3. (T/F) Use AsNoTracking() cho các truy vấn đọc thường xuyên. (T)
4. (MC) Concurrency token thường là: A) IsDeleted B) RowVersion C) CreatedAt → (B)
5. (T/F) FluentValidation chạy trước handler khi đã đăng ký. (T)

---

## Mnemonic để nhớ thứ tự luồng
"UICMHRD" → UI → Controller → MediatR (Command) → Handler → Repository → DbContext
(Mnemonic: "Ui, Controllers Make Handlers Really Direct")

---

## Ghi chú dùng khi ôn
- Học bằng cách viết: tạo nhanh một API CreateCourse từ template theo checklist trên.
- Ôn flashcards 10 phút mỗi ngày, thực hành 1 feature/tuần.
- Giữ file này làm study card: in 1 trang A4, dán cạnh màn hình.

