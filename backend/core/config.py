from dotenv import load_dotenv
import os

# Đọc file .env trong thư mục backend/
# override=True: .env luôn thắng nếu biến đã tồn tại trong hệ thống
load_dotenv(override=True)


class Settings:
    # ── MongoDB ───────────────────────────────────────────────────────────────
    # Chuỗi kết nối MongoDB Atlas — lấy từ .env, KHÔNG hardcode vào code
    MONGO_URL: str = os.getenv("MONGO_URL", "mongodb://localhost:27017")

    # Tên database
    DB_NAME: str = os.getenv("DB_NAME", "ky_nang_song")

    # ── Gemini AI ─────────────────────────────────────────────────────────────
    # API Key của Google Gemini — dùng trong modules/ai/service.py
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    # ── Bảo mật ───────────────────────────────────────────────────────────────
    # SECRET_KEY: dùng để ký JWT token nếu sau này thêm tính năng xác thực
    # Hiện tại chưa dùng, nhưng để sẵn — KHÔNG để giá trị mặc định khi deploy
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change_me_before_deploy")

    # ── Upload file ───────────────────────────────────────────────────────────
    # Giới hạn kích thước file upload (bytes) — 50MB
    MAX_UPLOAD_BYTES: int = int(os.getenv("MAX_UPLOAD_BYTES", str(50 * 1024 * 1024)))


settings = Settings()
