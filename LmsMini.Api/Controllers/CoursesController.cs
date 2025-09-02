using LmsMini.Application.Features.Courses.Commands;
using LmsMini.Application.Features.Courses.Queries;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace LmsMini.Api.Controllers
{
    /// <summary>
    /// Cung cấp các điểm cuối để quản lý khóa học, bao gồm tạo, truy xuất và liệt kê các khóa học.
    /// </summary>
    /// <remarks>Điều khiển này xử lý các yêu cầu HTTP liên quan đến khóa học và ủy quyền xử lý thực tế
    /// cho lớp ứng dụng bên dưới thông qua MediatR. Nó hỗ trợ tạo khóa học mới, truy xuất một khóa học cụ thể
    /// theo định danh (id) và liệt kê tất cả các khóa học có sẵn.</remarks>
    [ApiController]
    [Route("api/[controller]")]
    public class CoursesController : ControllerBase
    {
        // mediatR
        private readonly IMediator _mediator;

        // import the mediator
        public CoursesController(IMediator mediator)
        {
            _mediator = mediator;
        }

        // create course command
        [HttpPost]
        public async Task<IActionResult> CreateCourse([FromBody] CreateCourseCommand command)
        {
            var courseId = await _mediator.Send(command);
            return CreatedAtAction(nameof(GetCourseById), new { id = courseId }, null);
        }

        // get course by id
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetCourseById(Guid id)
        {
            var course = await _mediator.Send(new GetCourseByIdQuery(id));
            if (course == null)
            {
                return NotFound();
            }
            return Ok(course);
        }

        // get course
        [HttpGet]
        public async Task<IActionResult> GetCourses()
        {
            var courses = await _mediator.Send(new GetCoursesQuery());
            return Ok(courses);
        }
    }
}