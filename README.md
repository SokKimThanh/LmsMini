LmsMini
=======

Một hệ thống quản lý học tập (Learning Management System) nhẹ, **chỉ bao gồm backend**, được xây dựng bằng .NET.

Mô tả dự án
-----------

LmsMini là hệ thống quản lý học tập theo mô-đun, tập trung vào **xử lý dữ liệu và cung cấp API** để quản lý khóa học, ghi danh, và danh tính người dùng. Dự án được phát triển trên .NET 7/9, tuân theo kiến trúc sạch (Clean Architecture), **không bao gồm giao diện người dùng**.

Cấu trúc dự án
--------------

-   `LmsMini.Api`: Lớp API xử lý các yêu cầu HTTP (REST/GraphQL).

-   `LmsMini.Application`: Logic nghiệp vụ, quy tắc kinh doanh và xử lý luồng dữ liệu.

-   `LmsMini.Domain`: Các thực thể cốt lõi và giá trị đối tượng.

-   `LmsMini.Infrastructure`: Tích hợp cơ sở dữ liệu và các dịch vụ bên ngoài.

-   `LmsMini.Tests`: Kiểm thử đơn vị và tích hợp.

Yêu cầu hệ thống
----------------

-   .NET 7 SDK hoặc mới hơn

-   SQL Server (hoặc DB được hỗ trợ khác)

> **Lưu ý**: Node.js và bất kỳ công cụ frontend nào **không cần thiết** do dự án chỉ tập trung vào backend.

Hướng dẫn cài đặt
-----------------

1.  Clone repository:

    bash

    ```
    git clone https://github.com/your-username/LmsMini.git

    ```

2.  Di chuyển vào thư mục dự án:

    bash

    ```
    cd LmsMini

    ```

3.  Khôi phục các gói phụ thuộc:

    bash

    ```
    dotnet restore

    ```

4.  Build solution:

    bash

    ```
    dotnet build

    ```

Chạy dự án
----------

-   Khởi động API:

    bash

    ```
    dotnet run --project LmsMini.Api

    ```

-   API sẽ chạy tại `https://localhost:5001`.

Đóng góp
--------

Mọi đóng góp tập trung vào **nâng cấp backend** đều được hoan nghênh! Fork repo và gửi pull request.

Giấy phép
---------

MIT License -- xem chi tiết tại LICENSE.

Tài liệu hướng dẫn
------------------

Tài liệu bổ sung (kiến trúc hệ thống, API contract, kịch bản test) có trong thư mục `docs`.
