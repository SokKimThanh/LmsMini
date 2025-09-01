using MediatR;
using System;

namespace LmsMini.Application.Features.Courses.Commands
{
    /// <summary>
    /// DTO for creating a new course.
    /// </summary>
    public class CreateCourseCommand : IRequest<Guid>
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }
}
