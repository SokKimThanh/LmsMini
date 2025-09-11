// wire-up serilog, swagger, automapper, mediatR
using FluentValidation;
using FluentValidation.AspNetCore;
using LmsMini.Application.Features.Courses.Commands;
using LmsMini.Application.Interfaces;
using LmsMini.Domain.Entities;
using LmsMini.Infrastructure.Repositories;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using Serilog;
using Microsoft.AspNetCore.Identity;
using LmsMini.Infrastructure.Services;

// ======================================================================
// 1. Khởi tạo Serilog (chạy trước khi tạo `builder` để bắt log khởi tạo)
// ======================================================================
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);

// ======================================================================
// 2. Thay thế logger mặc định của Host bằng Serilog
// ======================================================================
builder.Host.UseSerilog();

// ======================================================================
// 3. Cấu hình dịch vụ chung (Service registrations)
//    3.1 Đăng ký DbContext (kết nối CSDL)
// ======================================================================
builder.Services.AddDbContext<LmsDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ======================================================================
// 3.2 Đăng ký Repository và các DI khác
// ======================================================================
builder.Services.AddScoped<ICourseRepository, CourseRepository>();

// ======================================================================
// 3.3 Đăng ký AutoMapper (quét tất cả assemblies hiện tại)
// ======================================================================
builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());

// ======================================================================
// 3.4 Đăng ký MediatR (command/query handlers)
// ======================================================================
builder.Services.AddMediatR(AppDomain.CurrentDomain.GetAssemblies());

// ======================================================================
// 3.5 Đăng ký dịch vụ JWT
// ======================================================================
builder.Services.AddScoped<IJwtService, JwtService>();

// ======================================================================
// 3.6 Đăng ký FluentValidation
// ======================================================================
builder.Services.AddControllers();
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddFluentValidationClientsideAdapters();
builder.Services.AddValidatorsFromAssemblies(AppDomain.CurrentDomain.GetAssemblies());

// ======================================================================
// 3.7 Đăng ký Swagger/OpenAPI (cấu hình bảo mật, JWT nếu cần)
// ======================================================================
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "LmsMini API", Version = "v1" });

    // Cấu hình JWT Bearer Auth trong Swagger (nếu cần)
    c.AddSecurityDefinition("Bearer", new()
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });

    c.AddSecurityRequirement(new()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// ======================================================================
// 3.8 Đăng ký Identity
//    Ghi chú: `AspNetUser` và `LmsDbContext` đã được cấu hình cho Identity.
// ======================================================================
builder.Services.AddIdentity<AspNetUser, IdentityRole<Guid>>(options =>
{
    // Thiết lập mật khẩu (tùy chỉnh nếu cần)
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;

    // Thiết lập người dùng
    options.User.RequireUniqueEmail = true;
})
    .AddEntityFrameworkStores<LmsDbContext>()
    .AddDefaultTokenProviders();

var app = builder.Build();

// ======================================================================
// 4. Cấu hình middleware (the request pipeline)
//    4.1 Bật Serilog request logging để ghi log các request
// ======================================================================
app.UseSerilogRequestLogging();

// ======================================================================
// 4.2 Bật Swagger chỉ trong môi trường phát triển
// ======================================================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "LmsMini API v1"));
}

// ======================================================================
// 4.3 Middleware chung: HTTPS, Authentication, Authorization, Controllers
// ======================================================================
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ======================================================================
// 5. Chạy ứng dụng
// ======================================================================
app.Run();
