# RowVersion & Optimistic Concurrency � H�?ng d?n nhanh

T�i li?u nh? n�y gi?i th�ch c�ch c?u h?nh v� x? l? tr�?ng RowVersion (SQL rowversion / timestamp) trong d? �n LmsMini. Bao g?m: scaffold behavior, c?u h?nh EF Core, mapping DTO, x? l? xung �?t khi SaveChanges v� v� d? code ng?n.

---

## 1. M?c ��ch
RowVersion ��?c d�ng l�m optimistic concurrency token. Khi nhi?u client c�ng c?p nh?t c�ng m?t b?n ghi, EF s? ph�t hi?n xung �?t v� n�m DbUpdateConcurrencyException. Ta c� th? b?t l?i n�y �? tr? 409 Conflict, retry ho?c h?p nh?t theo nghi?p v?.

---

## 2. Scaffold t? database
- N?u c?t trong DB l� ki?u `rowversion` / `timestamp`, l?nh `dotnet ef dbcontext scaffold` th�?ng t?o:
  - Property `byte[] RowVersion` trong entity.
  - Fluent API trong `OnModelCreating` v?i `.IsRowVersion()` / `.IsConcurrencyToken()` trong DbContext.
- N?u scaffold kh�ng sinh Fluent API, th�m th? c�ng (xem ph?n 3).

---

## 3. C?u h?nh EF Core (DbContext)
V� d? (�? c� trong `LmsDbContext`):

```csharp
modelBuilder.Entity<Course>(entity =>
{
    // ... c�c c?u h?nh kh�c ...
    entity.Property(e => e.RowVersion)
          .IsRowVersion()
          .IsConcurrencyToken();
});
```

Ghi ch�: `.IsRowVersion()` �?m b?o EF hi?u �� l� tr�?ng rowversion v� s? so s�nh gi� tr? khi update.

---

## 4. Entity (v� d?)
Entity scaffold th�?ng tr�ng nh� sau:

```csharp
public partial class Course
{
    public Guid Id { get; set; }
    // ... c�c tr�?ng kh�c ...
    public byte[] RowVersion { get; set; } = null!;
}
```

B?n c� th? d�ng attribute thay cho Fluent API:
```csharp
[Timestamp]
public byte[] RowVersion { get; set; }
```

---

## 5. DTO & mapping
- KH�NG tr? tr?c ti?p `byte[] RowVersion` v�o client n?u kh�ng c?n thi?t.
- N?u mu?n client g?i gi� tr? RowVersion khi c?p nh?t (optimistic concurrency), m? h�a Base64.

V� d? DTO nh?n c?p nh?t (client g?i rowVersionBase64):

```csharp
public class UpdateCourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    // rowversion ? client d�?i d?ng Base64
    public string? RowVersionBase64 { get; set; }
}
```

Trong handler: chuy?n Base64 -> byte[] v� g�n v�o entity tr�?c SaveChanges.

```csharp
if (!string.IsNullOrEmpty(dto.RowVersionBase64))
{
    course.RowVersion = Convert.FromBase64String(dto.RowVersionBase64);
}
```

---

## 6. X? l? DbUpdateConcurrencyException (repository / handler)
V� d? repository save v?i x? l? xung �?t:

```csharp
try
{
    await _context.SaveChangesAsync(cancellationToken);
}
catch (DbUpdateConcurrencyException ex)
{
    // Log, mapping ho?c n�m l?i m?t exception chuy�n bi?t
    throw new ConcurrencyException("Entity update conflict", ex);
}
```

Trong handler / controller, b?t ConcurrencyException v� tr? HTTP 409:

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

Ho?c tr? `409` k�m d? li?u hi?n t?i �? client hi?n th? v� refetch.

---

## 7. V� d? ho�n ch?nh (handler update ��n gi?n)

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
  1. Client A �?c resource (L?y rowVersion, c� th? Base64).
  2. Client B c?p nh?t resource.
  3. Client A c? g?ng c?p nh?t l?i d�ng rowVersion c? -> server n�m 409.
- Vi?t unit/integration tests m� ph?ng DbUpdateConcurrencyException.

---

## 9. T�m t?t (best practices)
- Gi? `RowVersion` trong DB v� c?u h?nh `.IsRowVersion()` trong DbContext.
- Khi tr? DTO cho client: omit `RowVersion` ho?c encode Base64 n?u client c?n g?i l?i.
- B?t `DbUpdateConcurrencyException` v� x? l? tr? 409 ho?c retry theo nghi?p v?.
- Document flow cho frontend (client ph?i g?i l?i rowVersion khi c?p nh?t n?u d�ng optimistic concurrency).

---

N?u b?n mu?n, t�i c� th?: th�m v� d? handler/repository file v�o repo, c?p nh?t ImplementCreateCourseGuide.md v?i link t?i t�i li?u n�y, ho?c t?o test case m?u. Ch?n m?t h�nh �?ng v� t�i s? th?c hi?n.