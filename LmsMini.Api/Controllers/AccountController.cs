using LmsMini.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace LmsMini.Api.Controllers
{
    /// <summary>
    /// Controller xử lý tài khoản: đăng ký và đăng nhập.
    /// </summary>
    /// <remarks>
    /// Quy trình đăng nhập (tóm tắt):
    /// - Kiểm tra request.
    /// - Tìm user bằng email và kiểm tra mật khẩu.
    /// - Lấy roles và tạo claims cho JWT.
    /// - Lấy khóa JWT từ cấu hình (Jwt:Key); nếu thiếu thì trả lỗi server.
    /// - Chuyển khóa sang bytes, tạo SymmetricSecurityKey và SigningCredentials.
    /// - Xây dựng JwtSecurityToken (issuer, audience, claims, expiry) và trả token.
    /// - Tránh truyền chuỗi null cho Encoding.UTF8.GetBytes để tránh CS8604.
    /// </remarks>
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase // Inherit from ControllerBase to access BadRequest and other helper methods
    {
        private readonly UserManager<AspNetUser> _userManager;
        private readonly SignInManager<AspNetUser> _signInManager;
        private readonly IConfiguration _config;

        public AccountController(UserManager<AspNetUser> userManager, SignInManager<AspNetUser> signInManager, IConfiguration config)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _config = config;
        }

        // dang ky
        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterRequest req)
        {
            var user = new AspNetUser
            {
                UserName = req.Email,
                Email = req.Email
            };
            var result = await _userManager.CreateAsync(user, req.Password);
            if (!result.Succeeded)
            {
                return BadRequest(result.Errors);
            }
            return Ok();
        }

        // dang nhap
        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginRequest req)
        {
            // Tìm user theo email
            var user = await _userManager.FindByEmailAsync(req.Email);
            if (user == null)
            {
                // Không tìm thấy -> Unauthorized
                return Unauthorized();
            }

            // Kiểm tra mật khẩu
            var pwOk = await _userManager.CheckPasswordAsync(user, req.Password);
            if (!pwOk)
            {
                // Mật khẩu sai -> Unauthorized
                return Unauthorized();
            }

            // Lấy roles và tạo danh sách claims cho JWT
            var roles = await _userManager.GetRolesAsync(user);
            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty)
            };

            // Thêm claim cho mỗi role
            claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));

            // Lấy khóa JWT từ cấu hình và kiểm tra
            var jwtKey = _config["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                return StatusCode(500, "JWT key is not configured.");
            }

            // Tạo signing credentials
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // Lấy issuer/audience/expiry từ cấu hình (mặc định 60 phút)
            var issuer = _config["Jwt:Issuer"];
            var audience = _config["Jwt:Audience"];
            var expiresInMinutes = 60;
            if (int.TryParse(_config["Jwt:ExpiresInMinutes"], out var minutes))
            {
                expiresInMinutes = minutes;
            }

            // Tạo token
            var tokenDescriptor = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiresInMinutes),
                signingCredentials: creds
            );

            var token = new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);

            return Ok(new { token });
        }
    }
}
