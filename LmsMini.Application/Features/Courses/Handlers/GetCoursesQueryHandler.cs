using MediatR;
using LmsMini.Application.DTOs;
using LmsMini.Application.Interfaces;
using LmsMini.Application.Features.Courses.Queries;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace LmsMini.Application.Features.Courses.Handlers;

public class GetCoursesQueryHandler : IRequestHandler<GetCoursesQuery, List<CourseDto>>
{
    private readonly ICourseRepository _courseRepository;

    public GetCoursesQueryHandler(ICourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    public async Task<List<CourseDto>> Handle(GetCoursesQuery request, CancellationToken cancellationToken)
    {
        var courses = await _courseRepository.GetAllAsync(cancellationToken);
        return courses.Select(c => new CourseDto { Id = c.Id, Title = c.Title, Description = c.Description }).ToList();
    }
}
