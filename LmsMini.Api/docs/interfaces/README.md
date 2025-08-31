# Interface visibility v� c�ch implement trong C#

M?c ti�u: gi?i th�ch ng?n g?n v? visibility c?a interface v� c�ch c�c ph��ng th?c c?a interface ��?c s? d?ng khi implement.

T�m t?t:
- ? c?p namespace, n?u b?n khai `public interface IMy { ... }` th? type n�y c� th? d�ng t? c�c assembly kh�c.
- N?u b?n **kh�ng** khai access modifier (v� d?: `interface IMy { }`) th? m?c �?nh type l� `internal` (ch? th?y trong c�ng assembly).
- C�c th�nh vi�n c?a interface (ph��ng th?c, property, v.v.) _m?c �?nh_ l� `public`. B?n kh�ng c?n (v� th�?ng kh�ng ��?c) vi?t access modifier tr�n c�c th�nh vi�n.
- Khi m?t l?p implement interface, c� hai c�ch:
  - Implicit implementation (tri?n khai th�ng th�?ng): ph��ng th?c tri?n khai ��?c khai l� `public` � c� th? g?i tr?c ti?p t? instance.
  - Explicit interface implementation (tri?n khai t�?ng minh): �?nh danh ki?u khi tri?n khai (`void IMy.Method() { ... }`) � ph��ng th?c n�y *kh�ng* xu?t hi?n l� public tr�n l?p, ch? c� th? g?i khi instance ��?c cast v? interface.

G?i ?:
- N?u repository/contract c?n d�ng t? c�c project kh�c (v� d? ��ng k? DI t? assembly kh�c), khai `public interface ICourseRepository` l� h?p l?.
- N?u ch? d�ng n?i b? trong assembly, c� th? �? m?c �?nh `internal` b?ng c�ch kh�ng ghi `public`.

V� d? minh ho? xem file examples/MinimalInterfaceExample.md

N?u c?n b?n ti?ng Anh ho?c m? r?ng v� d? v?i async/Task (nh� ICourseRepository), b�o r? y�u c?u.