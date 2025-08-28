using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Module
{
    public Guid Id { get; set; }

    public Guid CourseId { get; set; }

    public string Title { get; set; } = null!;

    public int Order { get; set; }

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public byte[] RowVersion { get; set; } = null!;

    public virtual Course Course { get; set; } = null!;

    public virtual ICollection<Lesson> Lessons { get; set; } = new List<Lesson>();
}
