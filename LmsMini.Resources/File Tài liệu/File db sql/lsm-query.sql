USE [LMSMini];
GO

PRINT '=== VERIFY COUNTS ===';

-- 1) Đếm số user
SELECT COUNT(*) AS TotalUsers FROM dbo.AspNetUsers;

-- 2) Đếm số course, phân loại Published/Draft/Archived
SELECT Status, COUNT(*) AS Total
FROM dbo.Courses
GROUP BY Status;

-- 3) Đếm Module / Lesson / Quiz / Question / Option
SELECT 'Modules' AS TableName, COUNT(*) AS Total FROM dbo.Modules
UNION ALL
SELECT 'Lessons', COUNT(*) FROM dbo.Lessons
UNION ALL
SELECT 'Quizzes', COUNT(*) FROM dbo.Quizzes
UNION ALL
SELECT 'Questions', COUNT(*) FROM dbo.Questions
UNION ALL
SELECT 'Options', COUNT(*) FROM dbo.Options;

PRINT '=== CHECK FK RELATIONSHIPS ===';

-- 4) Danh sách lesson không có module hợp lệ
SELECT l.Id, l.Title
FROM dbo.Lessons l
LEFT JOIN dbo.Modules m ON l.ModuleId = m.Id
WHERE m.Id IS NULL;

-- 5) Danh sách module không có course hợp lệ
SELECT m.Id, m.Title
FROM dbo.Modules m
LEFT JOIN dbo.Courses c ON m.CourseId = c.Id
WHERE c.Id IS NULL;

-- 6) Enrollment không có user hoặc course
SELECT e.Id, e.UserId, e.CourseId
FROM dbo.Enrollments e
LEFT JOIN dbo.AspNetUsers u ON e.UserId = u.Id
LEFT JOIN dbo.Courses c ON e.CourseId = c.Id
WHERE u.Id IS NULL OR c.Id IS NULL;

PRINT '=== TEST FILTERED UNIQUE INDEX ===';

-- 7) Course code trùng khi IsDeleted=0 (không được phép, trả về >0 tức là vi phạm)
SELECT Code, COUNT(*) AS Cnt
FROM dbo.Courses
WHERE IsDeleted = 0
GROUP BY Code
HAVING COUNT(*) > 1;

-- 8) Enrollment trùng khi IsDeleted=0
SELECT CourseId, UserId, COUNT(*) AS Cnt
FROM dbo.Enrollments
WHERE IsDeleted = 0
GROUP BY CourseId, UserId
HAVING COUNT(*) > 1;

PRINT '=== OTHER CHECKS ===';

-- 9) Progress percent ngoài 0–100
SELECT * FROM dbo.Progresses
WHERE [Percent] < 0 OR [Percent] > 100;

-- 10) QuizAttempts SubmitAt < StartAt (vi phạm logic)
SELECT * FROM dbo.QuizAttempts
WHERE SubmittedAt IS NOT NULL AND SubmittedAt < StartedAt;

-- 11) Check Option không có Question
SELECT o.Id, o.Text
FROM dbo.Options o
LEFT JOIN dbo.Questions q ON o.QuestionId = q.Id
WHERE q.Id IS NULL;

-- 12) Hiển thị các notification gần nhất
SELECT TOP 5 n.Title, n.Body, u.UserName AS ToUser
FROM dbo.Notifications n
LEFT JOIN dbo.AspNetUsers u ON n.ToUserId = u.Id
ORDER BY n.CreatedAt DESC;

-- 13) Thống kê số lesson mỗi course
SELECT c.Title AS CourseTitle, COUNT(l.Id) AS TotalLessons
FROM dbo.Courses c
LEFT JOIN dbo.Modules m ON m.CourseId = c.Id
LEFT JOIN dbo.Lessons l ON l.ModuleId = m.Id
GROUP BY c.Title;

-- 14) Liệt kê quiz + số câu hỏi
SELECT q.Title AS QuizTitle, COUNT(ques.Id) AS TotalQuestions
FROM dbo.Quizzes q
LEFT JOIN dbo.Questions ques ON ques.QuizId = q.Id
GROUP BY q.Title;

USE [LMSMini];
GO

PRINT '=== VERIFY FLOW DATA ===';

-- Check FLOW 1: Student A progress
SELECT u.UserName, c.Title AS Course, p.[Percent]
FROM dbo.Progresses p
JOIN dbo.Lessons l ON p.LessonId = l.Id
JOIN dbo.Modules m ON l.ModuleId = m.Id
JOIN dbo.Courses c ON m.CourseId = c.Id
JOIN dbo.AspNetUsers u ON p.UserId = u.Id
WHERE u.UserName LIKE 'alice%';

-- Check FLOW 2: Lecturer's new course
SELECT c.Code, c.Title, u.UserName AS CreatedBy
FROM dbo.Courses c
JOIN dbo.AspNetUsers u ON c.CreatedBy = u.Id
WHERE c.Code = 'NEW-101';

-- Check notification sent
SELECT n.Title, n.Body, u.UserName AS Recipient
FROM dbo.Notifications n
JOIN dbo.AspNetUsers u ON n.ToUserId = u.Id
WHERE n.CourseId = (SELECT Id FROM dbo.Courses WHERE Code = 'NEW-101');

-- Check FLOW 3: Outbox message exists
SELECT [Type]  , Payload, OccurredOn
FROM dbo.OutboxMessages
WHERE [Type] = 'CourseCreated';

-- Check FLOW 4: Enrollment completed & audit log
SELECT e.Id, e.Status, al.[Action], al.CreatedAt
FROM dbo.Enrollments e
JOIN dbo.AuditLogs al ON al.EntityId = e.CourseId
WHERE e.[Status] = 'Completed';
