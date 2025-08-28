USE [LMSMini];
GO

PRINT 'Seeding dữ liệu TEST cho LMSMini...';

-- ===== USERS =====
DECLARE @adminId UNIQUEIDENTIFIER = NEWID();
DECLARE @u1 UNIQUEIDENTIFIER = NEWID();
DECLARE @u2 UNIQUEIDENTIFIER = NEWID();
DECLARE @u3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.AspNetUsers (Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount)
VALUES
(@adminId, 'admin@test.com', 'ADMIN@TEST.COM', 'admin@test.com', 'ADMIN@TEST.COM', 1, 0, 0, 0, 0),
(@u1, 'student1@test.com', 'STUDENT1@TEST.COM', 'student1@test.com', 'STUDENT1@TEST.COM', 1, 0, 0, 0, 0),
(@u2, 'student2@test.com', 'STUDENT2@TEST.COM', 'student2@test.com', 'STUDENT2@TEST.COM', 1, 0, 0, 0, 0),
(@u3, 'lecturer@test.com', 'LECTURER@TEST.COM', 'lecturer@test.com', 'LECTURER@TEST.COM', 1, 0, 0, 0, 0);

-- ===== COURSES =====
DECLARE @c1 UNIQUEIDENTIFIER = NEWID();
DECLARE @c2 UNIQUEIDENTIFIER = NEWID();
DECLARE @c3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Courses (Id, Code, Title, Description, Status, CreatedBy, IsDeleted)
VALUES
(@c1, 'TEST-001', N'Course Active', N'Course published for testing', 'Published', @adminId, 0),
(@c2, 'TEST-002', N'Course Draft', N'Course still in draft', 'Draft', @adminId, 0),
(@c3, 'TEST-003', N'Course Soft Deleted', N'Course marked as deleted', 'Archived', @adminId, 1); -- test filtered index

-- ===== MODULES =====
DECLARE @m1 UNIQUEIDENTIFIER = NEWID();
DECLARE @m2 UNIQUEIDENTIFIER = NEWID();
DECLARE @m3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Modules (Id, CourseId, Title, [Order], CreatedBy)
VALUES
(@m1, @c1, N'Module 1 - Intro', 1, @adminId),
(@m2, @c1, N'Module 2 - Advanced', 2, @adminId),
(@m3, @c2, N'Module Draft', 1, @adminId);

-- ===== LESSONS =====
DECLARE @l1 UNIQUEIDENTIFIER = NEWID();
DECLARE @l2 UNIQUEIDENTIFIER = NEWID();
DECLARE @l3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Lessons (Id, ModuleId, Title, ContentType, ContentUrl, DurationSec, [Order], CreatedBy)
VALUES
(@l1, @m1, N'Lesson 1', 'article', NULL, 600, 1, @adminId),
(@l2, @m1, N'Lesson 2', 'video', NULL, 1200, 2, @adminId),
(@l3, @m3, N'Draft Lesson', 'article', NULL, 300, 1, @adminId);

-- ===== ENROLLMENTS =====
DECLARE @e1 UNIQUEIDENTIFIER = NEWID();
DECLARE @e2 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Enrollments (Id, CourseId, UserId, StartAt, Status, CreatedBy)
VALUES
(@e1, @c1, @u1, SYSUTCDATETIME(), 'Active', @adminId),
(@e2, @c1, @u2, DATEADD(DAY,-10,SYSUTCDATETIME()), 'Completed', @adminId);

-- ===== PROGRESSES =====
INSERT INTO dbo.Progresses (Id, UserId, LessonId, [Percent], CreatedBy)
VALUES
(NEWID(), @u1, @l1, 100, @adminId),
(NEWID(), @u2, @l1, 50, @adminId),
(NEWID(), @u1, @l2, 0, @adminId);

-- ===== QUIZZES =====
DECLARE @qz1 UNIQUEIDENTIFIER = NEWID();
INSERT INTO dbo.Quizzes (Id, CourseId, Title, AttemptsAllowed, ShuffleAnswers, CreatedBy)
VALUES (@qz1, @c1, N'Test Quiz', 2, 1, @adminId);

-- ===== QUESTIONS & OPTIONS =====
DECLARE @ques1 UNIQUEIDENTIFIER = NEWID();
DECLARE @op1 UNIQUEIDENTIFIER = NEWID();
DECLARE @op2 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Questions (Id, QuizId, [Text], [Order], CreatedBy)
VALUES (@ques1, @qz1, N'What is 5 + 5?', 1, @adminId);

INSERT INTO dbo.Options (Id, QuestionId, [Text], IsCorrect, CreatedBy)
VALUES
(@op1, @ques1, N'9', 0, @adminId),
(@op2, @ques1, N'10', 1, @adminId);

-- ===== QUIZ ATTEMPT & ANSWER =====
DECLARE @att1 UNIQUEIDENTIFIER = NEWID();
INSERT INTO dbo.QuizAttempts (Id, QuizId, UserId, StartedAt, SubmittedAt, Score)
VALUES (@att1, @qz1, @u1, SYSUTCDATETIME(), SYSUTCDATETIME(), 100);

INSERT INTO dbo.AttemptAnswers (Id, AttemptId, QuestionId, OptionId)
VALUES (NEWID(), @att1, @ques1, @op2);

-- ===== NOTIFICATIONS =====
INSERT INTO dbo.Notifications (Id, ToUserId, Title, Body, CreatedBy, SentBy)
VALUES
(NEWID(), @u1, N'Welcome', N'Welcome to Course Active', @adminId, @adminId),
(NEWID(), @u2, N'Congrats', N'You have completed Course Active', @adminId, @adminId);

-- ===== FILE ASSETS =====
INSERT INTO dbo.FileAssets (Id, OwnerUserId, FileName, MimeType, Size, StoragePath, CreatedBy)
VALUES
(NEWID(), @adminId, N'testfile.pdf', 'application/pdf', 12345, '/files/testfile.pdf', @adminId);

PRINT 'Seed TEST hoàn tất.';
GO
