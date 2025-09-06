using LmsMini.Domain.Entities.Identity;
using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Course
{
    public Guid Id { get; set; }

    public string Code { get; set; } = null!;

    public string Title { get; set; } = null!;

    public string? Description { get; set; }

    public string Status { get; set; } = null!;

    public Guid CreatedBy { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public byte[] RowVersion { get; set; } = null!;

    public virtual AspNetUser CreatedByNavigation { get; set; } = null!;

    public virtual ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();

    public virtual ICollection<Module> Modules { get; set; } = new List<Module>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Quiz> Quizzes { get; set; } = new List<Quiz>();
}
