using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Lesson
{
    public Guid Id { get; set; }

    public Guid ModuleId { get; set; }

    public string Title { get; set; } = null!;

    public string ContentType { get; set; } = null!;

    public string? ContentUrl { get; set; }

    public int? DurationSec { get; set; }

    public int Order { get; set; }

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public byte[] RowVersion { get; set; } = null!;

    public virtual Module Module { get; set; } = null!;

    public virtual ICollection<Progress> Progresses { get; set; } = new List<Progress>();
}
