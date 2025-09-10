/* PSEUDOCODE PLAN (detailed):
- Mục tiêu:
  - Giải thích ngắn gọn chức năng của phương thức `CreateToken`.
  - Biên tập (chuyển) các comment / XML doc sang tiếng Việt.
  - Giữ nguyên logic hiện có, chỉ thêm chú thích bằng tiếng Việt để dễ hiểu.

- Các bước thực hiện trong file:
  1. Thêm phần mô tả (XML doc) cho lớp `JwtService` bằng tiếng Việt.
  2. Thêm phần mô tả (XML doc) cho các phương thức `CreateToken` và `ValidateToken` bằng tiếng Việt.
  3. Trong thân `CreateToken`, thêm các comment nội tuyến tiếng Việt mô tả từng bước:
     - Tạo danh sách claim cơ bản (sub, email, name).
     - Chuyển các role thành claim kiểu `ClaimTypes.Role`.
     - Tạo `SymmetricSecurityKey` từ `_opts.Key`.
     - Tạo `SigningCredentials` với thuật toán HMAC SHA256.
     - Tạo `JwtSecurityToken` với issuer, audience, claims, expiry và signing credentials.
     - Trả về chuỗi token đã ký bằng `JwtSecurityTokenHandler`.
  4. Không thay đổi logic tạo token (giữ tương thích với các cấu hình JWT).
  5. Giữ `ValidateToken` như hiện tại (ném `NotImplementedException`) nhưng thêm mô tả bằng tiếng Việt.

- Lưu ý:
  - Mục tiêu là giải thích và biên tập comment, không sửa chức năng hiện có.
  - Pseudocode được đặt ở đây dưới dạng comment ở đầu file để tuân thủ yêu cầu "mô tả kế hoạch" trước khi xuất code.
*/

using LmsMini.Application.Auth;
using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace LmsMini.Infrastructure.Services
{
    /// <summary>
    /// Dịch vụ JWT chịu trách nhiệm tạo và xác thực JSON Web Tokens (JWT).
    /// </summary>
    /// <remarks>
    /// Lớp này sử dụng các cấu hình trong <see cref="JwtOptions"/> để tạo token đã được ký (HMAC).
    /// Các token chứa các claim cơ bản của người dùng và các claim vai trò.
    /// </remarks>
    public class JwtService : IJwtService
    {
        private readonly JwtOptions _opts;
        private readonly TokenValidationParameters _validationParams;

        /// <summary>
        /// Khởi tạo <see cref="JwtService"/> với các tùy chọn JWT được cung cấp qua <see cref="IOptions{JwtOptions}"/>.
        /// </summary>
        /// <param name="opts">Cấu hình JWT (issuer, audience, key, expires...)</param>
        public JwtService(IOptions<JwtOptions> opts)
        {
            _opts = opts.Value;
            var keybite = Encoding.UTF8.GetBytes(_opts.Key) ?? throw new InvalidOperationException("Jwt: Key is not configured");
            _validationParams = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = _opts.Issuer,
                ValidAudience = _opts.Audience,
                IssuerSigningKey = new SymmetricSecurityKey(keybite),
                ClockSkew = TimeSpan.Zero // Loại bỏ độ trễ thời gian mặc định 5 phút
            };
        }

        /// <summary>
        /// Tạo một JWT cho người dùng đã cho, bao gồm các vai trò tương ứng.
        /// </summary>
        /// <param name="user">Thực thể người dùng (AspNetUser) để nhúng thông tin vào token.</param>
        /// <param name="roles">Danh sách tên vai trò của người dùng để thêm vào claim.</param>
        /// <returns>Chuỗi token JWT đã được ký.</returns>
        public string CreateToken(AspNetUser user, IEnumerable<string> roles)
        {
            // Tạo danh sách các claim cơ bản cho token:
            // - sub: id của người dùng
            // - email: email của người dùng (nếu có)
            // - name: username (nếu có)
            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
            };

            // Chuyển các role thành claim kiểu ClaimTypes.Role và nối vào danh sách claim
            // (claims.Concat(...) được truyền trực tiếp vào JwtSecurityToken constructor).
            // Tạo khoá ký (symmetric key) từ _opts.Key (chuỗi ký).
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_opts.Key));

            // Tạo SigningCredentials sử dụng HMAC SHA256
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // Tạo token với issuer, audience, claims (bao gồm role claims), thời hạn và signing credentials
            var token = new JwtSecurityToken(
                issuer: _opts.Issuer,
                audience: _opts.Audience,
                claims: claims.Concat(roles.Select(role => new Claim(ClaimTypes.Role, role))),
                expires: DateTime.UtcNow.AddMinutes(_opts.ExpiresInMinutes),
                signingCredentials: creds
            );

            // Chuyển JwtSecurityToken thành chuỗi JWT đã ký và trả về
            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        /// <summary>
        /// Xác thực một token JWT và trả về <see cref="ClaimsPrincipal"/> nếu token hợp lệ.
        /// </summary>
        /// <param name="token">Chuỗi token JWT cần xác thực.</param>
        /// <returns>
        /// Một <see cref="ClaimsPrincipal"/> chứa các claim nếu token hợp lệ;
        /// trả về null nếu token không hợp lệ hoặc đã hết hạn.
        /// </returns>
        public ClaimsPrincipal? ValidateToken(string token)
        {
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var principal = handler.ValidateToken(token, _validationParams, out var validatedToken);
                // Kiểm tra xem token đã được ký đúng thuật toán chưa
                if (validatedToken is not JwtSecurityToken jwtToken ||
                    !jwtToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
                {
                    return null; // Token không hợp lệ
                }
                return principal; // Trả về ClaimsPrincipal nếu token hợp lệ
            }
            catch
            {
                return null; // Trả về null nếu có lỗi trong quá trình xác thực (token không hợp lệ hoặc hết hạn)
            }
        }
    }
}
