using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace LmsMini.Domain.Entities;

public partial class AspNetUser : IdentityUser<Guid>
{
    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual ICollection<Course> Courses { get; set; } = new List<Course>();

    public virtual ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();

    public virtual ICollection<FileAsset> FileAssets { get; set; } = new List<FileAsset>();

    public virtual ICollection<Notification> NotificationSentByNavigations { get; set; } = new List<Notification>();

    public virtual ICollection<Notification> NotificationToUsers { get; set; } = new List<Notification>();

    public virtual ICollection<Progress> Progresses { get; set; } = new List<Progress>();

    public virtual ICollection<QuizAttempt> QuizAttempts { get; set; } = new List<QuizAttempt>();
}
