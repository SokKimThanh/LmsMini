# Software Design Document (SDD) — LMS-Mini

> **Lưu ý:** Tài liệu này là phiên bản MD đã được biên tập/chỉnh sửa từ cả `SDD.docx` gốc và `SDD.md` hiện có. Mục tiêu: giữ đủ chi tiết để dev/QA/DevOps thực thi, đồng thời gọn, có ví dụ code, API contract rút gọn, DDL mẫu và appendices tham chiếu.

---

## Document Control

| Phiên bản | Ngày | Người biên tập | Nội dung chỉnh sửa |
|---:|---:|---|---|
| 1.2 | 26/08/2025 | Sok Kim Thanh | Bản cơ sở (docx)
| 1.3 | 03/09/2025 | Sok Kim Thanh | Hợp nhất nội dung, bổ sung Use Cases, API samples, DDL snippets, Outbox, NFRs, Deployment, Testing Strategy (MD hoàn chỉnh hơn bản rút gọn).

---

## Mục lục (tóm tắt)
1. Giới thiệu
2. Tổng quan hệ thống
3. Kiến trúc & Quyết định kiến trúc
4. Thiết kế cơ sở dữ liệu (logic + DDL mẫu)
5. Domain Design
6. Thiết kế API & Contract (OpenAPI rút gọn)
7. Thiết kế UI/UX (tóm tắt)
8. Luồng nghiệp vụ chính (sequence + code mẫu)
9. Bảo mật
10. Non-Functional Requirements
11. Deployment & Infrastructure
12. Error Handling & Exception Flow
13. Testing Strategy
14. Backup & DR
15. Coding style & Vận hành
16. Deliverables
17. Phụ lục (Appendices)

---

## 1. Giới thiệu
### 1.1 Mục tiêu
Mô tả thiết kế phần mềm cho hệ thống LMS-Mini: kiến trúc, domain model, API contract, luồng nghiệp vụ chính, dữ liệu, vận hành và kiểm thử.

### 1.2 Phạm vi
- Bao gồm: backend (API + domain + persistence), contract API, DB schema, sequence flows, NFRs, deployment guidance.
- Không bao gồm: pixel-perfect UI; cấu hình hạ tầng chi tiết nhà cung cấp (chỉ đưa patterns & tham khảo).

### 1.3 Độc giả
Backend/Frontend developers, QA, DevOps, Architects.

---

## 2. Tổng quan hệ thống (System Context)
Hệ thống bao gồm:
- Frontend (Blazor Server / SPA) gọi REST API
- Backend API (ASP.NET Core) triển khai Use Cases
- RDBMS (SQL Server / Azure SQL)
- Blob Storage (Azure Blob / S3)
- Background workers (containerized)
- Message broker (RabbitMQ / Azure Service Bus)

Stakeholders: Learner, Instructor, Admin, QA, DevOps.

---

## 3. Kiến trúc & Quyết định kiến trúc
### 3.1 Bản chất
Áp dụng **Clean Architecture**: Presentation → Application → Domain ← Infrastructure (implements ports). Sử dụng MediatR cho command/query orchestration, EF Core cho persistence.

### 3.2 Các quyết định quan trọng
- Lưu thời gian bằng UTC (IDateTimeProvider)
- Soft delete + global query filter (IsDeleted)
- Outbox pattern cho consistency DB ↔ Message Broker
- Specification pattern cho truy vấn phức tạp
- Idempotency-Key cho các POST có side-effects (enroll, submit)

---

## 4. Thiết kế cơ sở dữ liệu
### 4.1 Nguyên tắc audit & soft delete
Tất cả entity nghiệp vụ chính kế thừa BaseAuditable: CreatedAt (UTC), CreatedBy, UpdatedAt, UpdatedBy, DeletedAt, DeletedBy, IsDeleted (BIT). EF Core Global Query Filter áp dụng.

### 4.2 DDL mẫu (rút gọn) — SQL Server
```sql
CREATE TABLE Courses (
  Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
  Code NVARCHAR(50) NOT NULL,
  Title NVARCHAR(200) NOT NULL,
  Description NVARCHAR(MAX) NULL,
  Status NVARCHAR(20) NOT NULL DEFAULT('Draft'),
  CreatedBy UNIQUEIDENTIFIER NOT NULL,
  CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedBy UNIQUEIDENTIFIER NULL,
  UpdatedAt DATETIME2 NULL,
  IsDeleted BIT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX UQ_Courses_Code ON Courses(Code) WHERE IsDeleted = 0;

CREATE TABLE Enrollments (
  Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
  CourseId UNIQUEIDENTIFIER NOT NULL REFERENCES Courses(Id),
  UserId UNIQUEIDENTIFIER NOT NULL,
  StartAt DATETIME2 NOT NULL,
  EndAt DATETIME2 NULL,
  Status NVARCHAR(20) NOT NULL,
  CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  IsDeleted BIT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX UQ_Enrollments_CourseId_UserId ON Enrollments(CourseId, UserId) WHERE IsDeleted = 0;

-- Outbox
CREATE TABLE OutboxMessages (
  Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
  OccurredOn DATETIME2 NOT NULL,
  Type NVARCHAR(200) NOT NULL,
  Payload NVARCHAR(MAX) NOT NULL,
  ProcessedOn DATETIME2 NULL,
  RetryCount INT NOT NULL DEFAULT 0,
  Error NVARCHAR(MAX) NULL
);
```

### 4.3 Indexing & Concurrency
- Sử dụng filtered unique index cho các UQ tương tác soft-delete.
- RowVersion/ROWVERSION token cho các bảng có concurrency cao.

---

## 5. Domain Design
Entities chính: Course, Module, Lesson, Quiz, Question, Option, Enrollment, Progress, QuizAttempt, AttemptAnswer, Notification, FileAsset.

Aggregates: Course Aggregate (Course root), Quiz Aggregate (Quiz root), QuizAttempt Aggregate (QuizAttempt root).

Domain Events ví dụ: EnrollmentCreated, QuizSubmitted, LessonCompleted.

---

## 6. Thiết kế API & Contract (rút gọn OpenAPI)
### Nguyên tắc chung
- Base: `/api/v1`
- Response envelope:
```json
{ "success": true, "data": {...}, "error": null, "traceId": "..." }
```
- Idempotency-Key cho POST tác vụ viết
- ETag / If-Match cho PUT/patch

### Một số endpoint chính
- `GET /api/v1/courses` (paged)
- `GET /api/v1/courses/{id}`
- `POST /api/v1/courses` (CreateCourseRequest)
- `POST /api/v1/courses/{id}/enroll` (Idempotency-Key recommended)
- `POST /api/v1/quizzes/{id}/start`
- `POST /api/v1/quizzes/{id}/submit`

### Sample OpenAPI fragment (rút gọn)
```yaml
paths:
  /courses:
    get:
      summary: Get courses
    post:
      summary: Create course
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateCourseRequest'
components:
  schemas:
    CreateCourseRequest:
      type: object
      required: [code, title]
      properties:
        code: { type: string }
        title: { type: string }
        description: { type: string }
```

---

## 7. Thiết kế UI/UX (tóm tắt)
- Blazor Server UI (Razor Components)
- Accessibility: WCAG, ARIA attributes, keyboard navigation, focus management
- Component library: DataTable (server paging), Form (FluentValidation), QuizRunner (timer + autosave)
- Modal rules: use modal service, trap focus, warn on dirty form close

---

## 8. Luồng nghiệp vụ chính (Sequence Logic + code mẫu)
### Use Case: EnrollCourse (chi tiết)
**Preconditions:** user logged in, course exists and not deleted.
**Main flow:**
1. UI calls `POST /api/v1/courses/{id}/enroll` (kèm Idempotency-Key).
2. Controller -> EnrollCourseCommand -> Handler.
3. Handler checks `IEnrollmentRepository.IsUserEnrolledAsync` (specification)
4. If not, create Enrollment entity, add to repository, save UnitOfWork.
5. Raise Domain Event `EnrollmentCreated` → write Outbox record in same transaction.
6. Commit → background worker publishes outbox.

**C# handler (rút gọn):**
```csharp
public record EnrollCourseCommand(Guid CourseId, Guid UserId, string? IdempotencyKey): IRequest;
public class EnrollCourseCommandHandler : IRequestHandler<EnrollCourseCommand>
{
  public async Task<Unit> Handle(EnrollCourseCommand req, CancellationToken ct)
  {
    if (await _enrollmentRepo.IsUserEnrolledAsync(req.UserId, req.CourseId))
      throw new BusinessException("User already enrolled");

    var ent = new Enrollment(...);
    _enrollmentRepo.Add(ent);
    await _uow.SaveChangesAsync();

    _outboxService.Add(new OutboxMessage(...));
    return Unit.Value;
  }
}
```

### Use Case: Start & Submit Quiz (chi tiết)
- `POST /quizzes/{id}/start`: create QuizAttempt snapshot (questionSetVersion), return `attemptId`, `expireAt`.
- `POST /quizzes/{id}/submit`: validate attempt, compute score from snapshot, persist AttemptAnswers, update QuizAttempt + Progress, raise `QuizSubmitted` event.

**Scoring sample (domain):**
```csharp
public QuizResult CalculateScore(List<AnswerDto> answers) {
  int correct = Questions.Count(q => answers.Any(a => a.QuestionId==q.Id && a.OptionId==q.CorrectOptionId));
  double score = (double)correct / Questions.Count * 100;
  return new QuizResult(score, score >= PassingThreshold);
}
```

---

## 9. Quy tắc bảo mật
- RBAC: Admin / Instructor / Learner
- Authentication: ASP.NET Identity + JWT or cookie (Blazor Server)
- XSS: sanitize rich content server-side
- CSRF: anti-forgery tokens for cookie flows
- Headers: CSP, HSTS, X-Frame-Options, Referrer-Policy
- Audit: all important actions write audit entry

---

## 10. Non-Functional Requirements (NFRs)
- RPS target / latency SLOs to be agreed (ex: 99th pct latency < 500ms for read endpoints)
- Scalability: stateless API + DB scaling plan
- Availability: multi-AZ, health checks, readiness probes
- Observability: structured logs (Serilog), metrics and tracing (OpenTelemetry)

---

## 11. Deployment & Infrastructure View
- Recommended: containerized services on AKS/EKS or App Service + Azure SQL
- Blob storage: Azure Blob or S3 with signed URLs
- Broker: RabbitMQ / Azure Service Bus
- CI/CD: GitHub Actions (build → tests → push → deploy)

---

## 12. Error Handling & Exception Flow
- Centralized middleware to convert exceptions → envelope error codes (ERR_NOT_FOUND, ERR_VALIDATION, ERR_CONFLICT, ERR_INTERNAL)
- Include traceId in responses and logs

---

## 13. Testing Strategy
- Unit tests for domain logic (Quiz scoring, Enrollment rules)
- Integration tests (API + in-memory or real DB)
- Contract tests for API (OpenAPI-based)
- Load testing (k6), Security scanning (OWASP ZAP)

---

## 14. Backup & Disaster Recovery
- Full DB backup daily; transaction log every 15 minutes
- Blob Storage versioning + soft-delete
- RPO ≤ 15 minutes, RTO < 2 hours (tùy SLA)

---

## 15. Coding style & vận hành
- Namespaces: `Lms.Domain`, `Lms.Application`, `Lms.Infrastructure`, `Lms.Web`
- Async-only for IO; DI for services; keep Domain pure
- Use FluentValidation for input validation; AutoMapper for DTO mapping

---

## 16. Deliverables
Architecture diagrams, ERD + DDL, OpenAPI spec, DTO samples (Appendix C), test plan, deployment runbook.

---

## 17. Phụ lục (Appendices)
A. SQL DDL snippets (full) — see `appendices/ddl.sql` (tách file)
B. PlantUML sources for diagrams — see `appendices/plantuml/`
C. DTOs & Sample payloads — see `appendices/dtos.md`
D. Libraries & frameworks list (Serilog, MediatR, AutoMapper, FluentValidation, OpenTelemetry)

---

*Hết* — nếu bạn muốn tôi: (1) xuất file markdown sửa đổi (downloadable), (2) cập nhật tệp `SDD.md` gốc trực tiếp, hoặc (3) tách appendices thành file riêng (DDL, PlantUML, OpenAPI) tôi sẽ làm tiếp. 

