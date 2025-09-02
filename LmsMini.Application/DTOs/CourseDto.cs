using System;

namespace LmsMini.Application.DTOs
{
    /// <summary>
    /// Đại diện cho một đối tượng truyền dữ liệu (DTO) cho một khóa học, chứa các thông tin chính
    /// như mã định danh, mã khóa học, tiêu đề, mô tả, trạng thái và ngày tạo.
    /// </summary>
    /// <remarks>
    /// Lớp này thường được sử dụng để chuyển dữ liệu liên quan đến khóa học giữa các tầng của ứng dụng,
    /// chẳng hạn như từ cơ sở dữ liệu tới client.
    /// </remarks>
    public class CourseDto
    {
        public Guid Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
