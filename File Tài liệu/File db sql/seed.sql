USE [LMSMini];
GO

PRINT 'Seeding dữ liệu đầy đủ cho LMSMini...';

-- ==== USERS ====
DECLARE @adminId UNIQUEIDENTIFIER = NEWID();
DECLARE @user1Id UNIQUEIDENTIFIER = NEWID();
DECLARE @user2Id UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.AspNetUsers (Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount)
VALUES
(@adminId, 'admin@example.com', 'ADMIN@EXAMPLE.COM', 'admin@example.com', 'ADMIN@EXAMPLE.COM', 1, 0, 0, 0, 0),
(@user1Id, 'alice@example.com', 'ALICE@EXAMPLE.COM', 'alice@example.com', 'ALICE@EXAMPLE.COM', 1, 0, 0, 0, 0),
(@user2Id, 'bob@example.com', 'BOB@EXAMPLE.COM', 'bob@example.com', 'BOB@EXAMPLE.COM', 1, 0, 0, 0, 0);

-- ==== COURSE 1 ====
DECLARE @course1Id UNIQUEIDENTIFIER = NEWID();
DECLARE @module1Id UNIQUEIDENTIFIER = NEWID();
DECLARE @lesson1Id UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Courses (Id, Code, Title, Description, Status, CreatedBy)
VALUES (@course1Id, 'INTRO-001', N'Khóa học giới thiệu', N'Giới thiệu hệ thống LMS', 'Published', @adminId);

INSERT INTO dbo.Modules (Id, CourseId, Title, [Order], CreatedBy)
VALUES (@module1Id, @course1Id, N'Module 1 - Tổng quan', 1, @adminId);

INSERT INTO dbo.Lessons (Id, ModuleId, Title, ContentType, ContentUrl, DurationSec, [Order], CreatedBy)
VALUES (@lesson1Id, @module1Id, N'Bài 1 - Giới thiệu LMS', 'article', NULL, 600, 1, @adminId);

-- ==== COURSE 2 ====
DECLARE @course2Id UNIQUEIDENTIFIER = NEWID();
DECLARE @module2Id UNIQUEIDENTIFIER = NEWID();
DECLARE @lesson2Id UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Courses (Id, Code, Title, Description, Status, CreatedBy)
VALUES (@course2Id, 'DB-101', N'Cơ sở dữ liệu cơ bản', N'Học về SQL và thiết kế DB', 'Published', @adminId);

INSERT INTO dbo.Modules (Id, CourseId, Title, [Order], CreatedBy)
VALUES (@module2Id, @course2Id, N'Module 1 - SQL cơ bản', 1, @adminId);

INSERT INTO dbo.Lessons (Id, ModuleId, Title, ContentType, ContentUrl, DurationSec, [Order], CreatedBy)
VALUES (@lesson2Id, @module2Id, N'Bài 1 - SELECT cơ bản', 'video', NULL, 900, 1, @adminId);

-- ==== ENROLLMENTS ====
DECLARE @enroll1Id UNIQUEIDENTIFIER = NEWID();
DECLARE @enroll2Id UNIQUEIDENTIFIER = NEWID();
DECLARE @enroll3Id UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Enrollments (Id, CourseId, UserId, StartAt, Status, CreatedBy)
VALUES
(@enroll1Id, @course1Id, @user1Id, SYSUTCDATETIME(), 'Active', @adminId),
(@enroll2Id, @course2Id, @user1Id, SYSUTCDATETIME(), 'Active', @adminId),
(@enroll3Id, @course1Id, @user2Id, SYSUTCDATETIME(), 'Active', @adminId);

-- ==== PROGRESSES ====
INSERT INTO dbo.Progresses (Id, UserId, LessonId, [Percent], CreatedBy)
VALUES
(NEWID(), @user1Id, @lesson1Id, 100, @adminId),
(NEWID(), @user2Id, @lesson1Id, 50, @adminId);

-- ==== QUIZ SAMPLE ====
DECLARE @quizId UNIQUEIDENTIFIER = NEWID();
DECLARE @questionId UNIQUEIDENTIFIER = NEWID();
DECLARE @opt1 UNIQUEIDENTIFIER = NEWID();
DECLARE @opt2 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Quizzes (Id, CourseId, Title, AttemptsAllowed, ShuffleAnswers, CreatedBy)
VALUES (@quizId, @course1Id, N'Quiz giới thiệu', 1, 0, @adminId);

INSERT INTO dbo.Questions (Id, QuizId, [Text], [Order], CreatedBy)
VALUES (@questionId, @quizId, N'2 + 2 = ?', 1, @adminId);

INSERT INTO dbo.Options (Id, QuestionId, [Text], IsCorrect, CreatedBy)
VALUES
(@opt1, @questionId, N'3', 0, @adminId),
(@opt2, @questionId, N'4', 1, @adminId);

-- ==== QUIZ ATTEMPT ====
DECLARE @attemptId UNIQUEIDENTIFIER = NEWID();
INSERT INTO dbo.QuizAttempts (Id, QuizId, UserId, StartedAt, SubmittedAt, Score)
VALUES (@attemptId, @quizId, @user1Id, SYSUTCDATETIME(), SYSUTCDATETIME(), 100);

INSERT INTO dbo.AttemptAnswers (Id, AttemptId, QuestionId, OptionId)
VALUES (NEWID(), @attemptId, @questionId, @opt2);

-- ==== NOTIFICATIONS ====
INSERT INTO dbo.Notifications (Id, ToUserId, Title, Body, CreatedBy, SentBy)
VALUES
(NEWID(), @user1Id, N'Chào mừng!', N'Bạn đã được ghi danh vào khóa học.', @adminId, @adminId),
(NEWID(), @user2Id, N'Bắt đầu học ngay', N'Đừng quên hoàn thành bài học đầu tiên.', @adminId, @adminId);

-- ==== FILE ASSETS ====
INSERT INTO dbo.FileAssets (Id, OwnerUserId, FileName, MimeType, Size, StoragePath, CreatedBy)
VALUES
(NEWID(), @adminId, N'syllabus_intro.pdf', 'application/pdf', 102400, '/files/syllabus_intro.pdf', @adminId);

PRINT 'Seed đầy đủ hoàn tất.';
GO
