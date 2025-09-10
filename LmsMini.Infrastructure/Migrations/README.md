# EF Core Migrations for LmsMini.Infrastructure

This folder contains guidance for creating and applying EF Core migrations related to the Infrastructure project.

Important notes:
- Identity has been configured to use `AspNetUser` and the `LmsDbContext` extends `IdentityDbContext<AspNetUser, IdentityRole<Guid>, Guid>`.
- Do not commit secret keys to source control. Use `dotnet user-secrets` or environment variables for local development.

Creating the initial Identity migration (example):

1. Ensure the `LmsMini.Api` project is the startup project (the web project that provides the configuration and connection string).
2. Run the following command from the solution root (adjust paths if necessary):

```bash
dotnet ef migrations add Init_Identity -s LmsMini.Api -p LmsMini.Infrastructure -o Migrations/Init_Identity
```

3. Inspect the generated migration files and adjust if necessary.

Applying the migration to the database:

```bash
dotnet ef database update -s LmsMini.Api -p LmsMini.Infrastructure
```

If you encounter errors about multiple provider packages or missing tools, ensure the following packages are referenced in `LmsMini.Infrastructure.csproj`:

- Microsoft.EntityFrameworkCore
- Microsoft.EntityFrameworkCore.Design
- Microsoft.EntityFrameworkCore.SqlServer
- Microsoft.AspNetCore.Identity.EntityFrameworkCore

You may also need to install the EF Core CLI tool:

```bash
dotnet tool install --global dotnet-ef
```

Happy migrating!