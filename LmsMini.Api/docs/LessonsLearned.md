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
1. Client gửi request  
2. Controller nhận & tạo Command/Query  
3. MediatR định tuyến đến Handler  
4. Handler xử lý nghiệp vụ  
5. Repository truy cập DB  
6. Domain áp dụng rules  
7. Mapping sang DTO  
8. Controller trả response

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
---

**Tóm Lại:**
- Clean Architecture không chỉ là một mô hình tổ chức code, mà còn là một triết lý giúp xây dựng phần mềm dễ bảo trì, dễ mở rộng và chất lượng cao.