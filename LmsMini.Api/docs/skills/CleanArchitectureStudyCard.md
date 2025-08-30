# Study Card: Lu?ng Backend API theo Clean Architecture (LmsMini)

M?c ti�u: nh? nhanh lu?ng UI ? API ? Application ? Domain ? Infrastructure ? DB, c�c kh�i ni?m ch�nh v� c�c b�?c th?c h�nh �? t?o API CreateCourse m� kh�ng c?n ph? thu?c nhi?u v�o AI.

---

## 1 trang t�m t?t (One?page)
- Lu?ng ch�nh: UI ? Controller ? Command/Query ? MediatR ? Handler ? Domain (Entities/Rules) / Application (Interfaces) ? Repository impl (Infrastructure) ? LmsDbContext ? DB.
- Vai tr?: Controller = orchestration; Command/Query = DTO cho use?case; Handler = use?case logic; Repository interface ? Application; Implementation ? Infrastructure; Entity ? Domain.
- Conventions: files theo t�nh n�ng: Application/Features/Courses/{Commands,Queries,Handlers}; Domain/Entities; Infrastructure/Repositories; Api/Controllers.
- HTTP: POST ? t?o Command tr? Guid + 201 Created (CreatedAtAction ? GetById).

---

## Thu?t ng? ng?n c?n nh? (12�20)
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
1. Q: Repository interface n�n �?t ? ��u? A: Application.
2. Q: Implementation repository �?t ? ��u? A: Infrastructure.
3. Q: Command tr? lo?i g? khi t?o resource? A: Guid (ID).
4. Q: Handler nh?n g? t? MediatR? A: Command/Query instance.
5. Q: Controller c� business logic kh�ng? A: Kh�ng � ch? orchestration.
6. Q: D�ng g? �? validate Command? A: FluentValidation.
7. Q: D�ng g? �? map Entity ? DTO? A: AutoMapper ho?c manual mapping.
8. Q: L�m sao tr? location resource m?i? A: CreatedAtAction(nameof(GetById), new { id = id }, null).
9. Q: AsNoTracking khi n�o? A: Truy v?n �?c �? t�ng hi?u n�ng.
10. Q: RowVersion d�ng �? l�m g?? A: Concurrency token.
11. Q: Soft delete flag t�n th�?ng d�ng? A: IsDeleted.
12. Q: MediatR gi�p g?? A: �?nh tuy?n request t?i handler, gi?m coupling.
13. Q: ��ng k? DI repository ? ��u? A: Program.cs (Api project).
14. Q: Test handler n�n mock g?? A: ICourseRepository.
15. Q: L?nh EF t?o migration? A: dotnet ef migrations add <Name> -p LmsMini.Infrastructure -s LmsMini.Api

---

## Checklist th?c h�nh nhanh (CreateCourse) � 7 b�?c
1. T?o Command file: Application/Features/Courses/Commands/CreateCourseCommand.cs
2. T?o Validator: Application/Validators/CreateCourseValidator.cs; vi?t rules.
3. T?o Handler: Application/Features/Courses/Handlers/CreateCourseCommandHandler.cs (injected ICourseRepository).
4. T?o ICourseRepository trong Application/Interfaces v� CourseRepository trong Infrastructure/Repositories.
5. ��ng k? DI & MediatR & Validators trong Program.cs (Api): AddScoped, AddMediatR, AddValidatorsFromAssembly.
6. T?o Controller endpoint POST /api/courses g?i command qua _mediator.Send(command) v� tr? CreatedAtAction.
7. Migration & update DB n?u c?n; test b?ng curl/Swagger.

---

## 3 v� d? HTTP (curl + JSON minimal)
1) POST create
```bash
curl -i -X POST http://localhost:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{"title":"L?p tr?nh C# c� b?n","description":"Cho ng�?i m?i"}'
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

## 5 c�u quiz nhanh (self-check)
1. (T/F) Repository interface n�n n?m ? Infrastructure. (F)
2. (MC) CreatedAtAction n�n tr? t?i: A) GetList B) GetById C) Create ? (B)
3. (T/F) Use AsNoTracking() cho c�c truy v?n �?c th�?ng xuy�n. (T)
4. (MC) Concurrency token th�?ng l�: A) IsDeleted B) RowVersion C) CreatedAt ? (B)
5. (T/F) FluentValidation ch?y tr�?c handler khi �? ��ng k?. (T)

---

## Mnemonic �? nh? th? t? lu?ng
"UICMHRD" ? UI ? Controller ? MediatR (Command) ? Handler ? Repository ? DbContext
(Mnemonic: "Ui, Controllers Make Handlers Really Direct")

---

## Ghi ch� d�ng khi �n
- H?c b?ng c�ch vi?t: t?o nhanh m?t API CreateCourse t? template theo checklist tr�n.
- �n flashcards 10 ph�t m?i ng�y, th?c h�nh 1 feature/tu?n.
- Gi? file n�y l�m study card: in 1 trang A4, d�n c?nh m�n h?nh.

---

B?n mu?n t�i l�u file n�y v�o docs/skills/CleanArchitectureStudyCard.md v� commit v?i m� t? ng?n kh�ng?
