# LmsMini.Resources

Dự án này chứa tài liệu và hình ảnh/diagram (PlantUML) dùng chung trong solution.

Mục đích
- Tổ chức và lưu trữ các file tài liệu, sơ đồ và hình ảnh phục vụ phát triển, thiết kế và tài liệu nội bộ.
- Các tệp được đánh dấu là Content trong .csproj để có thể được copy vào output khi build/publish.

Cấu trúc thư mục

- File Tài liệu/
  - README.md                -> (tệp này) mô tả nội dung và hướng dẫn sử dụng
  - QuyTrinh/                -> tài liệu quy trình (ví dụ: quy-trinh-phan-cong.pdf)
  - ThiếtKế/                 -> tài liệu thiết kế (ví dụ: architecture.md)
  - HướngDẫn/                -> hướng dẫn sử dụng, cài đặt

- File Hinh PlantUML/
  - Diagrams/                -> file .puml nguồn (PlantUML)
  - Images/                  -> hình xuất từ PlantUML hoặc ảnh minh hoạ (.png, .svg)

Hướng dẫn sử dụng
- Đặt mọi tài liệu liên quan vào các thư mục con tương ứng để dễ quản lý.
- Khi cần publish hoặc copy tài liệu vào build output, project đã cấu hình để copy nội dung từ hai thư mục trên.
- Nếu bạn cần thêm loại tệp hoặc thay đổi quy tắc copy, chỉnh sửa LmsMini.Resources.csproj và điều chỉnh <ItemGroup>.

Ghi chú
- Thư mục có thể đang chứa file placeholder (.gitkeep) để giữ cấu trúc khi chưa có nội dung thực tế.
- Tên thư mục chứa ký tự Unicode; nếu bạn gặp vấn đề trên CI hoặc hệ thống khác, cân nhắc đổi tên (ví dụ "Docs" và "PlantUML").

Liên hệ
- Bổ sung hoặc sửa đổi cấu trúc này nếu đề xuất mới phát sinh.