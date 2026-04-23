"""
make_admin.py — Tạo hoặc nâng cấp tài khoản lên Admin.

Cách chạy (trong thư mục backend/):
    python make_admin.py admin@example.com

Cấu hình MongoDB lấy từ file .env (thông qua core/config.py).
Không hardcode credential trong file này.
"""
import asyncio
import sys
import certifi
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorClient

# Lấy config từ core/config.py — MongoDB URL & DB_NAME từ .env
from core.config import settings
from core.security import hash_password


async def make_admin(email: str):
    client = AsyncIOMotorClient(
        settings.MONGO_URL,
        tls=True,
        tlsCAFile=certifi.where(),
    )
    db = client[settings.DB_NAME]
    col = db["users"]

    user = await col.find_one({"email": email})
    if not user:
        print(f"[!] Chua co tai khoan voi email '{email}'. Tien hanh TAO MOI...")
        new_user = {
            "name": "Admin",
            "email": email,
            "password_hash": hash_password("123456"),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "role": "admin",
        }
        await col.insert_one(new_user)
        print(f"[OK] Da tao moi tai khoan Admin!")
        print(f"     Email   : {email}")
        print(f"     Mat khau: 123456")
    else:
        await col.update_one({"email": email}, {"$set": {"role": "admin"}})
        print(f"[OK] Da NANG CAP '{email}' len Admin thanh cong.")

    client.close()


if __name__ == "__main__":
    target_email = sys.argv[1] if len(sys.argv) > 1 else "admin@test.com"
    asyncio.run(make_admin(target_email))
