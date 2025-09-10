using LmsMini.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace LmsMini.Application.Interfaces
{
    /// <summary>
    /// Cung cấp các phương thức để tạo và xác thực JSON Web Tokens (JWT).
    /// </summary>
    /// <remarks>
    /// Giao diện này định nghĩa chức năng tạo JWT dựa trên thông tin người dùng và vai trò,
    /// cũng như xác thực và trích xuất các claim từ một token cho trước.
    /// </remarks>
    public interface IJwtService
    {
        /// <summary>
        /// Tạo một JWT cho người dùng đã cho, bao gồm các vai trò tương ứng.
        /// </summary>
        /// <param name="user">Thực thể người dùng (AspNetUser) để nhúng thông tin vào token.</param>
        /// <param name="roles">Danh sách tên vai trò của người dùng để thêm vào claim.</param>
        /// <returns>Chuỗi token JWT đã được ký.</returns>
        string CreateToken(AspNetUser user, IEnumerable<string> roles);

        /// <summary>
        /// Xác thực một token JWT và trả về đối tượng ClaimsPrincipal nếu token hợp lệ.
        /// </summary>
        /// <param name="token">Chuỗi token JWT cần xác thực.</param>
        /// <returns>
        /// Một ClaimsPrincipal chứa các claim nếu token hợp lệ; 
        /// trả về null nếu token không hợp lệ hoặc đã hết hạn.
        /// </returns>
        ClaimsPrincipal? ValidateToken(string token);
    }
}
