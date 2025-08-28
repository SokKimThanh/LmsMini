using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Progress
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid LessonId { get; set; }

    public DateTime? CompletedAt { get; set; }

    public byte Percent { get; set; }

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public virtual Lesson Lesson { get; set; } = null!;

    public virtual AspNetUser User { get; set; } = null!;
}
