using MediatR;
using System;

namespace LmsMini.Application.Features.Courses.Commands
{
    /// <summary>
    /// DTO để tạo một khóa học mới.
    /// </summary>
    public class CreateCourseCommand : IRequest<Guid>
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public Guid CreatedBy { get; set; }
    }
}
