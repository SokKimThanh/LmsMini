using AutoMapper;
using LmsMini.Application.DTOs;
using LmsMini.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LmsMini.Application.Mappings
{
    /// <summary>
    /// Cấu hình ánh xạ giữa các đối tượng <see cref="Course"/> và <see cref="CourseDto"/>.
    /// </summary>
    /// <remarks>Profile này tự động ánh xạ các thuộc tính có cùng tên giữa <see cref="Course"/> và <see cref="CourseDto"/>.
    /// Dùng để định nghĩa các quy tắc ánh xạ cho AutoMapper.</remarks>
    public class CourseProfile : Profile
    {
        public CourseProfile()
        {
            // Tự động ánh xạ giữa các đối tượng có cùng tên thuộc tính
            CreateMap<Course, CourseDto>();
        }
    }
}
