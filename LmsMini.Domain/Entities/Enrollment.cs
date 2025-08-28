using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Enrollment
{
    public Guid Id { get; set; }

    public Guid CourseId { get; set; }

    public Guid UserId { get; set; }

    public DateTime StartAt { get; set; }

    public DateTime? EndAt { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public virtual Course Course { get; set; } = null!;

    public virtual AspNetUser User { get; set; } = null!;
}
