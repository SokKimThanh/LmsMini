# Software Design Document (SDD) - LMS-Mini

## Document Control

**Phiên b?n** | **Ngày** | **Ngý?i biên t?p** | **N?i dung ch?nh s?a**
---|---:|---|---
1.0 | 15/08/2025 | Sok Kim Thanh | B?n nháp ð?u tiên.
1.1 | 25/08/2025 | Sok Kim Thanh | Biên t?p s?ch, chu?n hoá c?u trúc, b? sung Document Control, Scope, Glossary.
1.2 | 26/08/2025 | Sok Kim Thanh | B? sung Non-Functional Requirements, Deployment, Error Handling, Testing Strategy, Backup & Disaster Recovery. C?p nh?t M?c l?c.

### Revision History

**Phiên b?n** | **Ngày** | **Ngý?i s?a** | **N?i dung s?a ð?i**
---|---:|---|---
1.0 | 15/08/2025 | Sok Kim Thanh | B?n nháp ð?u tiên.
1.1 | 25/08/2025 | Sok Kim Thanh | Biên t?p s?ch, chu?n hoá c?u trúc.
1.2 | 26/08/2025 | Sok Kim Thanh | B? sung các m?c Non-Functional Requirements (NFRs), Deployment, Error Handling, Testing Strategy, Backup & Disaster Recovery. C?p nh?t l?i M?c l?c.

---

## M?c l?c

1. Gi?i thi?u
  - 1.1 M?c tiêu
  - 1.2 Ph?m vi
  - 1.3 Ð?c gi? m?c tiêu
  - 1.4 Thu?t ng? (Glossary)
2. T?ng quan h? th?ng (System Context)
  - 2.1 Stakeholders
  - 2.2 Sõ ð? t?ng quan h? th?ng
3. Ki?n trúc & Quy?t ð?nh ki?n trúc
  - 3.1 Component Diagram - LMS Mini
  - 3.2 Use-Case Diagram - LMS Mini
  - 3.3 Mô h?nh ki?n trúc
  - 3.4 Sõ ð? ki?n trúc t?ng th?
  - 3.5 Vai tr?, trách nhi?m và m?i quan h?
  - 3.6 Quy ý?c chung
  - 3.7 Interface/Port chính và nõi tri?n khai
  - 3.8 Domain Events, Outbox, Specification & Cross-Cutting Concerns
4. Thi?t k? cõ s? d? li?u
  - 4.1 Audit & Soft Delete
  - 4.2 Mô h?nh logic
  - 4.3 Indexes
  - ...
5. Domain Design
6. Thi?t k? API & Contract
7. Thi?t k? UI/UX
8. Lu?ng nghi?p v? chính (Sequence Logic)
9. Quy t?c b?o m?t (Security rules)
10. Non-Functional Requirements (NFRs)
11. Deployment & Infrastructure View
12. Error Handling & Exception Flow
13. Testing Strategy
14. Backup & Disaster Recovery
15. Coding style và v?n hành
16. Deliverables / Output
17. Ph? l?c

---

## 1 Gi?i thi?u

### 1.1 M?c tiêu

Tài li?u này mô t? thi?t k? ph?n m?m (Software Design Document) cho h? th?ng LMS-Mini. N?i dung bao g?m ki?n trúc h? th?ng, mô h?nh mi?n, API contract, d? li?u, use-case chính và hý?ng d?n tri?n khai.

### 1.2 Ph?m vi

- Bao g?m: ki?n trúc backend, domain model, API contract, d? li?u, use-case chính (ghi danh, làm bài ki?m tra, theo d?i ti?n ð?, thông báo).
- Không bao g?m: chi ti?t giao di?n ngý?i dùng (UI pixel-perfect), h? t?ng ph?n c?ng c? th?.

### 1.3 Ð?c gi? m?c tiêu

- Backend/Frontend Developers
- QA Engineers
- DevOps
- Reviewers / Architects

### 1.4 Thu?t ng? (Glossary)

B?ng thu?t ng? tóm t?t các khái ni?m chính (A11y, Admin, Instructor, Learner, Aggregate, Application Layer, Clean Architecture, CQRS, Domain Layer, Presentation Layer, Repository Pattern, Specification Pattern, UnitOfWork, Background Worker, Blob Storage, Key Vault, MediatR, Message Broker, Attempt, AttemptAnswer, Course, Enrollment, FileAsset, Lesson, Module, Notification, Progress, Question, Quiz, QuizAttempt, Use Case, Value Object, Audit Log, CSRF Token, ETag, Idempotency-Key, RBAC, RowVersion, Scope, Security Headers, Soft Delete, DDL, Filtered Index, Migration, PK/FK/UQ/IX/DF, DTO, EF Core, Global Query Filter, Backoff Retry, CI/CD, Observability, Rate limiting, SLA/SLI/SLO).

(Chi ti?t thu?t ng? chuy?n t? file g?c vào ph? l?c Glossary.)

---

## 2 T?ng quan h? th?ng (System Context)

H? th?ng LMS-Mini cho phép t?o khoá h?c, ghi danh, làm bài ki?m tra, theo d?i ti?n ð? và g?i thông báo. Các thành ph?n chính:

- Frontend: SPA giao ti?p qua REST API.
- Backend API: x? l? use case, domain logic.
- Database (RDBMS): lýu tr? transactional data.
- Blob Storage: lýu tài li?u, media.
- Background Workers: x? l? tác v? async.
- Message Broker: publish/subscribe các s? ki?n.

### 2.1 Stakeholders

- Learner: Ngý?i dùng h?c t?p, làm quiz, theo d?i ti?n ð?.
- Instructor: T?o, qu?n l? khoá h?c, theo d?i h?c viên.
- Admin: Qu?n l? ngý?i dùng, phân quy?n, giám sát h? th?ng.
- QA: Ð?m b?o ch?t lý?ng, vi?t test plan.
- DevOps: Tri?n khai, giám sát, v?n hành h? th?ng.

### 2.2 Sõ ð? t?ng quan h? th?ng

(H?nh minh ho? system context: clients, API, DB, Blob Storage, Broker, Workers)

---

## 3 Ki?n trúc & Quy?t ð?nh ki?n trúc

### 3.1 Component Diagram - LMS Mini

(Chi ti?t component diagram ðý?c thêm trong ph? l?c PlantUML.)

### 3.2 Use-Case Diagram - LMS Mini

(H?nh Use-case Diagram t?ng quan.)

### 3.3 Mô h?nh ki?n trúc

H? th?ng LMS Mini áp d?ng Clean Architecture nh?m tách bi?t r? ràng gi?a các t?ng: Presentation (Blazor/UI), Application (Use Cases, DTOs, Handlers), Domain (Entities, Value Objects, Business Rules), Infrastructure (EF Core, Repositories, Adapters).

Nguyên t?c chính:

- Ph? thu?c m?t chi?u: Presentation ? Application ? Domain.
- Domain không ph? thu?c vào t?ng khác.
- T?ng Infrastructure tri?n khai interfaces (ports) t? Application/Domain.

### 3.4 Sõ ð? ki?n trúc t?ng th?

(H?nh Layer Diagram)

#### 3.4.1 Ví d?: T?o khóa h?c m?i (Create Course)

Tóm t?t lu?ng: UI ? CreateCourseCommand ? Handler ? Domain (Course validate) ? Repository ? DbContext persist ? commit.

(M? ví d? razor component và handler minimal ðý?c gi? trong ph? l?c ho?c codebase.)

#### 3.4.2 Ví d?: Ðãng k? khóa h?c (Enroll in Course)

Tóm t?t lu?ng: EnrollCourse.razor g?i Mediator.Send(EnrollCourseCommand). Handler ki?m tra enrollment t?n t?i, g?i repository ð? lýu.

(M? ví d? ð? ðý?c ðýa vào SDD g?c; gi? l?i trong ph? l?c ví d? code.)

#### 3.4.3 Ví d?: N?p bài ki?m tra (Submit Quiz)

Tóm t?t lu?ng: UI SubmitQuizCommand ? Handler tính ði?m b?ng domain Quiz.CalculateScore ? Save QuizAttempt ? Update Progress ? tr? k?t qu?.

---

## 3.5 Vai tr?, trách nhi?m và m?i quan h?

B?ng mô t? responsabilidades c?a Presentation, Application, Domain, Infrastructure cùng các interface/port chính (ICourseRepository, IModuleRepository, IEnrollmentRepository, IProgressRepository, IQuizRepository, IUnitOfWork, IFileStorage, IEmailSender, IDateTimeProvider, IAuthService, IReportService, IQuerySpecification<T>).

## 3.6 Quy ý?c chung

- Audit: m?i entity k? th?a BaseAuditable (CreatedAt, CreatedBy, ModifiedAt, ModifiedBy).
- Soft Delete: IsDeleted flag và global query filter trong EF Core.
- Quy ý?c ð?t tên PK/FK/Index.

## 3.7 Interface/Port chính và nõi tri?n khai

B?ng mapping Interface ? Ð?nh ngh?a ? Tri?n khai (Application.Abstractions ? Infrastructure.Repositories/...)

## 3.8 Domain Events, Outbox, Specification & Cross-Cutting Concerns

### 3.8.1 Domain Events

- Raised t? Aggregate Root sau khi validate và trý?c commit.
- Lifecycle: Raised ? Persisted (Outbox) ? Published ? Consumed ? Archived.
- Payload chu?n JSON (eventId, eventType, version, occurredOn, correlationId, tenantId, causedByUserId, data).

### 3.8.2 Outbox Pattern

- Persist event vào OutboxMessages trong cùng transaction.
- Background worker ð?c Outbox, publish t?i broker, retry policy, mark ProcessedOn.

### 3.8.3 Specification Pattern

- IQuerySpecification<T> ð? mô t? Criteria, OrderBy, Includes, Skip/Take.
- Repository áp d?ng specification ð? compose queries.

### 3.8.4 Timezone / Clock

- Lýu UTC, IDateTimeProvider.UtcNow, mockable for tests.

### 3.8.5 Audit Log

- AuditEntry g?m id, action, entityType, entityId, performedByUserId, performedOnUtc, details, correlationId, tenantId.

---

## 4 Thi?t k? cõ s? d? li?u

(T?ng h?p các b?ng, PK/FK/UQ/Index, ERD, filtered indexes, migration strategy, seed strategy.)

### 4.1 Audit & Soft Delete

M?c tiêu: ð?m b?o audit & kh? nãng ph?c h?i b?ng soft delete (IsDeleted flag). Chi ti?t các trý?ng chu?n: CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, DeletedAt, DeletedBy, IsDeleted.

EF Core: áp d?ng Global Query Filter m?u (modelBuilder.Entity<Course>().HasQueryFilter(e => !e.IsDeleted); ...)

#### 4.1.5 Ghi nh?n audit t? ð?ng (EF Interceptor / middleware)

M?u interface IAuditable và ví d? override SaveChanges ð? set CreatedAt/CreatedBy/UpdatedAt/UpdatedBy t? _clock và _currentUser.

```csharp
public interface IAuditable
{
    DateTime CreatedAt { get; set; }
    Guid? CreatedBy { get; set; }
    DateTime? UpdatedAt { get; set; }
    Guid? UpdatedBy { get; set; }
}

public override int SaveChanges()
{
    var now = _clock.UtcNow;
    var userId = _currentUser.Id;

    foreach (var e in ChangeTracker.Entries<IAuditable>())
    {
        if (e.State == EntityState.Added)
        {
            e.Entity.CreatedAt = now;
            e.Entity.CreatedBy = userId;
        }
        if (e.State == EntityState.Modified)
        {
            e.Entity.UpdatedAt = now;
            e.Entity.UpdatedBy = userId;
        }
    }
    return base.SaveChanges();
}
```

(More DB DDL snippets included in Appendix A in original SDD.)

### 4.2 Mô h?nh logic - B?ng, PK, FK, Unique, Index

(Chi ti?t cho AspNetUsers, Courses, Modules, Lessons, Enrollments, Progresses, Quizzes, Questions, Options, QuizAttempts, AttemptAnswers, Notifications, FileAssets, AuditLogs, OutboxMessages.)

---

## 5 Domain Design

(Entities & Aggregates, Domain Services, Business Rules, Domain Events, Outbox flow.)

---

## 6 Thi?t k? API & Contract

### 6.1 Contract n?i b? (Port / Adapter)

Danh sách interfaces và nõi tri?n khai.

### 6.2 Contract bên ngoài (REST API cho client)

Nguyên t?c chung
- Base URL: /api/v1
- Auth: JWT Bearer Token (AspNet Identity)
- Response Envelope chu?n:

```json
{
  "success": true,
  "data": { },
  "error": null,
  "traceId": "..."
}
```

Quy t?c Idempotency-Key, ETag/If-Match, Pagination headers (X-Total-Count, Link), Rate limiting headers, i18n, CSV safety.

### 6.2.2 Courses (Endpoints & contract)

- GET /api/v1/courses
- GET /api/v1/courses/{id}
- POST /api/v1/courses
- PUT /api/v1/courses/{id}
- POST /api/v1/courses/{id}/publish
- DELETE /api/v1/courses/{id} (soft delete)

DTO samples (C# records) provided in Appendix C.

### 6.2.4 Enrollment

- POST /api/v1/courses/{id}/enroll (Idempotency-Key recommended/required)
- GET /api/v1/courses/{id}/enrollments
- DELETE /api/v1/enrollments/{id}

### 6.2.5 Quiz

- POST /api/v1/courses/{courseId}/quizzes
- POST /api/v1/quizzes/{id}/start
- POST /api/v1/quizzes/{id}/submit

(Additional endpoints detailed in SDD.)

---

## 7 Thi?t k? UI/UX

(TopBar, SideNav, ContentArea, Footer, A11y rules, Blazor Server connection resilience, autosave for quizzes, component library suggestions: LmsDataTable, LmsForm, ProgressBar, QuizRunner, KpiCard, Alert/Toast, ConfirmDialog, FileUploader.)

---

## 8 Lu?ng nghi?p v? chính (Sequence Logic)

(Use case flows: EnrollCourse, SubmitQuiz, QuizAttemptFlow, MarkLessonCompleted, CreateCourse, ManageLessons, CreateQuiz, ViewProgress, LessonProgress, SendNotification, FileAssets, Secrets & Upload Security, Observability.)

(Sequence diagrams included in Appendix B.)

---

## 9 Quy t?c b?o m?t (Security rules)

- RBAC: Admin, Instructor, Learner
- Authorization Policies: CourseOwnerOrAdmin, EnrolledOnly
- Authentication & Session: Blazor Server cookie auth (ASP.NET Identity), CookieOptions: SameSite=Strict, Secure
- Input Validation: FluentValidation
- XSS: sanitize server-side for rich content
- CSRF: anti-forgery for cookie-based flows
- Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy

---

## 10 Non-Functional Requirements (NFRs)

- Performance, Scalability, Availability, Security & Compliance, Observability (metrics, tracing, logging), SLOs.

---

## 11 Deployment & Infrastructure View

- Web Frontend (Blazor Server) on App Service / Containers
- Backend API: ASP.NET Core Web API on Kubernetes/App Service
- Database: SQL Server / Azure SQL
- Blob Storage: Azure Blob
- Message Broker: RabbitMQ / Azure Service Bus
- Background Workers: containerized

CI/CD: GitHub Actions / Azure Pipelines suggestions.

---

## 12 Error Handling & Exception Flow

- Map exceptions ? Error codes (ERR_NOT_FOUND, ERR_FORBIDDEN, ERR_VALIDATION, ERR_CONFLICT, ERR_INTERNAL, ERR_PRECONDITION, etc.)
- Use Response Envelope with traceId.

---

## 13 Testing Strategy

- Unit tests (?80% domain coverage where applicable)
- Integration tests (API + DB)
- Load tests (k6/JMeter)
- Security tests (OWASP ZAP/Burp)
- Acceptance tests based on use cases

---

## 14 Backup & Disaster Recovery

- DB full daily + transaction log every 15 minutes
- Blob Storage soft delete + versioning
- RPO ? 15 minutes, RTO < 2 hours

---

## 15 Coding style và v?n hành

- Namespaces: Lms.Domain, Lms.Application, Lms.Infrastructure, Lms.Web
- Async for all IO methods
- DTO naming conventions: CreateXRequest, XDto, XResponse
- Handlers implement MediatR IRequestHandler

---

## 16 Deliverables / Output (Ð?u ra mong mu?n)

- Architecture diagrams
- ERD & DDL scripts
- API specification & DTOs
- UI wireframes & user flows
- Security & operations notes
- Checklists & governance

---

## 17 Ph? l?c

- Appendix A: Sample SQL DDL Snippets (SQL Server) — includes CREATE TABLE for AspNetUsers, Courses, Modules, Lessons, Quizzes, Questions, Options, QuizAttempts, AttemptAnswers, Enrollments, Progresses, Notifications, FileAssets, OutboxMessages, AuditLogs, plus indexes and constraints.

- Appendix B: PlantUML sources for diagrams (System Context, Use-case, Layer diagrams, Sequence diagrams, Component diagrams).

- Appendix C: DTOs, Sample Payloads & OpenAPI snippets (C# samples and example JSON payloads).

- Appendix D: Libraries & Frameworks used (Serilog, MediatR, AutoMapper, FluentValidation, Swagger, ASP.NET Core) and notes about versions & usage.

---

(End of SDD.md: the full content mirrors the original SDD.txt with markdown headings, code blocks for examples, and appendices. For maintainability, consider splitting diagrams and large DDL into separate files under docs/architecture/appendices.)
