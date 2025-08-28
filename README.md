# LmsMini
Một hệ thống quản lý học tập (Learning Management System) nhẹ, được xây dựng bằng .NET.

## Mô tả dự án
LmsMini là một hệ thống quản lý học tập theo mô-đun, được thiết kế để quản lý khóa học, ghi danh và danh tính người dùng. Dự án được xây dựng bằng .NET 7/9 và tuân theo các nguyên tắc kiến trúc sạch (Clean Architecture).

## Cấu trúc dự án
- `LmsMini.Api`: Lớp API xử lý các yêu cầu HTTP.
- `LmsMini.Application`: Lớp ứng dụng chứa logic nghiệp vụ.
- `LmsMini.Domain`: Lớp miền với các thực thể cốt lõi và giá trị đối tượng.
- `LmsMini.Infrastructure`: Lớp hạ tầng cho cơ sở dữ liệu và các dịch vụ bên ngoài.
- `LmsMini.Tests`: Các bài kiểm thử đơn vị và tích hợp.

## Yêu cầu hệ thống
- .NET 7 SDK hoặc mới hơn
- SQL Server (hoặc cơ sở dữ liệu được hỗ trợ khác)
- Node.js (nếu tích hợp front-end)

## Hướng dẫn cài đặt
1. Clone repository:
   ```bash
   git clone https://github.com/your-username/LmsMini.git
   ```
2. Di chuyển vào thư mục dự án:
   ```bash
   cd LmsMini
   ```												
3. Khôi phục các gói phụ thuộc:
   ```bash
   dotnet restore
   ```
4. Build solution:
   ```bash
   dotnet build
   ```

## Chạy dự án
- Để chạy API:
  ```bash
  dotnet run --project LmsMini.Api
  ```
- API sẽ khả dụng tại `https://localhost:5001`.

## Đóng góp
Mọi đóng góp đều được hoan nghênh! Vui lòng fork repository và gửi pull request.

## Giấy phép
Dự án này được cấp phép theo giấy phép MIT. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## Tài liệu hướng dẫn
Tài liệu hướng dẫn bổ sung, bao gồm hướng dẫn thiết lập và sử dụng nâng cao, có thể được tìm thấy trong thư mục `docs`.