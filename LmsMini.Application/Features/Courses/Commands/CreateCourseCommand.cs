using MediatR;

namespace LmsMini.Application.Features.Courses.Commands;

public class CreateCourseCommand : IRequest<Guid>
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
