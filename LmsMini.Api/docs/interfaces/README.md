# Interface visibility và cách implement trong C#

M?c tiêu: gi?i thích ng?n g?n v? visibility c?a interface và cách các phýõng th?c c?a interface ðý?c s? d?ng khi implement.

Tóm t?t:
- ? c?p namespace, n?u b?n khai `public interface IMy { ... }` th? type này có th? dùng t? các assembly khác.
- N?u b?n **không** khai access modifier (ví d?: `interface IMy { }`) th? m?c ð?nh type là `internal` (ch? th?y trong cùng assembly).
- Các thành viên c?a interface (phýõng th?c, property, v.v.) _m?c ð?nh_ là `public`. B?n không c?n (và thý?ng không ðý?c) vi?t access modifier trên các thành viên.
- Khi m?t l?p implement interface, có hai cách:
  - Implicit implementation (tri?n khai thông thý?ng): phýõng th?c tri?n khai ðý?c khai là `public` — có th? g?i tr?c ti?p t? instance.
  - Explicit interface implementation (tri?n khai tý?ng minh): ð?nh danh ki?u khi tri?n khai (`void IMy.Method() { ... }`) — phýõng th?c này *không* xu?t hi?n là public trên l?p, ch? có th? g?i khi instance ðý?c cast v? interface.

G?i ?:
- N?u repository/contract c?n dùng t? các project khác (ví d? ðãng k? DI t? assembly khác), khai `public interface ICourseRepository` là h?p l?.
- N?u ch? dùng n?i b? trong assembly, có th? ð? m?c ð?nh `internal` b?ng cách không ghi `public`.

Ví d? minh ho? xem file examples/MinimalInterfaceExample.md

N?u c?n b?n ti?ng Anh ho?c m? r?ng ví d? v?i async/Task (nhý ICourseRepository), báo r? yêu c?u.