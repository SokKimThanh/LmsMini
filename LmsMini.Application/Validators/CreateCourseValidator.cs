using FluentValidation;
using LmsMini.Application.Features.Courses.Commands;
using System;

namespace LmsMini.Application.Validators
{
    public class CreateCourseValidator : AbstractValidator<CreateCourseCommand>
    {
        public CreateCourseValidator()
        {
            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Title bắt buộc nhập")
                .MaximumLength(200).WithMessage("Title không được vượt quá 200 ký tự");

            RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Description bắt buộc nhập")
                .MaximumLength(1000).WithMessage("Description không được vượt quá 1000 ký tự");

            RuleFor(x => x.CreatedBy)
                .NotEmpty().WithMessage("CreatedBy bắt buộc")
                .Must(id => id != Guid.Empty).WithMessage("CreatedBy phải là GUID hợp lệ");
        }
    }
}
