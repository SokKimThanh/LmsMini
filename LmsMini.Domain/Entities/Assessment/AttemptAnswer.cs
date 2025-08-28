using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class AttemptAnswer
{
    public Guid Id { get; set; }

    public Guid AttemptId { get; set; }

    public Guid QuestionId { get; set; }

    public Guid OptionId { get; set; }

    public virtual QuizAttempt Attempt { get; set; } = null!;

    public virtual Option Option { get; set; } = null!;

    public virtual Question Question { get; set; } = null!;
}
