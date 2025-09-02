using LmsMini.Application.DTOs;
using MediatR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LmsMini.Application.Features.Courses.Queries
{
    /// <summary>
    /// Đại diện cho truy vấn để lấy danh sách khóa học.
    /// </summary>
    /// <remarks>
    /// Truy vấn này được dùng để yêu cầu một tập hợp các khóa học, được biểu diễn bởi <see cref="CourseDto"/>.
    /// Thông thường truy vấn sẽ được xử lý bởi một mediator hoặc handler để xử lý yêu cầu và trả về kết quả.
    /// </remarks>
    public record GetCoursesQuery : IRequest<List<CourseDto>>;
}
