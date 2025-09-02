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

    /// <summary>
    /// Xử lý việc truy xuất danh sách khóa học theo truy vấn được cung cấp.
    /// </summary>
    /// <remarks>Lớp này xử lý <see cref="GetCoursesQuery"/> và trả về một danh sách các khóa học dưới dạng <see cref="CourseDto"/>.
    /// Nó sử dụng <see cref="ICourseRepository"/> để lấy dữ liệu khóa học và <see cref="IMapper"/> để ánh xạ dữ liệu sang DTO tương ứng.</remarks>
    public class GetCoursesQueryHandler : IRequestHandler<GetCoursesQuery, List<CourseDto>>
    {
        ICourseRepository _repo;
        IMapper _mapper;

        public GetCoursesQueryHandler(ICourseRepository courseRepository, IMapper mapper)
        {
            _repo = courseRepository;
            _mapper = mapper;
        }
        public async Task<List<CourseDto>> Handle(GetCoursesQuery request, CancellationToken cancellationToken)
        {
            var courses = await _repo.GetAllAsync(cancellationToken);
            return _mapper.Map<List<CourseDto>>(courses);
        }
    }
}
