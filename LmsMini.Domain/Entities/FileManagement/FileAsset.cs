using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class FileAsset
{
    public Guid Id { get; set; }

    public Guid OwnerUserId { get; set; }

    public string FileName { get; set; } = null!;

    public string MimeType { get; set; } = null!;

    public long Size { get; set; }

    public string StoragePath { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public virtual AspNetUser OwnerUser { get; set; } = null!;
}
