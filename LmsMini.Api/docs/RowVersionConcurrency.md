# RowVersion & Optimistic Concurrency — Hướng dẫn nhanh
<img width="683" height="932" alt="image" src="https://github.com/user-attachments/assets/4a6f7282-9ad1-46eb-af16-687ca10ea31c" />
<img width="908" height="697" alt="image" src="https://github.com/user-attachments/assets/c02885c7-50cc-4b55-adf1-23dfdc82b060" />

📌 Tóm tắt nội dung chính
Tài liệu nói về RowVersion (hay rowversion/timestamp trong SQL) và cách dùng nó để tránh ghi đè dữ liệu khi nhiều người cùng sửa — gọi là optimistic concurrency.

Ý tưởng chính:

- RowVersion là một cột đặc biệt trong bảng DB; mỗi khi bản ghi bị sửa, giá trị này tự động thay đổi.
- Khi client gửi yêu cầu cập nhật, EF Core sẽ so sánh RowVersion hiện tại trong DB với RowVersion mà client gửi.
- Nếu khác nhau → có người đã sửa trước đó → phát hiện xung đột và tránh ghi đè dữ liệu.

Các phần chính trong tài liệu (theo SDD):
- Mục đích, Cấu hình EF Core, Scaffold, DTO/ETag mapping, HTTP contract (ETag/If‑Match), Error codes, Ví dụ HTTP, Test cases.

---

## Giải thích cho học sinh lớp 5 (rút gọn, dễ hiểu)
- Hãy tưởng tượng mỗi quyển sổ (một bản ghi dữ liệu) có một nhãn nhỏ gọi là "phiên bản" dán ở góc. Mỗi lần ai đó sửa sổ, nhãn này thay đổi — giống như dán một sticker mới có số khác.
- Khi em đọc sổ và muốn sửa, em cũng mang theo nhãn của mình. Trước khi ghi, cô giáo kiểm tra nhãn trên sổ thật và nhãn em mang theo.
  - Nếu giống nhau → cô cho em sửa.
  - Nếu khác → có người đã sửa trước, cô sẽ nói: "Không được — phải xem lại" để tránh em ghi đè mất công người khác.

Ví dụ ngắn:
- Em A mở trang, thấy sticker là 1.
- Em B cũng mở và sửa, sticker đổi thành 2.
- Em A cố gắng ghi tiếp nhưng vẫn mang sticker 1 → hệ thống phát hiện và bảo em A tải trang mới trước khi sửa.

Tóm lại: RowVersion là "sticker phiên bản" giúp chương trình giữ an toàn cho dữ liệu khi nhiều người cùng sửa.

---

## Quan trọng: phân biệt HTTP status cho concurrency
- Khi client gửi If‑Match (ETag) và giá trị không khớp với RowVersion hiện tại → trả 412 Precondition Failed (theo SDD).
- Khi có xung đột nghiệp vụ (business conflict) hoặc duplicate/idempotency → trả 409 Conflict.
- DbUpdateConcurrencyException từ EF Core có thể map sang 412 nếu client dùng If‑Match/ETag, hoặc 409/ERR_CONCURRENCY_CONFLICT theo hợp đồng API.

---

## 1. Scope — entities khuyến nghị dùng RowVersion (theo SDD)
Áp dụng optimistic concurrency (ROWVERSION) cho các bảng thay đổi thường xuyên:
- Courses, Lessons, Questions, Options, Modules, Quizzes

(Giải pháp: thêm cột ROWVERSION trong DB và map `byte[] RowVersion` trong entity.)

---

## 2. Cấu hình EF Core (DbContext)
Ví dụ Fluent API:

```csharp
modelBuilder.Entity<Course>(entity =>
{
    entity.Property(e => e.RowVersion)
          .IsRowVersion()
          .IsConcurrencyToken();
});
```

Hoặc attribute:

```csharp
[Timestamp]
public byte[] RowVersion { get; set; }
```

---

## 3. ETag ↔ RowVersion mapping (API contract)
- Server trả header ETag trên response GET (đóng gói rowversion base64):
  ETag: "\"{rowversion-base64}\""
- Client khi cập nhật PUT/PATCH gửi header If‑Match: giá trị ETag đã đọc trước đó.
- Nếu mismatch → server trả 412 Precondition Failed với envelope lỗi chuẩn (xem phần lỗi).

Ví dụ GET response (tóm tắt):

HTTP/1.1 200 OK
ETag: "\"AQIDBAUGBwg=\""
Content-Type: application/json

{ "id": "...", "title": "...", "description": "..." }

Ví dụ PUT request với If‑Match:

PUT /api/v1/courses/{id}
If‑Match: "\"AQIDBAUGBwg=\""
Content-Type: application/json

{ "title": "Tiêu đề mới" }

---

## 4. Xử lý lỗi & error contract (theo SDD)
- Mã lỗi liên quan:
  - ERR_PRECONDITION → HTTP 412 (ETag/If‑Match mismatch)
  - ERR_CONCURRENCY_CONFLICT → HTTP 409 (xung đột nghiệp vụ do concurrent updates)
- Response envelope (mẫu):

HTTP/1.1 412 Precondition Failed
Content-Type: application/json

{
  "success": false,
  "data": null,
  "error": {
    "code": "ERR_PRECONDITION",
    "message": "ETag mismatch - resource was modified",
    "details": null
  },
  "traceId": "...",
}

Khi bắt DbUpdateConcurrencyException ở repository/handler, transform sang ConcurrencyException và map sang ERR_PRECONDITION (412) nếu request có If‑Match; nếu không, trả 409/ERR_CONCURRENCY_CONFLICT theo chính sách.

---

## 5. DTO — RowVersion exposure rules
- Không trả trực tiếp `byte[]` raw cho client.
- Nếu client cần gửi lại rowversion thì server encode Base64 và trả trong ETag header hoặc trong DTO dưới tên `rowVersionBase64` (ưu tiên ETag + If‑Match HTTP header).
- Khi nhận DTO có rowVersionBase64: decode bằng Convert.FromBase64String trước gán vào entity.

---

## 6. Ví dụ handler flow (chi tiết)
1. GET /api/v1/courses/{id} → trả CourseDto + ETag: "\"{base64}\"".
2. Client chỉnh sửa và gửi PUT kèm If‑Match.
3. Controller chuyển request thành command + gán rowVersion (nếu cần); Handler gọi repository save.
4. Repository gọi SaveChangesAsync; nếu EF ném DbUpdateConcurrencyException → handler map và trả 412/409 theo chính sách.

Controller pseudo‑code (ngắn):

```csharp
[HttpPut("{id:guid}")]
public async Task<IActionResult> UpdateCourse(Guid id, UpdateCourseRequest req)
{
    var ifMatch = Request.Headers["If-Match"].FirstOrDefault();

    // If‑Match format "\"base64\"" -> extract and decode
    if (!string.IsNullOrEmpty(ifMatch))
    {
        var raw = ifMatch.Trim('"');
        req.RowVersionBase64 = raw; // or set on command
    }

    try
    {
        await _mediator.Send(command);
        return NoContent();
    }
    catch (ConcurrencyException ex)
    {
        // map to 412 or 409 depending on presence of If‑Match
        return StatusCode(412, new ApiErrorResponse("ERR_PRECONDITION", "ETag mismatch"));
    }
}
```

---

## 7. Test cases (integration) — checklist
1. ETag match → PUT success (204 No Content). Steps: GET (read ETag) → PUT with If‑Match = that ETag → assert 204.
2. ETag mismatch → PUT returns 412 with ERR_PRECONDITION. Steps: GET ETag1; simulate concurrent update (change RowVersion); PUT with old ETag → assert 412.
3. Business conflict → 409 ERR_CONCURRENCY_CONFLICT. Scenario: two clients perform conflicting business operations causing application-level conflict (e.g., duplicate code) → assert 409.
4. Ensure ETag header format: ETag: "\"{base64}\"" and If‑Match uses same value.

---

## 8. Logging & observability
- Log DbUpdateConcurrencyException with traceId and involved entity id(s).
- Expose traceId in error envelope for debugging.

---

## 9. Best practices (tóm tắt)
- Áp dụng RowVersion cho entities được liệt kê ở Scope (SDD).
- Dùng ETag + If‑Match cho HTTP contract; trả 412 cho precondition failure.
- Không expose raw byte[]; sử dụng Base64 trong ETag hoặc DTO khi cần.
- Bắt DbUpdateConcurrencyException, map sang ConcurrencyException, trả mã lỗi chuẩn theo SDD.

---

Nếu bạn muốn, tôi sẽ: thêm ví dụ controller/handler thực tế, thêm wrapper repository xử lý DbUpdateConcurrencyException, hoặc tạo test project mẫu cho các test cases trên. Chọn hành động và tôi sẽ thực hiện.
