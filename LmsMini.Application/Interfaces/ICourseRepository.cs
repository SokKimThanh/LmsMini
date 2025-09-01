using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LmsMini.Domain.Entities;

namespace LmsMini.Application.Interfaces
{
    /// <summary>
    /// Định nghĩa hợp đồng để quản lý và truy xuất dữ liệu khóa học.
    /// </summary>
    /// <remarks>Giao diện này cung cấp các phương thức để thêm, truy xuất và truy vấn các khóa học.
    /// Các triển khai của giao diện này được mong đợi xử lý các thao tác lưu trữ và truy xuất dữ liệu cho thực thể <see cref="Course"/>.</remarks>
    public interface ICourseRepository
    {
        Task AddAsync(Course course, CancellationToken cancellationToken = default);
        Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<Course?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    }
}
