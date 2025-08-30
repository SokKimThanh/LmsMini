using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LmsMini.Domain.Entities;

namespace LmsMini.Application.Interfaces
{
    public interface ICourseRepository
    {
        Task AddAsync(Course course, CancellationToken cancellationToken = default);
        Task<List<Course>> GetAllAsync(CancellationToken cancellationToken = default);
        Task<Course?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    }
}
