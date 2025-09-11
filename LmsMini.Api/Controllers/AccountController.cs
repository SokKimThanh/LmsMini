using LmsMini.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using LmsMini.Application.Interfaces;

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
        private readonly IJwtService _jwtService;

        private readonly IConfiguration _config;

        public AccountController(UserManager<AspNetUser> userManager, SignInManager<AspNetUser> signInManager, IConfiguration config, IJwtService jwtService)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _config = config;
            _jwtService = jwtService;
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
            var token = _jwtService.CreateToken(user, roles);

            return Ok(new { token });
        }
    }
}
