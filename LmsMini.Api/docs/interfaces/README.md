# Interface visibility và cách implement trong C#

Mục tiêu: giải thích ngắn gọn về visibility của interface và cách các phương thức của interface được sử dụng khi implement.

Tóm tắt:
- Ở cấp namespace, nếu bạn khai `public interface IMy { ... }` thì type này có thể dùng từ các assembly khác.
- Nếu bạn **không** khai access modifier (ví dụ: `interface IMy { }`) thì mặc định type là `internal` (chỉ thấy trong cùng assembly).
- Các thành viên của interface (phương thức, property, v.v.) _mặc định_ là `public`. Bạn không cần (và thường không được) viết access modifier trên các thành viên.
- Khi một lớp implement interface, có hai cách:
  - Implicit implementation (triển khai thông thường): phương thức triển khai được khai là `public` — có thể gọi trực tiếp từ instance.
  - Explicit interface implementation (triễn khai tường minh): định danh kiểu khi triển khai (`void IMy.Method() { ... }`) — phương thức này *không* xuất hiện là public trên lớp, chỉ có thể gọi khi instance được cast về interface.

Gợi ý:
- Nếu repository/contract cần dùng từ các project khác (ví dụ đăng ký DI từ assembly khác), khai `public interface ICourseRepository` là hợp lý.
- Nếu chỉ dùng nội bộ trong assembly, có thể để mặc định `internal` bằng cách không ghi `public`.

Ví dụ minh hoạ xem file examples/MinimalInterfaceExample.cs

So sánh ngắn: Abstraction (lớp trừu tượng) vs Interface

- Giống nhau:
  - Đều là cách mô tả contract (hợp đồng) cho các lớp triển khai.
  - Hỗ trợ đa hình (polymorphism) — bạn có thể tham chiếu instance qua kiểu trừu tượng hoặc interface.
  - Không thể khởi tạo trực tiếp (abstract class không thể tạo instance; interface cũng không).

- Khác nhau chính:
  - Kế thừa:
    - Lớp trừu tượng: lớp chỉ được kế thừa từ một lớp trừu tượng đơn (single inheritance).
    - Interface: một lớp có thể implement nhiều interface.
  - Thành phần:
    - Lớp trừu tượng: có thể chứa state (fields), constructor, các phương thức có implementation, protected/internal members.
    - Interface: không có fields instance; từ C# 8+ có default implementations và static members nhưng vẫn không giữ state instance.
  - Access modifier:
    - Lớp trừu tượng: các thành viên có thể có modifiers (public/protected/internal/...).
    - Interface: các thành viên API mặc định public; các helper có thể private/static theo ngữ nghĩa hiện đại.
  - Khi dùng:
    - Dùng abstract class khi muốn chia sẻ implementation chung hoặc state giữa các subclass liên quan.
    - Dùng interface khi cần định nghĩa contract cho các kiểu không có quan hệ kế thừa trực tiếp hoặc khi cần đa kế thừa về hành vi.
  - Versioning:
    - Thêm method vào abstract class ít rủi ro vì có thể đưa implementation mặc định.
    - Thêm method vào interface trước C# 8 phá vỡ các triển khai cũ; C# 8+ giới thiệu default implementation giảm rủi ro nhưng vẫn nên cân nhắc.

Ngắn gọn: dùng abstract class khi có logic/chung state để chia sẻ; dùng interface để mô tả contract thuần túy và cho phép đa dạng kiểu implement.

Ví dụ minh hoạ xem file examples/AbstractionVsInterface.cs

Nếu cần bản tiếng Anh hoặc mở rộng ví dụ với async/Task (như ICourseRepository), báo rõ yêu cầu.