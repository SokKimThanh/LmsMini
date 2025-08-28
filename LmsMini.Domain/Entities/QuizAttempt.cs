using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class QuizAttempt
{
    public Guid Id { get; set; }

    public Guid QuizId { get; set; }

    public Guid UserId { get; set; }

    public DateTime StartedAt { get; set; }

    public DateTime? SubmittedAt { get; set; }

    public decimal? Score { get; set; }

    public virtual ICollection<AttemptAnswer> AttemptAnswers { get; set; } = new List<AttemptAnswer>();

    public virtual Quiz Quiz { get; set; } = null!;

    public virtual AspNetUser User { get; set; } = null!;
}
