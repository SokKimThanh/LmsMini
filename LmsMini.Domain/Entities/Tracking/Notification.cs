using LmsMini.Domain.Entities.Identity;
using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Notification
{
    public Guid Id { get; set; }

    public Guid? CourseId { get; set; }

    public Guid? ToUserId { get; set; }

    public string Title { get; set; } = null!;

    public string? Body { get; set; }

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public Guid SentBy { get; set; }

    public virtual Course? Course { get; set; }

    public virtual AspNetUser SentByNavigation { get; set; } = null!;

    public virtual AspNetUser? ToUser { get; set; }
}
