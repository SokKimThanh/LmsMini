using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class OutboxMessage
{
    public Guid Id { get; set; }

    public DateTime OccurredOn { get; set; }

    public string Type { get; set; } = null!;

    public string Payload { get; set; } = null!;

    public DateTime? ProcessedOn { get; set; }

    public string? Error { get; set; }

    public int RetryCount { get; set; }
}
