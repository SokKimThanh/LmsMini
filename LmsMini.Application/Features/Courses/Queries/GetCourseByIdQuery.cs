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
    /// Đại diện cho truy vấn để lấy thông tin một khóa học theo định danh duy nhất.
    /// </summary>
    /// <param name="Id">Định danh (Id) duy nhất của khóa học cần truy xuất.</param>
    public record GetCourseByIdQuery(Guid Id) : IRequest<CourseDto?>;
}
