from __future__ import annotations

from contextlib import asynccontextmanager
from typing import Optional

import certifi
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from core.config import settings

# Global instances — được khởi tạo trong lifespan, dùng chung toàn app
_client: Optional[AsyncIOMotorClient] = None
_db: Optional[AsyncIOMotorDatabase] = None


@asynccontextmanager
async def lifespan(app):
    """Quản lý vòng đời kết nối MongoDB.
    
    - Startup: mở kết nối, tạo index cần thiết
    - Shutdown: đóng kết nối, tránh memory leak
    """
    global _client, _db

    _client = AsyncIOMotorClient(
        settings.MONGO_URL,
        tls=True,
        tlsCAFile=certifi.where(),
    )
    _db = _client[settings.DB_NAME]

    try:
        await _client.admin.command("ping")
        print(f"[OK] MongoDB connected! DB: {settings.DB_NAME}")
    except Exception as e:
        print(f"[ERROR] MongoDB connection failed: {e}")

    # Tạo unique index để tránh email trùng lặp
    await _db.users.create_index("email", unique=True)

    yield  # App đang chạy

    # Shutdown — đóng kết nối sạch sẽ
    _client.close()
    print("[OK] MongoDB disconnected.")


def get_db() -> AsyncIOMotorDatabase:
    """Trả về database instance. Dùng trong tất cả service modules.
    
    Usage:
        from core.database import get_db
        db = get_db()
        await db.users.find_one(...)
    """
    if _db is None:
        raise RuntimeError("Database chưa được khởi tạo. Đảm bảo lifespan đang chạy.")
    return _db
