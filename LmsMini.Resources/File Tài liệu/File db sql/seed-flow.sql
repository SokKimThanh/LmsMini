USE [LMSMini];
GO

PRINT '=== SEED THEO LUỒNG CHÍNH ===';

-- ==== FLOW 1: Student enrolls & learns & takes quiz ====
DECLARE @studentA UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM dbo.AspNetUsers WHERE UserName LIKE 'alice%');
DECLARE @courseA UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM dbo.Courses WHERE Code = 'INTRO-001');
DECLARE @lessonA UNIQUEIDENTIFIER = (SELECT TOP 1 l.Id FROM dbo.Lessons l 
                                     JOIN dbo.Modules m ON l.ModuleId = m.Id
                                     WHERE m.CourseId = @courseA);

-- Enroll
DECLARE @enrA UNIQUEIDENTIFIER = NEWID();
INSERT INTO dbo.Enrollments (Id, CourseId, UserId, StartAt, [Status], CreatedBy)
VALUES (@enrA, @courseA, @studentA, SYSUTCDATETIME(), 'Active', @studentA);

-- Complete lesson
INSERT INTO dbo.Progresses (Id, UserId, LessonId, [Percent], CreatedBy)
VALUES (NEWID(), @studentA, @lessonA, 100, @studentA);

-- Take quiz
DECLARE @quizA UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM dbo.Quizzes WHERE CourseId = @courseA);
DECLARE @questionA UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM dbo.Questions WHERE QuizId = @quizA);
DECLARE @optionCorrect UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM dbo.Options WHERE QuestionId = @questionA AND IsCorrect = 1);

DECLARE @attA UNIQUEIDENTIFIER = NEWID();
INSERT INTO dbo.QuizAttempts (Id, QuizId, UserId, StartedAt, SubmittedAt, Score)
VALUES (@attA, @quizA, @studentA, SYSUTCDATETIME(), SYSUTCDATETIME(), 100);

INSERT INTO dbo.AttemptAnswers (Id, AttemptId, QuestionId, OptionId)
VALUES (NEWID(), @attA, @questionA, @optionCorrect);

-- ==== FLOW 2: Lecturer creates a new course & module/lesson & sends notification ====
DECLARE @lecturer UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM dbo.AspNetUsers WHERE UserName LIKE 'lecturer%');
DECLARE @newCourse UNIQUEIDENTIFIER = NEWID();
DECLARE @newModule UNIQUEIDENTIFIER = NEWID();
DECLARE @newLesson UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Courses (Id, Code, Title, Description, Status, CreatedBy)
VALUES (@newCourse, 'NEW-101', N'Course New Release', N'Khoá học mới cho test flow', 'Draft', @lecturer);

INSERT INTO dbo.Modules (Id, CourseId, Title, [Order], CreatedBy)
VALUES (@newModule, @newCourse, N'Intro Module', 1, @lecturer);

INSERT INTO dbo.Lessons (Id, ModuleId, Title, ContentType, DurationSec, [Order], CreatedBy)
VALUES (@newLesson, @newModule, N'First Lesson', 'article', 300, 1, @lecturer);

-- Gửi thông báo tới học viên
INSERT INTO dbo.Notifications (Id, CourseId, ToUserId, Title, Body, CreatedBy, SentBy)
VALUES (NEWID(), @newCourse, @studentA, N'Khoá học mới', N'Mời bạn tham gia khoá học mới vừa được tạo.', @lecturer, @lecturer);

-- ==== FLOW 3: Outbox event giả lập (publish course created) ====
INSERT INTO dbo.OutboxMessages (Id, OccurredOn, [Type], Payload)
VALUES (NEWID(), SYSUTCDATETIME(), N'CourseCreated', N'{"CourseId":"'+CAST(@newCourse AS NVARCHAR(36))+'"}');

-- ==== FLOW 4: Complete course & log ====
UPDATE dbo.Enrollments SET Status = 'Completed', UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @studentA
WHERE Id = @enrA;

INSERT INTO dbo.Auditlogs (Id, UserId, [Action], Entity, EntityId)
VALUES (NEWID(), @studentA, N'CompleteCourse', N'Course', @courseA);

PRINT '=== SEED-FLOW COMPLETED ===';
GO
