# RowVersion & Optimistic Concurrency — Hướng dẫn nhanh

📌 Tóm tắt nội dung chính
Tài liệu nói về RowVersion (hay rowversion/timestamp trong SQL) và cách dùng nó để tránh ghi đè dữ liệu khi nhiều người cùng sửa — gọi là optimistic concurrency.

Ý tưởng chính:

- RowVersion là một cột đặc biệt trong bảng DB; mỗi khi bản ghi bị sửa, giá trị này tự động thay đổi.
- Khi client gửi yêu cầu cập nhật, EF Core sẽ so sánh RowVersion hiện tại trong DB với RowVersion mà client gửi.
- Nếu khác nhau → có người đã sửa trước đó → phát hiện xung đột (DbUpdateConcurrencyException) và tránh ghi đè dữ liệu.

Các phần chính trong tài liệu:

- Mục đích: Dùng RowVersion để phát hiện xung đột khi nhiều người cùng cập nhật.
- Scaffold từ DB: EF sẽ tạo property `byte[] RowVersion` và cấu hình `.IsRowVersion().IsConcurrencyToken()`.
- Cấu hình EF Core: Có thể dùng Fluent API hoặc `[Timestamp]` attribute.
- DTO & mapping: Không gửi trực tiếp `byte[]` cho client; nếu cần thì encode Base64.
- Xử lý lỗi: Bắt `DbUpdateConcurrencyException` và trả HTTP 409 Conflict.
- Ví dụ code: Handler cập nhật có kiểm tra RowVersion.
- Testing: Mô phỏng tình huống 2 client cùng sửa để test lỗi xung đột.
- Best practices: Luôn giữ RowVersion trong DB, cấu hình đúng, và document rõ cho frontend.

---

## Giải thích cho học sinh lớp 5 (ngắn gọn)
Hãy tưởng tượng RowVersion giống như một "tem ngày giờ" dán trên một cuốn sổ lớp:

- Mỗi khi ai đó viết vào sổ, tem sẽ đổi sang một số mới.
- Nếu bạn cầm bản photo cũ của trang sổ (tem cũ) và viết đè, cô giáo sẽ phát hiện: “Ơ, có người đã viết trước rồi!” → không cho ghi đè.

Nhờ vậy, không ai vô tình xóa mất nội dung mới nhất của người khác.

---

Tài liệu này giải thích cách cấu hình và xử lý trường RowVersion (SQL rowversion / timestamp) trong dự án LmsMini. Bao gồm: behaviour khi scaffold, cấu hình EF Core, mapping DTO, xử lý xung đột khi SaveChanges và ví dụ code ngắn.

---

## 1. Mục đích
RowVersion được dùng làm optimistic concurrency token. Khi nhiều client cùng cập nhật cùng một bản ghi, EF sẽ phát hiện xung đột và ném `DbUpdateConcurrencyException`. Ta có thể bắt lỗi này để trả `409 Conflict`, retry hoặc hợp nhất theo nghiệp vụ.

---

## 2. Scaffold từ database
- Nếu cột trong DB là kiểu `rowversion` / `timestamp`, lệnh `dotnet ef dbcontext scaffold` thường tạo:
  - Property `byte[] RowVersion` trong entity.
  - Fluent API trong `OnModelCreating` với `.IsRowVersion()` / `.IsConcurrencyToken()` trong DbContext.
- Nếu scaffold không sinh Fluent API, thêm thủ công (xem phần 3).

---

## 3. Cấu hình EF Core (DbContext)
Ví dụ (đã có trong `LmsDbContext`):

```csharp
modelBuilder.Entity<Course>(entity =>
{
    // ... các cấu hình khác ...
    entity.Property(e => e.RowVersion)
          .IsRowVersion()
          .IsConcurrencyToken();
});
```

Ghi chú: `.IsRowVersion()` đảm bảo EF hiểu đó là trường rowversion và sẽ so sánh giá trị khi update.

---

## 4. Entity (ví dụ)
Entity scaffold thường trông như sau:

```csharp
public partial class Course
{
    public Guid Id { get; set; }
    // ... các trường khác ...
    public byte[] RowVersion { get; set; } = null!;
}
```

Bạn có thể dùng attribute thay cho Fluent API:

```csharp
[Timestamp]
public byte[] RowVersion { get; set; }
```

---

## 5. DTO & mapping
- KHÔNG trả trực tiếp `byte[] RowVersion` cho client nếu không cần thiết.
- Nếu muốn client gửi giá trị RowVersion khi cập nhật (optimistic concurrency), mã hóa Base64.

Ví dụ DTO nhận cập nhật (client gửi `RowVersionBase64`):

```csharp
public class UpdateCourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    // RowVersion ở client dưới dạng Base64
    public string? RowVersionBase64 { get; set; }
}
```

Trong handler: chuyển Base64 -> byte[] và gán vào entity trước SaveChanges.

```csharp
if (!string.IsNullOrEmpty(dto.RowVersionBase64))
{
    course.RowVersion = Convert.FromBase64String(dto.RowVersionBase64);
}
```

---

## 6. Xử lý DbUpdateConcurrencyException (repository / handler)
Ví dụ repository save với xử lý xung đột:

```csharp
try
{
    await _context.SaveChangesAsync(cancellationToken);
}
catch (DbUpdateConcurrencyException ex)
{
    // Log, mapping hoặc ném lại một exception chuyên biệt
    throw new ConcurrencyException("Entity update conflict", ex);
}
```

Trong handler / controller, bắt `ConcurrencyException` và trả HTTP 409:

```csharp
try
{
    await _mediator.Send(command);
}
catch (ConcurrencyException)
{
    return Conflict(new { message = "Version conflict. Please reload and try again." });
}
```

Hoặc trả `409` kèm dữ liệu hiện tại để client hiển thị và refetch.

---

## 7. Ví dụ hoàn chỉnh (handler update đơn giản)

```csharp
public async Task<Unit> Handle(UpdateCourseCommand request, CancellationToken ct)
{
    var course = await _repository.GetByIdAsync(request.Id, ct);
    if (course == null) throw new NotFoundException();

    course.Title = request.Title;
    course.Description = request.Description;

    if (!string.IsNullOrEmpty(request.RowVersionBase64))
        course.RowVersion = Convert.FromBase64String(request.RowVersionBase64);

    try
    {
        await _repository.SaveChangesAsync(ct);
    }
    catch (DbUpdateConcurrencyException)
    {
        throw new ConcurrencyException("Update failed due to concurrency");
    }

    return Unit.Value;
}
```

---

## 8. Kiểm tra & testing
- Test scenario:
  1. Client A đọc resource (lấy rowVersion, có thể Base64).
  2. Client B cập nhật resource.
  3. Client A cố gắng cập nhật lại dùng rowVersion cũ → server ném 409.
- Viết unit/integration tests mô phỏng `DbUpdateConcurrencyException`.

---

## 9. Tóm tắt (best practices)
- Giữ `RowVersion` trong DB và cấu hình `.IsRowVersion()` trong DbContext.
- Khi trả DTO cho client: omit `RowVersion` hoặc encode Base64 nếu client cần gửi lại.
- Bắt `DbUpdateConcurrencyException` và xử lý trả 409 hoặc retry theo nghiệp vụ.
- Document flow cho frontend (client phải gửi lại rowVersion khi cập nhật nếu dùng optimistic concurrency).

---

Nếu bạn muốn, tôi có thể: thêm ví dụ handler/repository file vào repo, cập nhật ImplementCreateCourseGuide.md với link tới tài liệu này, hoặc tạo test case mẫu. Chọn một hành động và tôi sẽ thực hiện.
