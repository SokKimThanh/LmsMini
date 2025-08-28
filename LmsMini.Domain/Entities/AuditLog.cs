using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class AuditLog
{
    public Guid Id { get; set; }

    public Guid? UserId { get; set; }

    public string Action { get; set; } = null!;

    public string Entity { get; set; } = null!;

    public Guid? EntityId { get; set; }

    public string? Data { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual AspNetUser? User { get; set; }
}
