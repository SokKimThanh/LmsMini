# RowVersion & Optimistic Concurrency — Hý?ng d?n nhanh

Tài li?u nh? này gi?i thích cách c?u h?nh và x? l? trý?ng RowVersion (SQL rowversion / timestamp) trong d? án LmsMini. Bao g?m: scaffold behavior, c?u h?nh EF Core, mapping DTO, x? l? xung ð?t khi SaveChanges và ví d? code ng?n.

---

## 1. M?c ðích
RowVersion ðý?c dùng làm optimistic concurrency token. Khi nhi?u client cùng c?p nh?t cùng m?t b?n ghi, EF s? phát hi?n xung ð?t và ném DbUpdateConcurrencyException. Ta có th? b?t l?i này ð? tr? 409 Conflict, retry ho?c h?p nh?t theo nghi?p v?.

---

## 2. Scaffold t? database
- N?u c?t trong DB là ki?u `rowversion` / `timestamp`, l?nh `dotnet ef dbcontext scaffold` thý?ng t?o:
  - Property `byte[] RowVersion` trong entity.
  - Fluent API trong `OnModelCreating` v?i `.IsRowVersion()` / `.IsConcurrencyToken()` trong DbContext.
- N?u scaffold không sinh Fluent API, thêm th? công (xem ph?n 3).

---

## 3. C?u h?nh EF Core (DbContext)
Ví d? (ð? có trong `LmsDbContext`):

```csharp
modelBuilder.Entity<Course>(entity =>
{
    // ... các c?u h?nh khác ...
    entity.Property(e => e.RowVersion)
          .IsRowVersion()
          .IsConcurrencyToken();
});
```

Ghi chú: `.IsRowVersion()` ð?m b?o EF hi?u ðó là trý?ng rowversion và s? so sánh giá tr? khi update.

---

## 4. Entity (ví d?)
Entity scaffold thý?ng trông nhý sau:

```csharp
public partial class Course
{
    public Guid Id { get; set; }
    // ... các trý?ng khác ...
    public byte[] RowVersion { get; set; } = null!;
}
```

B?n có th? dùng attribute thay cho Fluent API:
```csharp
[Timestamp]
public byte[] RowVersion { get; set; }
```

---

## 5. DTO & mapping
- KHÔNG tr? tr?c ti?p `byte[] RowVersion` vào client n?u không c?n thi?t.
- N?u mu?n client g?i giá tr? RowVersion khi c?p nh?t (optimistic concurrency), m? hóa Base64.

Ví d? DTO nh?n c?p nh?t (client g?i rowVersionBase64):

```csharp
public class UpdateCourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    // rowversion ? client dý?i d?ng Base64
    public string? RowVersionBase64 { get; set; }
}
```

Trong handler: chuy?n Base64 -> byte[] và gán vào entity trý?c SaveChanges.

```csharp
if (!string.IsNullOrEmpty(dto.RowVersionBase64))
{
    course.RowVersion = Convert.FromBase64String(dto.RowVersionBase64);
}
```

---

## 6. X? l? DbUpdateConcurrencyException (repository / handler)
Ví d? repository save v?i x? l? xung ð?t:

```csharp
try
{
    await _context.SaveChangesAsync(cancellationToken);
}
catch (DbUpdateConcurrencyException ex)
{
    // Log, mapping ho?c ném l?i m?t exception chuyên bi?t
    throw new ConcurrencyException("Entity update conflict", ex);
}
```

Trong handler / controller, b?t ConcurrencyException và tr? HTTP 409:

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

Ho?c tr? `409` kèm d? li?u hi?n t?i ð? client hi?n th? và refetch.

---

## 7. Ví d? hoàn ch?nh (handler update ðõn gi?n)

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

## 8. Ki?m tra & testing
- Test scenario:
  1. Client A ð?c resource (L?y rowVersion, có th? Base64).
  2. Client B c?p nh?t resource.
  3. Client A c? g?ng c?p nh?t l?i dùng rowVersion c? -> server ném 409.
- Vi?t unit/integration tests mô ph?ng DbUpdateConcurrencyException.

---

## 9. Tóm t?t (best practices)
- Gi? `RowVersion` trong DB và c?u h?nh `.IsRowVersion()` trong DbContext.
- Khi tr? DTO cho client: omit `RowVersion` ho?c encode Base64 n?u client c?n g?i l?i.
- B?t `DbUpdateConcurrencyException` và x? l? tr? 409 ho?c retry theo nghi?p v?.
- Document flow cho frontend (client ph?i g?i l?i rowVersion khi c?p nh?t n?u dùng optimistic concurrency).

---

N?u b?n mu?n, tôi có th?: thêm ví d? handler/repository file vào repo, c?p nh?t ImplementCreateCourseGuide.md v?i link t?i tài li?u này, ho?c t?o test case m?u. Ch?n m?t hành ð?ng và tôi s? th?c hi?n.