import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import sys
from datetime import datetime, timezone

# Load hàm hash_password từ backend/main.py
try:
    from main import hash_password
except ImportError:
    print("Vui lòng chạy lệnh trong thư mục backend/")
    sys.exit(1)

MONGO_URL = "mongodb+srv://huynhhuyen01022004_db_user:JnR2UDe7WftTl4nL@cluster0.zpr4s7u.mongodb.net/?appName=Cluster0"
DB_NAME = "ky_nang_song"

async def make_admin(email: str):
    client = AsyncIOMotorClient(MONGO_URL)
    db = client[DB_NAME]
    col = db["users"]
    
    user = await col.find_one({"email": email})
    if not user:
        print(f"⚠️ Chưa có tài khoản với email '{email}'. Tiến hành TẠO MỚI...")
        new_user = {
            "name": "Admin Test",
            "email": email,
            "password_hash": hash_password("123456"),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "role": "admin",
        }
        await col.insert_one(new_user)
        print(f"✅ Đã tạo mới MIỄN PHÍ tài khoản quản lý (Admin)!")
        print(f"   Email: {email}")
        print(f"   Mật khẩu: 123456")
    else:
        await col.update_one({"email": email}, {"$set": {"role": "admin"}})
        print(f"✅ Mừng quá, đã NÂNG CẤP thành công '{email}' lên quản trị viên (Admin).")
        
    client.close()

if __name__ == "__main__":
    target_email = sys.argv[1] if len(sys.argv) > 1 else "admin@test.com"
    asyncio.run(make_admin(target_email))
