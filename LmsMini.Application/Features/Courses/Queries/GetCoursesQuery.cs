using MediatR;
using System.Collections.Generic;
using LmsMini.Application.DTOs;

namespace LmsMini.Application.Features.Courses.Queries;

public class GetCoursesQuery : IRequest<List<CourseDto>> { }
