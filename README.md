# LMS Mini - Hệ Thống Quản Lý Học Tập

## 📋 Giới Thiệu

**LMS Mini** là một hệ thống quản lý học tập (Learning Management System) được phát triển bằng .NET 9, tập trung vào việc xây dựng **backend API** cho việc quản lý khóa học trực tuyến. Dự án được thiết kế dành cho **team 2 nhà phát triển** với quy mô vừa phải, phù hợp cho việc học tập và nghiên cứu.

## 🎯 Mục Tiêu Dự Án

- Xây dựng **Backend API** hoàn chỉnh cho hệ thống LMS
- Áp dụng **Clean Architecture** và các design patterns hiện đại
- Hỗ trợ quản lý khóa học, bài học, và đánh giá học viên
- Triển khai hệ thống authentication và authorization
- **Giới hạn:** Chỉ tập trung vào backend API, không bao gồm frontend

## 🚀 Công Nghệ Sử Dụng

- **.NET 9** - Framework chính
- **ASP.NET Core Web API** - Xây dựng REST API
- **Entity Framework Core 9** - ORM và Database Access
- **SQL Server Express** - Cơ sở dữ liệu
- **AutoMapper** - Object mapping
- **MediatR** - CQRS pattern implementation
- **FluentValidation** - Validation logic
- **Serilog** - Logging framework
- **xUnit** - Unit testing

## 🏗️ Kiến Trúc Dự Án

Dự án được tổ chức theo **Clean Architecture** với các layers:

```
📁 LmsMini/
├── 🌐 LmsMini.Api/              # Presentation Layer (Web API Controllers)
├── 📱 LmsMini.Application/      # Application Layer (Business Logic, CQRS)
├── 🏢 LmsMini.Domain/           # Domain Layer (Entities & Business Rules)
├── 🗄️ LmsMini.Infrastructure/   # Infrastructure Layer (Data Access, EF Core)
└── 🧪 LmsMini.Tests/           # Unit Tests
```

## 📊 Tính Năng Hệ Thống

### 👥 Quản Lý Người Dùng
- Đăng ký, đăng nhập với ASP.NET Core Identity
- Phân quyền vai trò (Admin, Instructor, Student)
- Quản lý profile người dùng
- Audit logging cho tất cả hoạt động người dùng

### 📚 Quản Lý Khóa Học
- Tạo và quản lý khóa học với mã code duy nhất
- Tổ chức theo modules và lessons
- Quản lý nội dung đa phương tiện
- Theo dõi tiến độ học tập của học viên
- Hệ thống enrollment (ghi danh)

### 📝 Hệ Thống Đánh Giá
- Tạo và quản lý quiz với nhiều câu hỏi
- Hỗ trợ multiple choice questions
- Quản lý số lần làm bài được phép
- Chấm điểm tự động và lưu kết quả
- Theo dõi chi tiết các lần làm bài

### 🔔 Thông Báo & Theo Dõi
- Hệ thống notification cho học viên
- Audit logging chi tiết
- Progress tracking theo từng lesson
- Event sourcing với Outbox pattern

### 📁 Quản Lý File
- Upload và quản lý file assets
- Hỗ trợ nhiều loại file đa phương tiện
- Metadata tracking và storage management

## 🗃️ Cấu Trúc Database

Hệ thống bao gồm **15 bảng chính**:

**Core Tables:**
- **AspNetUsers** - Quản lý người dùng (Identity Framework)
- **Courses** - Thông tin khóa học và metadata
- **Modules** - Các module trong khóa học
- **Lessons** - Bài học chi tiết với content

**Assessment System:**
- **Quizzes** - Bài kiểm tra và cấu hình
- **Questions** - Câu hỏi với thứ tự
- **Options** - Các lựa chọn cho câu hỏi
- **QuizAttempts** - Lịch sử làm bài
- **AttemptAnswers** - Chi tiết câu trả lời

**Tracking & Management:**
- **Enrollments** - Đăng ký học với trạng thái
- **Progress** - Tiến độ học tập theo lesson
- **Notifications** - Thông báo hệ thống
- **FileAssets** - Quản lý file và media
- **AuditLogs** - Nhật ký hệ thống đầy đủ
- **OutboxMessages** - Event sourcing pattern

## ⚙️ Cài Đặt và Chạy Dự Án

### Yêu Cầu Hệ Thống
- **.NET 9 SDK**
- **SQL Server Express** hoặc **SQL Server**
- **Visual Studio 2022** hoặc **VS Code**

### Các Bước Cài Đặt

1. **Clone repository:**
   ```bash
   git clone https://github.com/SokKimThanh/LmsMini.git
   cd LmsMini
   ```

2. **Cấu hình Connection String:**
   
   File `LmsMini.Api/appsettings.json` đã được cấu hình:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=.\\SQLEXPRESS;Database=LMSMini;Trusted_Connection=True;TrustServerCertificate=True;"
     }
   }
   ```

3. **Restore packages:**
   ```bash
   dotnet restore
   ```

4. **Build solution:**
   ```bash
   dotnet build
   ```

5. **Chạy API:**
   ```bash
   dotnet run --project LmsMini.Api
   ```

6. **Truy cập API Documentation:**
   
   Swagger UI: `https://localhost:7xxx/swagger`

## 🧪 Testing

Chạy unit tests:
```bash
dotnet test
```

## 📈 Giới Hạn và Phạm Vi Dự Án

### ✅ **Những gì được bao gồm:**
- **Backend API hoàn chỉnh** với REST endpoints
- **Database design** hoàn chỉnh với 15 tables
- **Authentication/Authorization** với Identity
- **CQRS pattern** với MediatR
- **Comprehensive logging** và audit trail
- **Unit testing** framework setup

### ❌ **Những gì KHÔNG bao gồm:**
- **Frontend application** (React, Angular, Blazor, etc.)
- **Mobile app** development
- **Real-time features** (SignalR, WebSockets)
- **Advanced file storage** (AWS S3, Azure Blob)
- **Email service integration**
- **Payment gateway** integration
- **Advanced analytics** và reporting
- **Multi-tenant** architecture

### 🎯 **Giới Hạn Kỹ Thuật:**
- **Team size:** Tối ưu cho 2 developers
- **Database:** SQL Server Express (10GB limit)
- **File storage:** Local file system
- **Caching:** In-memory only
- **Authentication:** JWT basic, không có OAuth2
- **Deployment:** Single instance, chưa có load balancing

## 🛠️ Kế Hoạch Phát Triển Tiếp Theo

### Phase 1 (Backend Completion):
- [ ] Hoàn thiện tất cả API endpoints
- [ ] Comprehensive unit và integration tests
- [ ] API documentation với OpenAPI/Swagger
- [ ] Error handling và validation nâng cao

### Phase 2 (Infrastructure):
- [ ] Docker containerization
- [ ] CI/CD pipeline setup
- [ ] Database migration scripts
- [ ] Performance optimization

### Phase 3 (Extended Features):
- [ ] Caching layer (Redis)
- [ ] Email notifications
- [ ] File upload to cloud storage
- [ ] Advanced reporting APIs

## 👥 Đóng Góp

Dự án hiện tại được phát triển và maintain bởi **team 2 developers**. 

**Quy trình đóng góp:**
1. Fork repository
2. Tạo feature branch
3. Implement changes với unit tests
4. Submit pull request với mô tả chi tiết

## 📝 License

Dự án này được phát triển cho mục đích **học tập và nghiên cứu**. Xem file [LICENSE](LICENSE) để biết chi tiết.

---

## 🚨 **Lưu Ý Quan Trọng**

> **Đây là phiên bản BACKEND API ONLY**
> 
> - Dự án này chỉ cung cấp REST API endpoints
> - Không bao gồm bất kỳ frontend nào (web, mobile)
> - Phù hợp cho việc học tập Clean Architecture và API development
> - Frontend có thể được phát triển riêng bằng công nghệ khác

**API Base URL:** `https://localhost:7xxx/api/`
**Documentation:** `https://localhost:7xxx/swagger`