using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LmsMini.Domain.Entities;
using LmsMini.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace LmsMini.Infrastructure.Repositories
{

    /**
    /// <summary>
    /// Cung cấp các phương thức để quản lý và truy xuất dữ liệu khóa học từ kho dữ liệu nền tảng.
    /// </summary>
    /// <remarks>Kho lưu trữ này chịu trách nhiệm thực hiện các thao tác liên quan đến thực thể <see cref="Course"/>
    /// như thêm khóa học mới, truy xuất tất cả khóa học, hoặc lấy một khóa học cụ thể theo định danh.
    /// Nó sử dụng một thể hiện của <see cref="LmsDbContext"/> để tương tác với cơ sở dữ liệu.</remarks>
    */
    public class CourseRepository : ICourseRepository
    {
        private readonly LmsDbContext _context;
        public CourseRepository(LmsDbContext context)
        {
            _context = context;
        }
        public async Task AddAsync(Course course, CancellationToken cancellationToken = default)
        {
            _context.Courses.Add(course);
            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            // AsNoTracking tối ưu hiệu suất khi chỉ đọc dữ liệu
            return await _context.Courses.AsNoTracking().ToListAsync(cancellationToken);
        }

        public async Task<Course?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        {
            // Sử dụng FindAsync để tìm kiếm theo khóa chính
            return await _context.Courses.FindAsync(new object[] { id }, cancellationToken);
        }
    }
}
