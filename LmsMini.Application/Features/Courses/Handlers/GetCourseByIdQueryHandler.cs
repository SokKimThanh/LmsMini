using AutoMapper;
using LmsMini.Application.DTOs;
using LmsMini.Application.Features.Courses.Queries;
using LmsMini.Application.Interfaces;
using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LmsMini.Application.Features.Courses.Handlers
{
    public class GetCourseByIdQueryHandler : IRequestHandler<GetCourseByIdQuery, CourseDto?>
    {
        private readonly ICourseRepository _courseRepository;
        private readonly IMapper _mapper;
        public GetCourseByIdQueryHandler(ICourseRepository courseRepository, IMapper mapper)
        {
            _courseRepository = courseRepository;
            _mapper = mapper;
        }

        public async Task<CourseDto?> Handle(GetCourseByIdQuery request, CancellationToken cancellationToken)
        {
            var course = await _courseRepository.GetByIdAsync(request.Id, cancellationToken);
            if (course == null)
            {
                return null;
            }
            return _mapper.Map<CourseDto>(course);
        }
    }
}
