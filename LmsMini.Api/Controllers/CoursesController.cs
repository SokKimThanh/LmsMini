using LmsMini.Application.Features.Courses.Commands;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace LmsMini.Api.Controllers
{
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

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetCourseById()
        {
            // TODO: implement this method later
            return NotFound();
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