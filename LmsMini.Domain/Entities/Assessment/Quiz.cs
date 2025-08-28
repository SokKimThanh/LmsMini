using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Quiz
{
    public Guid Id { get; set; }

    public Guid CourseId { get; set; }

    public string Title { get; set; } = null!;

    public int? DurationSec { get; set; }

    public int? AttemptsAllowed { get; set; }

    public bool ShuffleAnswers { get; set; }

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public byte[] RowVersion { get; set; } = null!;

    public virtual Course Course { get; set; } = null!;

    public virtual ICollection<Question> Questions { get; set; } = new List<Question>();

    public virtual ICollection<QuizAttempt> QuizAttempts { get; set; } = new List<QuizAttempt>();
}
