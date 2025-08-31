# Interface visibility và cách implement trong C#

Mục tiêu: giải thích ngắn gọn về visibility của interface và cách các phương thức của interface được sử dụng khi implement.

Tóm tắt:
- Ở cấp namespace, nếu bạn khai `public interface IMy { ... }` thì type này có thể dùng từ các assembly khác.
- Nếu bạn **không** khai access modifier (ví dụ: `interface IMy { }`) thì mặc định type là `internal` (chỉ thấy trong cùng assembly).
- Các thành viên của interface (phương thức, property, v.v.) _mặc định_ là `public`. Bạn không cần (và thường không được) viết access modifier trên các thành viên.
- Khi một lớp implement interface, có hai cách:
  - Implicit implementation (triển khai thông thường): phương thức triển khai được khai là `public` — có thể gọi trực tiếp từ instance.
  - Explicit interface implementation (triển khai tường minh): định danh kiểu khi triển khai (`void IMy.Method() { ... }`) — phương thức này *không* xuất hiện là public trên lớp, chỉ có thể gọi khi instance được cast về interface.

Gợi ý:
- Nếu repository/contract cần dùng từ các project khác (ví dụ đăng ký DI từ assembly khác), khai `public interface ICourseRepository` là hợp lý.
- Nếu chỉ dùng nội bộ trong assembly, có thể để mặc định `internal` bằng cách không ghi `public`.

Ví dụ minh hoạ xem file examples/MinimalInterfaceExample.md

Nếu cần bản tiếng Anh hoặc mở rộng ví dụ với async/Task (như ICourseRepository), báo rõ yêu cầu.