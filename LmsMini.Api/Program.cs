// wire-up serilog, swagger, automapper, mediatR
using Microsoft.OpenApi.Models;
using Serilog;
using MediatR;
using FluentValidation;
using FluentValidation.AspNetCore;

// 1. Khởi tạo logger
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);

// 2. Thay thế default logger bằng Serilog
builder.Host.UseSerilog();

// 3. Đăng ký các dịch vụ
// 3.1 Đăng ký Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "LmsMini API", Version = "v1" });

    // Cấu hình JWT Bearer Auth
    c.AddSecurityDefinition("Bearer", new()
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
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

// 3.2 Đăng ký AutoMapper
builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());

// 3.3 Đăng ký MediatR
builder.Services.AddMediatR(AppDomain.CurrentDomain.GetAssemblies());

// 3.4 Đăng ký FluentValidation
builder.Services
    .AddControllers();
builder.Services
    .AddFluentValidationAutoValidation()
    .AddFluentValidationClientsideAdapters();

builder.Services.AddValidatorsFromAssemblies(AppDomain.CurrentDomain.GetAssemblies());

var app = builder.Build();

// 4. Cấu hình middleware
// 4.1 Bật request logging với Serilog
app.UseSerilogRequestLogging();

// 4.2 Cấu hình Swagger cho môi trường phát triển
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "LmsMini API v1"));
}

// 4.3 Cấu hình các middleware khác
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// 5. Chạy ứng dụng
app.Run();
