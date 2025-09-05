SET NOCOUNT ON;

-- 1) Create database if not exists
IF DB_ID('LMSMini') IS NULL
BEGIN
    PRINT 'Creating database LMSMini...';
    CREATE DATABASE [LMSMini];
END
GO

USE [LMSMini];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 2) Drop tables in reverse dependency order */
IF OBJECT_ID('dbo.AttemptAnswers','U') IS NOT NULL DROP TABLE dbo.AttemptAnswers;
IF OBJECT_ID('dbo.QuizAttempts','U') IS NOT NULL DROP TABLE dbo.QuizAttempts;
IF OBJECT_ID('dbo.Options','U') IS NOT NULL DROP TABLE dbo.Options;
IF OBJECT_ID('dbo.Questions','U') IS NOT NULL DROP TABLE dbo.Questions;
IF OBJECT_ID('dbo.Quizzes','U') IS NOT NULL DROP TABLE dbo.Quizzes;
IF OBJECT_ID('dbo.Progresses','U') IS NOT NULL DROP TABLE dbo.Progresses;
IF OBJECT_ID('dbo.Enrollments','U') IS NOT NULL DROP TABLE dbo.Enrollments;
IF OBJECT_ID('dbo.Lessons','U') IS NOT NULL DROP TABLE dbo.Lessons;
IF OBJECT_ID('dbo.Modules','U') IS NOT NULL DROP TABLE dbo.Modules;
IF OBJECT_ID('dbo.Notifications','U') IS NOT NULL DROP TABLE dbo.Notifications;
IF OBJECT_ID('dbo.FileAssets','U') IS NOT NULL DROP TABLE dbo.FileAssets;
IF OBJECT_ID('dbo.OutboxMessages','U') IS NOT NULL DROP TABLE dbo.OutboxMessages;
IF OBJECT_ID('dbo.AuditLogs','U') IS NOT NULL DROP TABLE dbo.AuditLogs;
IF OBJECT_ID('dbo.Courses','U') IS NOT NULL DROP TABLE dbo.Courses;

IF OBJECT_ID('dbo.AspNetUsers','U') IS NOT NULL DROP TABLE dbo.AspNetUsers;
IF OBJECT_ID('dbo.AspNetRoles','U') IS NOT NULL DROP TABLE dbo.AspNetRoles;
IF OBJECT_ID('dbo.AspNetRoleClaims','U') IS NOT NULL DROP TABLE dbo.AspNetRoleClaims;
IF OBJECT_ID('dbo.AspNetUserClaims','U') IS NOT NULL DROP TABLE dbo.AspNetUserClaims;
IF OBJECT_ID('dbo.AspNetUserLogins','U') IS NOT NULL DROP TABLE dbo.AspNetUserLogins;
IF OBJECT_ID('dbo.AspNetUserTokens','U') IS NOT NULL DROP TABLE dbo.AspNetUserTokens;
IF OBJECT_ID('dbo.AspNetUserRoles','U') IS NOT NULL DROP TABLE dbo.AspNetUserRoles;
GO

/* 3) AspNetUsers (Identity) - theo SDD, không soft delete/audit mở rộng */
CREATE TABLE dbo.AspNetUsers (
    Id UNIQUEIDENTIFIER NOT NULL,
    UserName NVARCHAR(256) NOT NULL,
    NormalizedUserName NVARCHAR(256) NOT NULL,
    Email NVARCHAR(256) NULL,
    NormalizedEmail NVARCHAR(256) NULL,
    EmailConfirmed BIT NOT NULL CONSTRAINT DF_AspNetUsers_EmailConfirmed DEFAULT (0),
    PasswordHash NVARCHAR(MAX) NULL,
    SecurityStamp NVARCHAR(MAX) NULL,
    ConcurrencyStamp NVARCHAR(MAX) NULL,
    PhoneNumber NVARCHAR(50) NULL,
    PhoneNumberConfirmed BIT NOT NULL CONSTRAINT DF_AspNetUsers_PhoneNumberConfirmed DEFAULT (0),
    TwoFactorEnabled BIT NOT NULL CONSTRAINT DF_AspNetUsers_TwoFactorEnabled DEFAULT (0),
    LockoutEnd DATETIMEOFFSET NULL,
    LockoutEnabled BIT NOT NULL CONSTRAINT DF_AspNetUsers_LockoutEnabled DEFAULT (0),
    AccessFailedCount INT NOT NULL CONSTRAINT DF_AspNetUsers_AccessFailedCount DEFAULT (0)
);
ALTER TABLE dbo.AspNetUsers ADD CONSTRAINT PK_AspNetUsers PRIMARY KEY (Id);
ALTER TABLE dbo.AspNetUsers ADD CONSTRAINT UQ_AspNetUsers_NormalizedUserName UNIQUE (NormalizedUserName);
CREATE INDEX IX_AspNetUsers_NormalizedEmail ON dbo.AspNetUsers(NormalizedEmail);
CREATE INDEX IX_AspNetUsers_UserName ON dbo.AspNetUsers(UserName);
GO
-- =====================================================
-- File: identity-all-in-one.sql
-- Mục đích: Tạo các bảng AspNet* (idempotent), index, seed roles
-- Ghi chú:
--  - Dòng DROP đã được comment sẵn. Bỏ '--' nếu bạn thực sự muốn xóa trước khi tạo.
--  - Script kiểm tra tồn tại từng bảng/constraint/index trước khi tạo.
--  - Nếu dbo.AspNetUsers không tồn tại, các FK tới AspNetUsers sẽ bị bỏ qua (sẽ có PRINT).
--  - Trước khi chạy: backup database.
-- =====================================================
 
----------------------------------------------------------------
-- 1) AspNetRoles
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetRoles','U') IS NULL
BEGIN
    CREATE TABLE dbo.AspNetRoles (
        Id UNIQUEIDENTIFIER NOT NULL,
        [Name] NVARCHAR(256) NULL,
        NormalizedName NVARCHAR(256) NULL,
        ConcurrencyStamp NVARCHAR(MAX) NULL
    );
    ALTER TABLE dbo.AspNetRoles ADD CONSTRAINT PK_AspNetRoles PRIMARY KEY (Id);
END
GO

-- Unique index on NormalizedName (idempotent)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_AspNetRoles_NormalizedName' AND object_id = OBJECT_ID('dbo.AspNetRoles'))
BEGIN
    CREATE UNIQUE INDEX UQ_AspNetRoles_NormalizedName ON dbo.AspNetRoles(NormalizedName);
END
GO

----------------------------------------------------------------
-- 2) AspNetRoleClaims
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetRoleClaims','U') IS NULL
BEGIN
    CREATE TABLE dbo.AspNetRoleClaims (
        Id INT IDENTITY(1,1) NOT NULL,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        ClaimType NVARCHAR(MAX) NULL,
        ClaimValue NVARCHAR(MAX) NULL
    );
    ALTER TABLE dbo.AspNetRoleClaims ADD CONSTRAINT PK_AspNetRoleClaims PRIMARY KEY (Id);
END
GO

-- FK AspNetRoleClaims -> AspNetRoles (only add if AspNetRoles exists)
IF OBJECT_ID('dbo.AspNetRoles','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID('dbo.AspNetRoleClaims') AND fk.referenced_object_id = OBJECT_ID('dbo.AspNetRoles')
    )
    BEGIN
        ALTER TABLE dbo.AspNetRoleClaims
        ADD CONSTRAINT FK_AspNetRoleClaims_AspNetRoles FOREIGN KEY (RoleId) REFERENCES dbo.AspNetRoles(Id);
    END
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AspNetRoleClaims_RoleId' AND object_id = OBJECT_ID('dbo.AspNetRoleClaims'))
BEGIN
    CREATE INDEX IX_AspNetRoleClaims_RoleId ON dbo.AspNetRoleClaims(RoleId);
END
GO

----------------------------------------------------------------
-- 3) AspNetUserClaims
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetUserClaims','U') IS NULL
BEGIN
    CREATE TABLE dbo.AspNetUserClaims (
        Id INT IDENTITY(1,1) NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        ClaimType NVARCHAR(MAX) NULL,
        ClaimValue NVARCHAR(MAX) NULL
    );
    ALTER TABLE dbo.AspNetUserClaims ADD CONSTRAINT PK_AspNetUserClaims PRIMARY KEY (Id);
END
GO

-- FK AspNetUserClaims -> AspNetUsers (only if AspNetUsers exists)
IF OBJECT_ID('dbo.AspNetUsers','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID('dbo.AspNetUserClaims') AND fk.referenced_object_id = OBJECT_ID('dbo.AspNetUsers')
    )
    BEGIN
        ALTER TABLE dbo.AspNetUserClaims
        ADD CONSTRAINT FK_AspNetUserClaims_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
    END
END
ELSE
BEGIN
    PRINT 'NOTICE: dbo.AspNetUsers not found => FK AspNetUserClaims_AspNetUsers skipped.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AspNetUserClaims_UserId' AND object_id = OBJECT_ID('dbo.AspNetUserClaims'))
BEGIN
    CREATE INDEX IX_AspNetUserClaims_UserId ON dbo.AspNetUserClaims(UserId);
END
GO

----------------------------------------------------------------
-- 4) AspNetUserLogins
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetUserLogins','U') IS NULL
BEGIN
    CREATE TABLE dbo.AspNetUserLogins (
        LoginProvider NVARCHAR(128) NOT NULL,
        ProviderKey NVARCHAR(128) NOT NULL,
        ProviderDisplayName NVARCHAR(256) NULL,
        UserId UNIQUEIDENTIFIER NOT NULL
    );
    ALTER TABLE dbo.AspNetUserLogins ADD CONSTRAINT PK_AspNetUserLogins PRIMARY KEY (LoginProvider, ProviderKey);
END
GO

-- FK AspNetUserLogins -> AspNetUsers
IF OBJECT_ID('dbo.AspNetUsers','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID('dbo.AspNetUserLogins') AND fk.referenced_object_id = OBJECT_ID('dbo.AspNetUsers')
    )
    BEGIN
        ALTER TABLE dbo.AspNetUserLogins
        ADD CONSTRAINT FK_AspNetUserLogins_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
    END
END
ELSE
BEGIN
    PRINT 'NOTICE: dbo.AspNetUsers not found => FK AspNetUserLogins_AspNetUsers skipped.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AspNetUserLogins_UserId' AND object_id = OBJECT_ID('dbo.AspNetUserLogins'))
BEGIN
    CREATE INDEX IX_AspNetUserLogins_UserId ON dbo.AspNetUserLogins(UserId);
END
GO

----------------------------------------------------------------
-- 5) AspNetUserTokens
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetUserTokens','U') IS NULL
BEGIN
    CREATE TABLE dbo.AspNetUserTokens (
        UserId UNIQUEIDENTIFIER NOT NULL,
        LoginProvider NVARCHAR(128) NOT NULL,
        Name NVARCHAR(128) NOT NULL,
        Value NVARCHAR(MAX) NULL
    );
    ALTER TABLE dbo.AspNetUserTokens ADD CONSTRAINT PK_AspNetUserTokens PRIMARY KEY (UserId, LoginProvider, Name);
END
GO

-- FK AspNetUserTokens -> AspNetUsers
IF OBJECT_ID('dbo.AspNetUsers','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID('dbo.AspNetUserTokens') AND fk.referenced_object_id = OBJECT_ID('dbo.AspNetUsers')
    )
    BEGIN
        ALTER TABLE dbo.AspNetUserTokens
        ADD CONSTRAINT FK_AspNetUserTokens_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
    END
END
ELSE
BEGIN
    PRINT 'NOTICE: dbo.AspNetUsers not found => FK AspNetUserTokens_AspNetUsers skipped.';
END
GO

----------------------------------------------------------------
-- 6) AspNetUserRoles
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetUserRoles','U') IS NULL
BEGIN
    CREATE TABLE dbo.AspNetUserRoles (
        UserId UNIQUEIDENTIFIER NOT NULL,
        RoleId UNIQUEIDENTIFIER NOT NULL
    );
    ALTER TABLE dbo.AspNetUserRoles ADD CONSTRAINT PK_AspNetUserRoles PRIMARY KEY (UserId, RoleId);
END
GO

-- FK AspNetUserRoles -> AspNetUsers (UserId)
IF OBJECT_ID('dbo.AspNetUsers','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID('dbo.AspNetUserRoles') AND fk.referenced_object_id = OBJECT_ID('dbo.AspNetUsers')
    )
    BEGIN
        ALTER TABLE dbo.AspNetUserRoles
        ADD CONSTRAINT FK_AspNetUserRoles_User FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
    END
END
ELSE
BEGIN
    PRINT 'NOTICE: dbo.AspNetUsers not found => FK AspNetUserRoles_User skipped.';
END
GO

-- FK AspNetUserRoles -> AspNetRoles (RoleId)
IF OBJECT_ID('dbo.AspNetRoles','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = OBJECT_ID('dbo.AspNetUserRoles') AND fk.referenced_object_id = OBJECT_ID('dbo.AspNetRoles')
    )
    BEGIN
        ALTER TABLE dbo.AspNetUserRoles
        ADD CONSTRAINT FK_AspNetUserRoles_Role FOREIGN KEY (RoleId) REFERENCES dbo.AspNetRoles(Id);
    END
END
ELSE
BEGIN
    PRINT 'NOTICE: dbo.AspNetRoles not found => FK AspNetUserRoles_Role skipped.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AspNetUserRoles_RoleId' AND object_id = OBJECT_ID('dbo.AspNetUserRoles'))
BEGIN
    CREATE INDEX IX_AspNetUserRoles_RoleId ON dbo.AspNetUserRoles(RoleId);
END
GO

----------------------------------------------------------------
-- 7) Additional Indexes / Support (follow SDD naming)
----------------------------------------------------------------
-- IX on AspNetUsers.NormalizedEmail (if AspNetUsers exists)
--IF OBJECT_ID('dbo.AspNetUsers','U') IS NOT NULL
--BEGIN
--    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AspNetUsers_NormalizedEmail' AND object_id = OBJECT_ID('dbo.AspNetUsers'))
--    BEGIN
--        CREATE INDEX IX_AspNetUsers_NormalizedEmail ON dbo.AspNetUsers(NormalizedEmail);
--    END
--END
--GO

----------------------------------------------------------------
-- 8) Seed roles (idempotent) - theo SDD: Admin, Instructor, Learner
----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.AspNetRoles WHERE NormalizedName = 'ADMIN')
BEGIN
    INSERT INTO dbo.AspNetRoles (Id, [Name], NormalizedName, ConcurrencyStamp)
    VALUES (NEWID(), 'Admin', 'ADMIN', NEWID());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AspNetRoles WHERE NormalizedName = 'INSTRUCTOR')
BEGIN
    INSERT INTO dbo.AspNetRoles (Id, [Name], NormalizedName, ConcurrencyStamp)
    VALUES (NEWID(), 'Instructor', 'INSTRUCTOR', NEWID());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AspNetRoles WHERE NormalizedName = 'LEARNER')
BEGIN
    INSERT INTO dbo.AspNetRoles (Id, [Name], NormalizedName, ConcurrencyStamp)
    VALUES (NEWID(), 'Learner', 'LEARNER', NEWID());
END
GO

----------------------------------------------------------------
-- Done
----------------------------------------------------------------
IF OBJECT_ID('dbo.AspNetUsers','U') IS NULL
BEGIN
    RAISERROR('❌ CẢNH BÁO: Bảng AspNetUsers KHÔNG tồn tại, các FK phụ thuộc sẽ KHÔNG được tạo. Vui lòng tạo AspNetUsers trước.',16,1);
END
ELSE
BEGIN
    PRINT '✅ AspNetUsers tồn tại, các FK đã được ràng buộc thành công.';
END


/* 4) Courses (audit + soft delete + filtered unique + RowVersion) */
CREATE TABLE dbo.Courses (
    Id UNIQUEIDENTIFIER NOT NULL,
    Code NVARCHAR(50) NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT DF_Courses_Status DEFAULT ('Draft'),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Courses_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Courses_IsDeleted DEFAULT (0),
    [RowVersion] ROWVERSION
);
ALTER TABLE dbo.Courses ADD CONSTRAINT PK_Courses PRIMARY KEY (Id);
ALTER TABLE dbo.Courses ADD CONSTRAINT FK_Courses_AspNetUsers FOREIGN KEY (CreatedBy) REFERENCES dbo.AspNetUsers(Id);
-- Filtered unique index để hỗ trợ soft delete
CREATE UNIQUE INDEX UQ_Courses_Code ON dbo.Courses(Code) WHERE IsDeleted = 0;
CREATE INDEX IX_Courses_Status ON dbo.Courses(Status);
CREATE INDEX IX_Courses_Title ON dbo.Courses(Title);
-- Trạng thái hợp lệ
ALTER TABLE dbo.Courses ADD CONSTRAINT CK_Courses_Status_Valid CHECK ([Status] IN ('Draft','Published','Archived'));
GO

/* 5) Modules (audit + soft delete + RowVersion) */
CREATE TABLE dbo.Modules (
    Id UNIQUEIDENTIFIER NOT NULL,
    CourseId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    [Order] INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Modules_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Modules_IsDeleted DEFAULT (0),
    [RowVersion] ROWVERSION
);
ALTER TABLE dbo.Modules ADD CONSTRAINT PK_Modules PRIMARY KEY (Id);
ALTER TABLE dbo.Modules ADD CONSTRAINT FK_Modules_Courses FOREIGN KEY (CourseId) REFERENCES dbo.Courses(Id);
CREATE INDEX IX_Modules_Course_Order ON dbo.Modules(CourseId, [Order]);
GO

/* 6) Lessons (audit + soft delete + RowVersion) */
CREATE TABLE dbo.Lessons (
    Id UNIQUEIDENTIFIER NOT NULL,
    ModuleId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    ContentType NVARCHAR(50) NOT NULL,
    ContentUrl NVARCHAR(1000) NULL,
    DurationSec INT NULL,
    [Order] INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Lessons_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Lessons_IsDeleted DEFAULT (0),
    [RowVersion] ROWVERSION
);
ALTER TABLE dbo.Lessons ADD CONSTRAINT PK_Lessons PRIMARY KEY (Id);
ALTER TABLE dbo.Lessons ADD CONSTRAINT FK_Lessons_Modules FOREIGN KEY (ModuleId) REFERENCES dbo.Modules(Id);
CREATE INDEX IX_Lessons_Module_Order ON dbo.Lessons(ModuleId, [Order]);
ALTER TABLE dbo.Lessons ADD CONSTRAINT CK_Lessons_Duration_Positive CHECK (DurationSec IS NULL OR DurationSec > 0);
GO

/* 7) Enrollments (audit + soft delete + filtered unique) */
CREATE TABLE dbo.Enrollments (
    Id UNIQUEIDENTIFIER NOT NULL,
    CourseId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    StartAt DATETIME2 NOT NULL,
    EndAt DATETIME2 NULL,
    [Status] NVARCHAR(20) NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Enrollments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Enrollments_IsDeleted DEFAULT (0)
);
ALTER TABLE dbo.Enrollments ADD CONSTRAINT PK_Enrollments PRIMARY KEY (Id);
ALTER TABLE dbo.Enrollments ADD CONSTRAINT FK_Enrollments_Courses FOREIGN KEY (CourseId) REFERENCES dbo.Courses(Id);
ALTER TABLE dbo.Enrollments ADD CONSTRAINT FK_Enrollments_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
-- Filtered unique index để hỗ trợ re-enroll sau soft delete
CREATE UNIQUE INDEX UQ_Enrollments_CourseId_UserId ON dbo.Enrollments(CourseId, UserId) WHERE IsDeleted = 0;
CREATE INDEX IX_Enrollments_User ON dbo.Enrollments(UserId);
CREATE INDEX IX_Enrollments_Course_Status ON dbo.Enrollments(CourseId, [Status]);
ALTER TABLE dbo.Enrollments ADD CONSTRAINT CK_Enrollments_EndAfterStart CHECK (EndAt IS NULL OR EndAt >= StartAt);
ALTER TABLE dbo.Enrollments ADD CONSTRAINT CK_Enrollments_Status_Valid CHECK ([Status] IN ('Active','Completed','Cancelled'));
GO

/* 8) Progresses (audit + soft delete) */
CREATE TABLE dbo.Progresses (
    Id UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    LessonId UNIQUEIDENTIFIER NOT NULL,
    CompletedAt DATETIME2 NULL,
    [Percent] TINYINT NOT NULL CONSTRAINT DF_Progresses_Percent DEFAULT (0),
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Progresses_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Progresses_IsDeleted DEFAULT (0)
);
ALTER TABLE dbo.Progresses ADD CONSTRAINT PK_Progresses PRIMARY KEY (Id);
ALTER TABLE dbo.Progresses ADD CONSTRAINT FK_Progresses_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
ALTER TABLE dbo.Progresses ADD CONSTRAINT FK_Progresses_Lessons FOREIGN KEY (LessonId) REFERENCES dbo.Lessons(Id);
CREATE UNIQUE INDEX UQ_Progresses_UserId_LessonId ON dbo.Progresses (UserId, LessonId);
CREATE INDEX IX_Progresses_User ON dbo.Progresses(UserId);
ALTER TABLE dbo.Progresses ADD CONSTRAINT CK_Progresses_Percent_Range CHECK ([Percent] BETWEEN 0 AND 100);
GO

/* 9) Quizzes (audit + soft delete + RowVersion) */
CREATE TABLE dbo.Quizzes (
    Id UNIQUEIDENTIFIER NOT NULL,
    CourseId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    DurationSec INT NULL,
    AttemptsAllowed INT NULL CONSTRAINT DF_Quizzes_AttemptsAllowed DEFAULT (1),
    ShuffleAnswers BIT NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Quizzes_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Quizzes_IsDeleted DEFAULT (0),
    [RowVersion] ROWVERSION
);
ALTER TABLE dbo.Quizzes ADD CONSTRAINT PK_Quizzes PRIMARY KEY (Id);
ALTER TABLE dbo.Quizzes ADD CONSTRAINT FK_Quizzes_Courses FOREIGN KEY (CourseId) REFERENCES dbo.Courses(Id);
CREATE INDEX IX_Quizzes_Course ON dbo.Quizzes(CourseId);
ALTER TABLE dbo.Quizzes ADD CONSTRAINT CK_Quizzes_Attempts_Min1 CHECK (AttemptsAllowed IS NULL OR AttemptsAllowed >= 1);
GO

/* 10) Questions (audit + soft delete + RowVersion) */
CREATE TABLE dbo.Questions (
    Id UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    [Text] NVARCHAR(MAX) NOT NULL,
    [Order] INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Questions_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Questions_IsDeleted DEFAULT (0),
    [RowVersion] ROWVERSION
);
ALTER TABLE dbo.Questions ADD CONSTRAINT PK_Questions PRIMARY KEY (Id);
ALTER TABLE dbo.Questions ADD CONSTRAINT FK_Questions_Quizzes FOREIGN KEY (QuizId) REFERENCES dbo.Quizzes(Id);
CREATE INDEX IX_Questions_Quiz_Order ON dbo.Questions(QuizId, [Order]);
GO

/* 11) Options (audit + soft delete + RowVersion) */
CREATE TABLE dbo.Options (
    Id UNIQUEIDENTIFIER NOT NULL,
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    [Text] NVARCHAR(MAX) NOT NULL,
    IsCorrect BIT NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Options_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Options_IsDeleted DEFAULT (0),
    [RowVersion] ROWVERSION
);
ALTER TABLE dbo.Options ADD CONSTRAINT PK_Options PRIMARY KEY (Id);
ALTER TABLE dbo.Options ADD CONSTRAINT FK_Options_Questions FOREIGN KEY (QuestionId) REFERENCES dbo.Questions(Id);
CREATE INDEX IX_Options_Question ON dbo.Options(QuestionId);
GO

/* 12) QuizAttempts (không audit/soft delete) */
CREATE TABLE dbo.QuizAttempts (
    Id UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    StartedAt DATETIME2 NOT NULL,
    SubmittedAt DATETIME2 NULL,
    Score DECIMAL(5,2) NULL CONSTRAINT DF_QuizAttempts_Score DEFAULT (0)
);
ALTER TABLE dbo.QuizAttempts ADD CONSTRAINT PK_QuizAttempts PRIMARY KEY (Id);
ALTER TABLE dbo.QuizAttempts ADD CONSTRAINT FK_QuizAttempts_Quizzes FOREIGN KEY (QuizId) REFERENCES dbo.Quizzes(Id);
ALTER TABLE dbo.QuizAttempts ADD CONSTRAINT FK_QuizAttempts_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
CREATE INDEX IX_QuizAttempts_Quiz_User ON dbo.QuizAttempts(QuizId, UserId);
ALTER TABLE dbo.QuizAttempts ADD CONSTRAINT CK_QuizAttempts_SubmitAfterStart CHECK (SubmittedAt IS NULL OR SubmittedAt >= StartedAt);
ALTER TABLE dbo.QuizAttempts ADD CONSTRAINT CK_QuizAttempts_Score_Range CHECK (Score BETWEEN 0 AND 100);
GO

/* 13) AttemptAnswers (không audit/soft delete) */
CREATE TABLE dbo.AttemptAnswers (
    Id UNIQUEIDENTIFIER NOT NULL,
    AttemptId UNIQUEIDENTIFIER NOT NULL,
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    OptionId UNIQUEIDENTIFIER NOT NULL
);
ALTER TABLE dbo.AttemptAnswers ADD CONSTRAINT PK_AttemptAnswers PRIMARY KEY (Id);
ALTER TABLE dbo.AttemptAnswers ADD CONSTRAINT FK_AttemptAnswers_QuizAttempts FOREIGN KEY (AttemptId) REFERENCES dbo.QuizAttempts(Id);
ALTER TABLE dbo.AttemptAnswers ADD CONSTRAINT FK_AttemptAnswers_Questions FOREIGN KEY (QuestionId) REFERENCES dbo.Questions(Id);
ALTER TABLE dbo.AttemptAnswers ADD CONSTRAINT FK_AttemptAnswers_Options FOREIGN KEY (OptionId) REFERENCES dbo.Options(Id);
ALTER TABLE dbo.AttemptAnswers ADD CONSTRAINT UQ_AttemptAnswers_AttemptId_QuestionId UNIQUE (AttemptId, QuestionId);
GO

/* 14) Notifications (audit + soft delete) */
CREATE TABLE dbo.Notifications (
    Id UNIQUEIDENTIFIER NOT NULL,
    CourseId UNIQUEIDENTIFIER NULL,
    ToUserId UNIQUEIDENTIFIER NULL,
    Title NVARCHAR(200) NOT NULL,
    Body NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_Notifications_IsDeleted DEFAULT (0),
    SentBy UNIQUEIDENTIFIER NOT NULL
);
ALTER TABLE dbo.Notifications ADD CONSTRAINT PK_Notifications PRIMARY KEY (Id);
ALTER TABLE dbo.Notifications ADD CONSTRAINT FK_Notifications_Courses FOREIGN KEY (CourseId) REFERENCES dbo.Courses(Id);
ALTER TABLE dbo.Notifications ADD CONSTRAINT FK_Notifications_AspNetUsers_ToUser FOREIGN KEY (ToUserId) REFERENCES dbo.AspNetUsers(Id);
ALTER TABLE dbo.Notifications ADD CONSTRAINT FK_Notifications_AspNetUsers_SentBy FOREIGN KEY (SentBy) REFERENCES dbo.AspNetUsers(Id);
CREATE INDEX IX_Notifications_ToUserId ON dbo.Notifications(ToUserId);
GO

/* 15) FileAssets (audit + soft delete) */
CREATE TABLE dbo.FileAssets (
    Id UNIQUEIDENTIFIER NOT NULL,
    OwnerUserId UNIQUEIDENTIFIER NOT NULL,
    FileName NVARCHAR(255) NOT NULL,
    MimeType NVARCHAR(100) NOT NULL,
    Size BIGINT NOT NULL,
    StoragePath NVARCHAR(1000) NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_FileAssets_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy UNIQUEIDENTIFIER NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_FileAssets_IsDeleted DEFAULT (0)
);
ALTER TABLE dbo.FileAssets ADD CONSTRAINT PK_FileAssets PRIMARY KEY (Id);
ALTER TABLE dbo.FileAssets ADD CONSTRAINT FK_FileAssets_AspNetUsers FOREIGN KEY (OwnerUserId) REFERENCES dbo.AspNetUsers(Id);
CREATE INDEX IX_FileAssets_OwnerUserId ON dbo.FileAssets(OwnerUserId);
GO

/* 16) OutboxMessages (theo SDD Phụ lục A) */
CREATE TABLE dbo.OutboxMessages (
    Id UNIQUEIDENTIFIER NOT NULL,
    OccurredOn DATETIME2 NOT NULL CONSTRAINT DF_OutboxMessages_OccurredOn DEFAULT (SYSUTCDATETIME()),
    [Type] NVARCHAR(200) NOT NULL,
    Payload NVARCHAR(MAX) NOT NULL,
    ProcessedOn DATETIME2 NULL,
    Error NVARCHAR(MAX) NULL,
    RetryCount INT NOT NULL CONSTRAINT DF_OutboxMessages_RetryCount DEFAULT (0)
);
ALTER TABLE dbo.OutboxMessages ADD CONSTRAINT PK_OutboxMessages PRIMARY KEY (Id);
CREATE INDEX IX_OutboxMessages_ProcessedOn ON dbo.OutboxMessages(ProcessedOn);
GO

/* 17) AuditLogs (theo SDD Phụ lục A) */
CREATE TABLE dbo.AuditLogs (
    Id UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NULL,
    [Action] NVARCHAR(200) NOT NULL,
    [Entity] NVARCHAR(200) NOT NULL,
    EntityId UNIQUEIDENTIFIER NULL,
    [Data] NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_AuditLogs_CreatedAt DEFAULT (SYSUTCDATETIME())
);
ALTER TABLE dbo.AuditLogs ADD CONSTRAINT PK_AuditLogs PRIMARY KEY (Id);
ALTER TABLE dbo.AuditLogs ADD CONSTRAINT FK_AuditLogs_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers(Id);
CREATE INDEX IX_AuditLogs_UserId ON dbo.AuditLogs(UserId);
CREATE INDEX IX_AuditLogs_Entity_EntityId ON dbo.AuditLogs([Entity], EntityId);
GO

PRINT 'LMSMini schema created successfully (aligned with SDD).';
