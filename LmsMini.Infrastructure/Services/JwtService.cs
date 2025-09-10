using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;
using System.Security.Claims;

namespace LmsMini.Infrastructure.Services
{
    public class JwtService : IJwtService
    {
        public string CreateToken(AspNetUser user, IEnumerable<string> roles)
        {
            throw new NotImplementedException();
        }

        public ClaimsPrincipal? ValidateToken(string token)
        {
            throw new NotImplementedException();
        }
    }
}
