# 📦 Scaffold Entity từ Database vào Project (.NET)

## 🎯 Mục tiêu
Hướng dẫn sinh mã C# (entity + DbContext) từ cơ sở dữ liệu có sẵn bằng Entity Framework Core, theo hướng **Database-first**, và đưa vào đúng cấu trúc thư mục của dự án LMS.

---

## 🧱 Yêu cầu trước khi thực hiện

- Đã cài công cụ `dotnet-ef`:

```sh
  dotnet tool install --global dotnet-ef
```

- Đã có database (ví dụ: LMSMini) với các bảng cần scaffold.

- Project đã có cấu trúc thư mục như sau:

```
Lms.Domain/
└── Entities/
    ├── Identity/
    ├── Course/
    ├── Enrollment/
    └── Shared/
Lms.Infrastructure/
└── Persistence/
    └── LmsDbContext.cs
```

---

## ⚙️ Lệnh scaffold đầy đủ

```bash
dotnet ef dbcontext scaffold "Server=localhost;Database=LMSMini;Trusted_Connection=True;" Microsoft.EntityFrameworkCore.SqlServer \
--output-dir ../Lms.Domain/Entities \
--context-dir ../Lms.Infrastructure/Persistence \
--context LmsDbContext \
--namespace Lms.Domain.Entities \
--use-database-names \
--no-onconfiguring
```

---

## 🔍 Giải thích tham số

| **Tham số**            | **Ý nghĩa**                                                               |
|------------------------|---------------------------------------------------------------------------|
| `"..."`                | Chuỗi kết nối đến cơ sở dữ liệu                                           |
| `SqlServer`            | Provider Entity Framework dùng để kết nối                                 |
| `--output-dir`         | Thư mục nơi sinh ra các entity                                            |
| `--context-dir`        | Thư mục nơi đặt DbContext                                                 |
| `--context`            | Tên của lớp DbContext                                                     |
| `--namespace`          | Namespace của các entity                                                  |
| `--use-database-names` | Giữ nguyên tên bảng từ cơ sở dữ liệu                                      |
| `--no-onconfiguring`   | Không sinh phương thức OnConfiguring() trong DbContext                    |

---

## 📁 Sau khi scaffold

- Các entity sẽ nằm trong `Lms.Domain/Entities/`.
- Di chuyển entity vào các module con như `Identity/`, `Course/`, `Enrollment/` nếu cần.
- Kiểm tra lại namespace và kế thừa `BaseEntity` hoặc `AuditEntity` nếu có.

---

## 🧪 Kiểm tra sau scaffold

1. Mở `LmsDbContext.cs` để xác nhận các `DbSet<T>` đã sinh đúng.
2. Build lại solution để kiểm tra lỗi cú pháp hoặc xung đột namespace.
3. Có thể viết unit test hoặc gọi thử API để xác nhận entity hoạt động đúng.

---

## 📌 Ghi chú

- Nếu dùng PostgreSQL, thay `SqlServer` bằng `Npgsql.EntityFrameworkCore.PostgreSQL`.
- Nếu DB có nhiều bảng không cần thiết, dùng `--table` để scaffold chọn lọc:

```bash
--table Courses --table Lessons
```

---

## Tài liệu hướng dẫn
Tài liệu hướng dẫn bổ sung, bao gồm hướng dẫn thiết lập và sử dụng nâng cao, có thể được tìm thấy trong thư mục `docs`.

---

## ✅ Kết luận

Scaffold từ database giúp bạn nhanh chóng tạo mô hình C# đồng bộ với DB thực tế, đặc biệt hữu ích khi tích hợp hệ thống cũ hoặc reverse-engineer. Tuy nhiên, cần kiểm tra kỹ namespace, cấu trúc thư mục, và kế thừa các base class để đảm bảo phù hợp với kiến trúc dự án.