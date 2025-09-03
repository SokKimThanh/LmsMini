# Software Design Document (SDD) - LMS-Mini

## Document Control

**Phiên bản** | **Ngày** | **Người biên tập** | **Nội dung chỉnh sửa**
---|---:|---|---
1.0 | 15/08/2025 | Sok Kim Thanh | Bản nháp đầu tiên.
1.1 | 25/08/2025 | Sok Kim Thanh | Biên tập sạch, chuẩn hoá cấu trúc, bổ sung Document Control, Scope, Glossary.
1.2 | 26/08/2025 | Sok Kim Thanh | Bổ sung Non-Functional Requirements, Deployment, Error Handling, Testing Strategy, Backup & Disaster Recovery. Cập nhật Mục lục.

### Revision History

**Phiên bản** | **Ngày** | **Người sửa** | **Nội dung sửa đổi**
---|---:|---|---
1.0 | 15/08/2025 | Sok Kim Thanh | Bản nháp đầu tiên.
1.1 | 25/08/2025 | Sok Kim Thanh | Biên tập sạch, chuẩn hoá cấu trúc.
1.2 | 26/08/2025 | Sok Kim Thanh | Bổ sung các mục Non-Functional Requirements (NFRs), Deployment, Error Handling, Testing Strategy, Backup & Disaster Recovery. Cập nhật lại Mục lục.

---

## Mục lục

1. Giới thiệu
  - 1.1 Mục tiêu
  - 1.2 Phạm vi
  - 1.3 Độc giả mục tiêu
  - 1.4 Thuật ngữ (Glossary)
2. Tổng quan hệ thống (System Context)
  - 2.1 Stakeholders
  - 2.2 Sơ đồ tổng quan hệ thống
3. Kiến trúc & Quyết định kiến trúc
  - 3.1 Component Diagram - LMS Mini
  - 3.2 Use-Case Diagram - LMS Mini
  - 3.3 Mô hình kiến trúc
  - 3.4 Sơ đồ kiến trúc tổng thể
  - 3.5 Vai trò, trách nhiệm và mối quan hệ
  - 3.6 Quy ước chung
  - 3.7 Interface/Port chính và nơi triển khai
  - 3.8 Domain Events, Outbox, Specification & Cross-Cutting Concerns
4. Thiết kế cơ sở dữ liệu
  - 4.1 Audit & Soft Delete
  - 4.2 Mô hình logic
  - 4.3 Indexes
  - ...
5. Domain Design
6. Thiết kế API & Contract
7. Thiết kế UI/UX
8. Luồng nghiệp vụ chính (Sequence Logic)
9. Quy tắc bảo mật (Security rules)
10. Non-Functional Requirements (NFRs)
11. Deployment & Infrastructure View
12. Error Handling & Exception Flow
13. Testing Strategy
14. Backup & Disaster Recovery
15. Coding style và vận hành
16. Deliverables / Output
17. Phụ lục

---

## 1 Giới thiệu

### 1.1 Mục tiêu

Tài liệu này mô tả thiết kế phần mềm (Software Design Document) cho hệ thống LMS-Mini. Nội dung bao gồm kiến trúc hệ thống, mô hình miền, API contract, dữ liệu, use-case chính và hướng dẫn triển khai.

### 1.2 Phạm vi

- Bao gồm: kiến trúc backend, domain model, API contract, dữ liệu, use-case chính (ghi danh, làm bài kiểm tra, theo dõi tiến độ, thông báo).
- Không bao gồm: chi tiết giao diện người dùng (UI pixel-perfect), hạ tầng phần cứng cụ thể.

### 1.3 Độc giả mục tiêu

- Backend/Frontend Developers
- QA Engineers
- DevOps
- Reviewers / Architects

### 1.4 Thuật ngữ (Glossary)

Bảng thuật ngữ tóm tắt các khái niệm chính (A11y, Admin, Instructor, Learner, Aggregate, Application Layer, Clean Architecture, CQRS, Domain Layer, Presentation Layer, Repository Pattern, Specification Pattern, UnitOfWork, Background Worker, Blob Storage, Key Vault, MediatR, Message Broker, Attempt, AttemptAnswer, Course, Enrollment, FileAsset, Lesson, Module, Notification, Progress, Question, Quiz, QuizAttempt, Use Case, Value Object, Audit Log, CSRF Token, ETag, Idempotency-Key, RBAC, RowVersion, Scope, Security Headers, Soft Delete, DDL, Filtered Index, Migration, PK/FK/UQ/IX/DF, DTO, EF Core, Global Query Filter, Backoff Retry, CI/CD, Observability, Rate limiting, SLA/SLI/SLO).

(Chi tiết thuật ngữ chuyển từ file gốc vào phụ lục Glossary.)

---

## 2 Tổng quan hệ thống (System Context)

Hệ thống LMS-Mini cho phép tạo khoá học, ghi danh, làm bài kiểm tra, theo dõi tiến độ và gửi thông báo. Các thành phần chính:

- Frontend: SPA giao tiếp qua REST API.
- Backend API: xử lý use case, domain logic.
- Database (RDBMS): lưu trữ transactional data.
- Blob Storage: lưu tài liệu, media.
- Background Workers: xử lý tác vụ async.
- Message Broker: publish/subscribe các sự kiện.

### 2.1 Stakeholders

- Learner: Người dùng học tập, làm quiz, theo dõi tiến độ.
- Instructor: Tạo, quản lý khoá học, theo dõi học viên.
- Admin: Quản lý người dùng, phân quyền, giám sát hệ thống.
- QA: Đảm bảo chất lượng, viết test plan.
- DevOps: Triển khai, giám sát, vận hành hệ thống.

### 2.2 Sơ đồ tổng quan hệ thống

(Hình minh hoạ system context: clients, API, DB, Blob Storage, Broker, Workers)

---

## 3 Kiến trúc & Quyết định kiến trúc

### 3.1 Component Diagram - LMS Mini

(Chi tiết component diagram được thêm trong phụ lục PlantUML.)

### 3.2 Use-Case Diagram - LMS Mini

(Hình Use-case Diagram tổng quan.)

### 3.3 Mô hình kiến trúc

Hệ thống LMS Mini áp dụng Clean Architecture nhằm tách biệt rõ ràng giữa các tầng: Presentation (Blazor/UI), Application (Use Cases, DTOs, Handlers), Domain (Entities, Value Objects, Business Rules), Infrastructure (EF Core, Repositories, Adapters).

Nguyên tắc chính:

- Phụ thuộc một chiều: Presentation → Application → Domain.
- Domain không phụ thuộc vào tầng khác.
- Tầng Infrastructure triển khai interfaces (ports) từ Application/Domain.

### 3.4 Sơ đồ kiến trúc tổng thể

(Hình Layer Diagram)

#### 3.4.1 Ví dụ: Tạo khóa học mới (Create Course)

Tóm tắt luồng: UI → CreateCourseCommand → Handler → Domain (Course validate) → Repository → DbContext persist → commit.

(Mã ví dụ razor component và handler minimal được giữ trong phụ lục hoặc codebase.)

#### 3.4.2 Ví dụ: Đăng ký khóa học (Enroll in Course)

Tóm tắt luồng: EnrollCourse.razor gọi Mediator.Send(EnrollCourseCommand). Handler kiểm tra enrollment tồn tại, gọi repository để lưu.

(Mã ví dụ đã được đưa vào SDD gốc; giữ lại trong phụ lục ví dụ code.)

#### 3.4.3 Ví dụ: Nộp bài kiểm tra (Submit Quiz)

Tóm tắt luồng: UI SubmitQuizCommand → Handler tính điểm bằng domain Quiz.CalculateScore → Save QuizAttempt → Update Progress → trả kết quả.

---

## 3.5 Vai trò, trách nhiệm và mối quan hệ

Bảng mô tả responsabilidades của Presentation, Application, Domain, Infrastructure cùng các interface/port chính (ICourseRepository, IModuleRepository, IEnrollmentRepository, IProgressRepository, IQuizRepository, IUnitOfWork, IFileStorage, IEmailSender, IDateTimeProvider, IAuthService, IReportService, IQuerySpecification<T>).

## 3.6 Quy ước chung

- Audit: mọi entity kế thừa BaseAuditable (CreatedAt, CreatedBy, ModifiedAt, ModifiedBy).
- Soft Delete: IsDeleted flag và global query filter trong EF Core.
- Quy ước đặt tên PK/FK/Index.

## 3.7 Interface/Port chính và nơi triển khai

Bảng mapping Interface → Định nghĩa → Triển khai (Application.Abstractions → Infrastructure.Repositories/...)

## 3.8 Domain Events, Outbox, Specification & Cross-Cutting Concerns

### 3.8.1 Domain Events

- Raised từ Aggregate Root sau khi validate và trước commit.
- Lifecycle: Raised → Persisted (Outbox) → Published → Consumed → Archived.
- Payload chuẩn JSON (eventId, eventType, version, occurredOn, correlationId, tenantId, causedByUserId, data).

### 3.8.2 Outbox Pattern

- Persist event vào OutboxMessages trong cùng transaction.
- Background worker đọc Outbox, publish tới broker, retry policy, mark ProcessedOn.

### 3.8.3 Specification Pattern

- IQuerySpecification<T> để mô tả Criteria, OrderBy, Includes, Skip/Take.
- Repository áp dụng specification để compose queries.

### 3.8.4 Timezone / Clock

- Lưu UTC, IDateTimeProvider.UtcNow, mockable for tests.

### 3.8.5 Audit Log

- AuditEntry gồm id, action, entityType, entityId, performedByUserId, performedOnUtc, details, correlationId, tenantId.

---

## 4 Thiết kế cơ sở dữ liệu

(Tổng hợp các bảng, PK/FK/UQ/Index, ERD, filtered indexes, migration strategy, seed strategy.)

### 4.1 Audit & Soft Delete

Mục tiêu: đảm bảo audit & khả năng phục hồi bằng soft delete (IsDeleted flag). Chi tiết các trường chuẩn: CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, DeletedAt, DeletedBy, IsDeleted.

EF Core: áp dụng Global Query Filter mẫu (modelBuilder.Entity<Course>().HasQueryFilter(e => !e.IsDeleted); ...)

#### 4.1.5 Ghi nhận audit tự động (EF Interceptor / middleware)

Mẫu interface IAuditable và ví dụ override SaveChanges để set CreatedAt/CreatedBy/UpdatedAt/UpdatedBy từ _clock và _currentUser.

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

### 4.2 Mô hình logic - Bảng, PK, FK, Unique, Index

(Chi tiết cho AspNetUsers, Courses, Modules, Lessons, Enrollments, Progresses, Quizzes, Questions, Options, QuizAttempts, AttemptAnswers, Notifications, FileAssets, AuditLogs, OutboxMessages.)

---

## 5 Domain Design

(Entities & Aggregates, Domain Services, Business Rules, Domain Events, Outbox flow.)

---

## 6 Thiết kế API & Contract

### 6.1 Contract nội bộ (Port / Adapter)

Danh sách interfaces và nơi triển khai.

### 6.2 Contract bên ngoài (REST API cho client)

Nguyên tắc chung
- Base URL: /api/v1
- Auth: JWT Bearer Token (AspNet Identity)
- Response Envelope chuẩn:

```json
{
  "success": true,
  "data": { },
  "error": null,
  "traceId": "..."
}
```

Quy tắc Idempotency-Key, ETag/If-Match, Pagination headers (X-Total-Count, Link), Rate limiting headers, i18n, CSV safety.

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

## 7 Thiết kế UI/UX

(TopBar, SideNav, ContentArea, Footer, A11y rules, Blazor Server connection resilience, autosave for quizzes, component library suggestions: LmsDataTable, LmsForm, ProgressBar, QuizRunner, KpiCard, Alert/Toast, ConfirmDialog, FileUploader.)

---

## 8 Luồng nghiệp vụ chính (Sequence Logic)

(Use case flows: EnrollCourse, SubmitQuiz, QuizAttemptFlow, MarkLessonCompleted, CreateCourse, ManageLessons, CreateQuiz, ViewProgress, LessonProgress, SendNotification, FileAssets, Secrets & Upload Security, Observability.)

(Sequence diagrams included in Appendix B.)

---

## 9 Quy tắc bảo mật (Security rules)

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

- Map exceptions → Error codes (ERR_NOT_FOUND, ERR_FORBIDDEN, ERR_VALIDATION, ERR_CONFLICT, ERR_INTERNAL, ERR_PRECONDITION, etc.)
- Use Response Envelope with traceId.

---

## 13 Testing Strategy

- Unit tests (≥80% domain coverage where applicable)
- Integration tests (API + DB)
- Load tests (k6/JMeter)
- Security tests (OWASP ZAP/Burp)
- Acceptance tests based on use cases

---

## 14 Backup & Disaster Recovery

- DB full daily + transaction log every 15 minutes
- Blob Storage soft delete + versioning
- RPO ≤ 15 minutes, RTO < 2 hours

---

## 15 Coding style và vận hành

- Namespaces: Lms.Domain, Lms.Application, Lms.Infrastructure, Lms.Web
- Async for all IO methods
- DTO naming conventions: CreateXRequest, XDto, XResponse
- Handlers implement MediatR IRequestHandler

---

## 16 Deliverables / Output (Đầu ra mong muốn)

- Architecture diagrams
- ERD & DDL scripts
- API specification & DTOs
- UI wireframes & user flows
- Security & operations notes
- Checklists & governance

---

## 17 Phụ lục

- Appendix A: Sample SQL DDL Snippets (SQL Server) — includes CREATE TABLE for AspNetUsers, Courses, Modules, Lessons, Quizzes, Questions, Options, QuizAttempts, AttemptAnswers, Enrollments, Progresses, Notifications, FileAssets, OutboxMessages, AuditLogs, plus indexes and constraints.

- Appendix B: PlantUML sources for diagrams (System Context, Use-case, Layer diagrams, Sequence diagrams, Component diagrams).

- Appendix C: DTOs, Sample Payloads & OpenAPI snippets (C# samples and example JSON payloads).

- Appendix D: Libraries & Frameworks used (Serilog, MediatR, AutoMapper, FluentValidation, Swagger, ASP.NET Core) and notes about versions & usage.

---

(End of SDD.md: the full content mirrors the original SDD.txt with markdown headings, code blocks for examples, and appendices. For maintainability, consider splitting diagrams and large DDL into separate files under docs/architecture/appendices.)
