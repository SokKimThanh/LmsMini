using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LmsMini.Domain.Entities.Identity
{
    public partial class ApplicationUser : IdentityUser<Guid>
    {
    }
}
