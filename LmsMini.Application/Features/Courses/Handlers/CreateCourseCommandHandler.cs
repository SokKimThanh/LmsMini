using MediatR;
using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;
using LmsMini.Application.Features.Courses.Commands;

namespace LmsMini.Application.Features.Courses.Handlers
{
    /// <summary>
    /// Xử lý việc tạo khóa học mới bằng cách xử lý yêu cầu <see cref="CreateCourseCommand"/>.
    /// </summary>
    /// <remarks>
    /// Handler này tạo một thực thể Course mới với các thông tin được cung cấp, gán Id và Code duy nhất,
    /// đặt trạng thái ban đầu là "Draft" và lưu vào repository.
    /// </remarks>
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
                Code = Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                Title = request.Title,
                Description = request.Description,
                Status = "Draft",
                CreatedBy = Guid.Empty, // Thay bằng ID người dùng thực tế nếu có
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            await _courseRepository.AddAsync(course, cancellationToken);
            return course.Id;
        }
    }
}
