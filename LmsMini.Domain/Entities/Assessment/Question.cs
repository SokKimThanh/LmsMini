using System;
using System.Collections.Generic;

namespace LmsMini.Domain.Entities;

public partial class Question
{
    public Guid Id { get; set; }

    public Guid QuizId { get; set; }

    public string Text { get; set; } = null!;

    public int Order { get; set; }

    public DateTime CreatedAt { get; set; }

    public Guid CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Guid? UpdatedBy { get; set; }

    public bool IsDeleted { get; set; }

    public byte[] RowVersion { get; set; } = null!;

    public virtual ICollection<AttemptAnswer> AttemptAnswers { get; set; } = new List<AttemptAnswer>();

    public virtual ICollection<Option> Options { get; set; } = new List<Option>();

    public virtual Quiz Quiz { get; set; } = null!;
}
