using MediatR;
using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;
using LmsMini.Application.Features.Courses.Commands;
using System.Threading;
using System.Threading.Tasks;
using System;

namespace LmsMini.Application.Features.Courses.Handlers;

public class CreateCourseCommandHandler : IRequestHandler<CreateCourseCommand, Guid>
{
    private readonly ICourseRepository _courseRepository;

    public CreateCourseCommandHandler(ICourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    public async Task<Guid> Handle(CreateCourseCommand request, CancellationToken cancellationToken)
    {
        var course = new Course
        {
            Id = Guid.NewGuid(),
            Code = Guid.NewGuid().ToString("N").Substring(0, 8),
            Title = request.Title,
            Description = request.Description,
            Status = "Draft",
            CreatedBy = Guid.Empty, // TODO: replace with current user
            CreatedAt = DateTime.UtcNow,
            IsDeleted = false
        };

        await _courseRepository.AddAsync(course, cancellationToken);
        return course.Id;
    }
}
