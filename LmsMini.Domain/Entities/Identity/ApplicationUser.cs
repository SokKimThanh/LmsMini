using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities.Identity
{
    // ApplicationUser extends IdentityUser<Guid> and holds domain navigations.
    // Keep this class focused on user-specific data only; audit fields remain on domain entities.
    public partial class ApplicationUser : IdentityUser<Guid>
    {
        // Optional profile fields useful for API / UI
        public string? FullName { get; set; }
        public string? DisplayName { get; set; }
        public string? ProfilePictureUrl { get; set; }
        public bool IsActive { get; set; } = true;

        // Navigation properties to domain entities (keep names consistent with existing mappings)
        public virtual ICollection<Course> Courses { get; set; } = new List<Course>();
        public virtual ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();
        public virtual ICollection<FileAsset> FileAssets { get; set; } = new List<FileAsset>();
        public virtual ICollection<Notification> NotificationSentByNavigations { get; set; } = new List<Notification>();
        public virtual ICollection<Notification> NotificationToUsers { get; set; } = new List<Notification>();
        public virtual ICollection<Progress> Progresses { get; set; } = new List<Progress>();
        public virtual ICollection<QuizAttempt> QuizAttempts { get; set; } = new List<QuizAttempt>();
        public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    }
}
