# Library Summary for Program.cs

## 1. Serilog
- **Namespace**: `Serilog`
- **Purpose**: 
  - Cung cấp khả năng logging mạnh mẽ và linh hoạt.
  - Được sử dụng để ghi log ra console và theo dõi các hoạt động của ứng dụng.
- **Key Usage**:
  - `Log.Logger`: Khởi tạo logger toàn cục.
  - `UseSerilog()`: Thay thế logger mặc định của ứng dụng bằng Serilog.
- **Complexity Assessment**:
  - **Learning Curve**: Dễ học và sử dụng với tài liệu phong phú, nhưng có thể phức tạp khi cấu hình các sink hoặc enrichers tùy chỉnh.
  - **Performance**: Hiệu suất cao, nhưng cần tối ưu hóa khi ghi log với tần suất lớn hoặc sử dụng nhiều sink.
  - **Integration**: Tích hợp tốt với ASP.NET Core và các thư viện khác, nhưng cần cấu hình đúng để tránh xung đột.
  - **Maintainability**: Dễ bảo trì nhờ cấu hình tập trung và khả năng mở rộng linh hoạt.

## 2. Swagger (Swashbuckle)
- **Namespace**: `Microsoft.OpenApi.Models`
- **Purpose**:
  - Tạo tài liệu API và giao diện thử nghiệm API.
  - Hỗ trợ cấu hình bảo mật với JWT Bearer Token.
- **Key Usage**:
  - `AddSwaggerGen()`: Cấu hình Swagger, bao gồm định nghĩa bảo mật.
  - `UseSwagger()`, `UseSwaggerUI()`: Kích hoạt giao diện Swagger trong môi trường phát triển.
- **Complexity Assessment**:
  - **Learning Curve**: Dễ học và sử dụng, nhưng có thể phức tạp khi cấu hình các tính năng nâng cao như bảo mật hoặc tài liệu tùy chỉnh.
  - **Performance**: Hiệu suất tốt, nhưng có thể tăng thời gian tải giao diện Swagger khi API lớn.
  - **Integration**: Tích hợp tốt với ASP.NET Core, nhưng cần cấu hình đúng để tránh lộ thông tin nhạy cảm trong môi trường sản xuất.
  - **Maintainability**: Dễ bảo trì nhờ cấu hình rõ ràng và khả năng mở rộng.

## 3. AutoMapper
- **Namespace**: `AutoMapper` (được đăng ký nhưng không trực tiếp sử dụng trong file này).
- **Purpose**:
  - Tự động ánh xạ (map) giữa các đối tượng.
  - Giảm thiểu mã lặp khi chuyển đổi giữa các lớp DTO và Entity.
- **Key Usage**:
  - `AddAutoMapper()`: Tự động quét và đăng ký các profile ánh xạ trong assembly.
- **Complexity Assessment**:
  - **Learning Curve**: Dễ học và sử dụng cho các ánh xạ đơn giản, nhưng có thể phức tạp khi ánh xạ các đối tượng phức tạp hoặc tùy chỉnh.
  - **Performance**: Hiệu suất tốt, nhưng cần chú ý khi ánh xạ các tập hợp lớn hoặc ánh xạ lồng nhau.
  - **Integration**: Tích hợp tốt với ASP.NET Core, nhưng cần cấu hình đúng các profile để tránh lỗi ánh xạ.
  - **Maintainability**: Dễ bảo trì nhờ cấu trúc profile rõ ràng và khả năng tái sử dụng.

## 4. MediatR
- **Namespace**: `MediatR`
- **Purpose**:
  - Cung cấp mô hình CQRS (Command Query Responsibility Segregation).
  - Đóng vai trò trung gian để xử lý các yêu cầu (request) và phản hồi (response).
- **Key Usage**:
  - `AddMediatR()`: Tự động quét và đăng ký các handler trong assembly.
- **Complexity Assessment**:
  - **Learning Curve**: Dễ học và sử dụng cho các ứng dụng nhỏ, nhưng có thể phức tạp khi áp dụng CQRS trong các hệ thống lớn.
  - **Performance**: Hiệu suất tốt, nhưng cần tối ưu hóa khi xử lý số lượng lớn request đồng thời.
  - **Integration**: Tích hợp tốt với ASP.NET Core, nhưng cần thiết kế đúng các handler để tránh logic phức tạp.
  - **Maintainability**: Dễ bảo trì nhờ tách biệt rõ ràng giữa các request và handler.

## 5. ASP.NET Core Libraries
- **Namespace**: `Microsoft.AspNetCore.*`
- **Purpose**:
  - Cung cấp các tính năng cơ bản của ứng dụng web như Controllers, Middleware, và Dependency Injection.
- **Key Usage**:
  - `AddControllers()`: Đăng ký các controller.
  - `UseHttpsRedirection()`, `UseAuthorization()`: Cấu hình pipeline xử lý HTTP.
- **Complexity Assessment**:
  - **Learning Curve**: Dễ học và sử dụng nhờ tài liệu phong phú và cộng đồng lớn.
  - **Performance**: Hiệu suất cao, nhưng cần tối ưu hóa middleware khi ứng dụng lớn.
  - **Integration**: Tích hợp tốt với các thư viện khác, nhưng cần cấu hình đúng để tránh xung đột.
  - **Maintainability**: Dễ bảo trì nhờ cấu trúc rõ ràng và khả năng mở rộng.

## 6. FluentValidation
- **Namespace**: `FluentValidation`, `FluentValidation.AspNetCore`
- **Purpose**:
  - Cung cấp cơ chế kiểm tra dữ liệu (validation) mạnh mẽ và dễ sử dụng cho các model.
  - Hỗ trợ kiểm tra tự động và kiểm tra phía client.
- **Key Usage**:
  - `AddFluentValidationAutoValidation()`: Bật kiểm tra tự động cho các model khi nhận yêu cầu HTTP.
  - `AddFluentValidationClientsideAdapters()`: Thêm hỗ trợ kiểm tra phía client.
  - `AddValidatorsFromAssemblies()`: Tự động quét và đăng ký tất cả các validator trong assembly.
- **Complexity Assessment**:
  - **Learning Curve**: Dễ học và sử dụng với cú pháp rõ ràng, nhưng có thể phức tạp khi áp dụng các quy tắc kiểm tra nâng cao hoặc tùy chỉnh.
  - **Performance**: Hiệu suất tốt cho các ứng dụng vừa và nhỏ, nhưng cần chú ý khi sử dụng với các model phức tạp hoặc số lượng lớn validator.
  - **Integration**: Tích hợp tốt với ASP.NET Core, nhưng cần cấu hình cẩn thận để tránh xung đột với các cơ chế kiểm tra khác.
  - **Maintainability**: Dễ bảo trì nhờ khả năng tách biệt các quy tắc kiểm tra trong các lớp validator riêng biệt.

---

### Summary
File `Program.cs` sử dụng các thư viện trên để thiết lập logging, tài liệu API, ánh xạ đối tượng, xử lý yêu cầu theo mô hình CQRS, và kiểm tra dữ liệu. Các thư viện này giúp ứng dụng dễ bảo trì, mở rộng và theo dõi trong quá trình phát triển.
