namespace LmsMini.Application.Auth
{
    /// <summary>
    /// Tùy chọn cấu hình cho JWT (JSON Web Token) dùng trong ứng dụng.
    /// </summary>
    /// <remarks>
    /// Chứa các cấu hình cần thiết để tạo và xác thực token: khoá bí mật, issuer, audience và thời hạn.
    /// Lưu ý: Giá trị <see cref="Key"/> không nên để rỗng trong môi trường sản xuất và nên được lấy từ nguồn bảo mật
    /// (ví dụ: biến môi trường, Secret Manager hoặc hệ thống quản lý bí mật).
    /// </remarks>
    public class JwtOptions
    {
        /// <summary>
        /// Khoá bí mật dùng để ký token (HMAC). 
        /// </summary>
        /// <remarks>
        /// Mặc định là chuỗi rỗng. Trong môi trường thực tế, hãy gán giá trị an toàn (đủ độ dài và ngẫu nhiên).
        /// </remarks>
        public string Key { get; set; } = string.Empty;

        /// <summary>
        /// Nhà phát hành (issuer) của token.
        /// </summary>
        /// <value>Mặc định: "LmsMini".</value>
        public string Issuer { get; set; } = "LmsMini";

        /// <summary>
        /// Người nhận (audience) của token.
        /// </summary>
        /// <value>Mặc định: "LmsMiniClient".</value>
        public string Audience { get; set; } = "LmsMiniClient";

        /// <summary>
        /// Thời lượng hiệu lực của token tính theo phút.
        /// </summary>
        /// <value>Mặc định: 60 (phút).</value>
        public int ExpiresInMinutes { get; set; } = 60;
    }
}
