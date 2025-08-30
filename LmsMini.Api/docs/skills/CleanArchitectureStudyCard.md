# Study Card: Lu?ng Backend API theo Clean Architecture (LmsMini)

M?c tiêu: nh? nhanh lu?ng UI ? API ? Application ? Domain ? Infrastructure ? DB, các khái ni?m chính và các bý?c th?c hành ð? t?o API CreateCourse mà không c?n ph? thu?c nhi?u vào AI.

---

## 1 trang tóm t?t (One?page)
- Lu?ng chính: UI ? Controller ? Command/Query ? MediatR ? Handler ? Domain (Entities/Rules) / Application (Interfaces) ? Repository impl (Infrastructure) ? LmsDbContext ? DB.
- Vai tr?: Controller = orchestration; Command/Query = DTO cho use?case; Handler = use?case logic; Repository interface ? Application; Implementation ? Infrastructure; Entity ? Domain.
- Conventions: files theo tính nãng: Application/Features/Courses/{Commands,Queries,Handlers}; Domain/Entities; Infrastructure/Repositories; Api/Controllers.
- HTTP: POST ? t?o Command tr? Guid + 201 Created (CreatedAtAction ? GetById).

---

## Thu?t ng? ng?n c?n nh? (12–20)
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

## 15 Flashcards (Q/A ng?n)
1. Q: Repository interface nên ð?t ? ðâu? A: Application.
2. Q: Implementation repository ð?t ? ðâu? A: Infrastructure.
3. Q: Command tr? lo?i g? khi t?o resource? A: Guid (ID).
4. Q: Handler nh?n g? t? MediatR? A: Command/Query instance.
5. Q: Controller có business logic không? A: Không — ch? orchestration.
6. Q: Dùng g? ð? validate Command? A: FluentValidation.
7. Q: Dùng g? ð? map Entity ? DTO? A: AutoMapper ho?c manual mapping.
8. Q: Làm sao tr? location resource m?i? A: CreatedAtAction(nameof(GetById), new { id = id }, null).
9. Q: AsNoTracking khi nào? A: Truy v?n ð?c ð? tãng hi?u nãng.
10. Q: RowVersion dùng ð? làm g?? A: Concurrency token.
11. Q: Soft delete flag tên thý?ng dùng? A: IsDeleted.
12. Q: MediatR giúp g?? A: Ð?nh tuy?n request t?i handler, gi?m coupling.
13. Q: Ðãng k? DI repository ? ðâu? A: Program.cs (Api project).
14. Q: Test handler nên mock g?? A: ICourseRepository.
15. Q: L?nh EF t?o migration? A: dotnet ef migrations add <Name> -p LmsMini.Infrastructure -s LmsMini.Api

---

## Checklist th?c hành nhanh (CreateCourse) — 7 bý?c
1. T?o Command file: Application/Features/Courses/Commands/CreateCourseCommand.cs
2. T?o Validator: Application/Validators/CreateCourseValidator.cs; vi?t rules.
3. T?o Handler: Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs (injected ICourseRepository).
4. T?o ICourseRepository trong Application/Interfaces và CourseRepository trong Infrastructure/Repositories.
5. Ðãng k? DI & MediatR & Validators trong Program.cs (Api): AddScoped, AddMediatR, AddValidatorsFromAssembly.
6. T?o Controller endpoint POST /api/courses g?i command qua _mediator.Send(command) và tr? CreatedAtAction.
7. Migration & update DB n?u c?n; test b?ng curl/Swagger.

---

## 3 ví d? HTTP (curl + JSON minimal)
1) POST create
```bash
curl -i -X POST http://localhost:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{"title":"L?p tr?nh C# cõ b?n","description":"Cho ngý?i m?i"}'
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
1. (T/F) Repository interface nên n?m ? Infrastructure. (F)
2. (MC) CreatedAtAction nên tr? t?i: A) GetList B) GetById C) Create ? (B)
3. (T/F) Use AsNoTracking() cho các truy v?n ð?c thý?ng xuyên. (T)
4. (MC) Concurrency token thý?ng là: A) IsDeleted B) RowVersion C) CreatedAt ? (B)
5. (T/F) FluentValidation ch?y trý?c handler khi ð? ðãng k?. (T)

---

## Mnemonic ð? nh? th? t? lu?ng
"UICMHRD" ? UI ? Controller ? MediatR (Command) ? Handler ? Repository ? DbContext
(Mnemonic: "Ui, Controllers Make Handlers Really Direct")

---

## Ghi chú dùng khi ôn
- H?c b?ng cách vi?t: t?o nhanh m?t API CreateCourse t? template theo checklist trên.
- Ôn flashcards 10 phút m?i ngày, th?c hành 1 feature/tu?n.
- Gi? file này làm study card: in 1 trang A4, dán c?nh màn h?nh.

---

B?n mu?n tôi lýu file này vào docs/skills/CleanArchitectureStudyCard.md và commit v?i mô t? ng?n không?
