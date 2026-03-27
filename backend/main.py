from __future__ import annotations

from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field

# ── Cấu hình MongoDB ──────────────────────────────────────────────────────────
# Mặc định kết nối MongoDB cài local.
# Nếu dùng MongoDB Atlas, thay bằng connection string của Atlas:
#   MONGO_URL = "mongodb+srv://<user>:<password>@cluster.mongodb.net/"
MONGO_URL = "mongodb+srv://huynhhuyen01022004_db_user:JnR2UDe7WftTl4nL@cluster0.zpr4s7u.mongodb.net/?appName=Cluster0"
DB_NAME = "ky_nang_song"

# ── Password hashing ──────────────────────────────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Pydantic models ───────────────────────────────────────────────────────────
class UserInRegister(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class UserInLogin(BaseModel):
    email: EmailStr
    password: str


class UserPublic(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: str = "user"


class RoleUpdate(BaseModel):
    admin_id: str
    target_email: str
    new_role: str


# ── MongoDB lifespan ─────────────────────────────────────────────────────────
mongo_client: Optional[AsyncIOMotorClient] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Khởi động và dọn dẹp kết nối MongoDB."""
    global mongo_client
    mongo_client = AsyncIOMotorClient(MONGO_URL)
    try:
        await mongo_client.admin.command("ping")
        print("✅ Kết nối MongoDB thành công!")
    except Exception as e:
        print(f"❌ Lỗi kết nối MongoDB: {e}")

    # Tạo unique index trên email để tránh trùng lặp
    db = mongo_client[DB_NAME]
    await db.users.create_index("email", unique=True)

    yield  # App đang chạy

    # Shutdown
    mongo_client.close()
    print("🔌 Đã đóng kết nối MongoDB.")


# ── FastAPI app ───────────────────────────────────────────────────────────────
app = FastAPI(title="Ky Nang Song Auth API - MongoDB", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_users_collection():
    return mongo_client[DB_NAME]["users"]


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)


# ── API Endpoints ─────────────────────────────────────────────────────────────
@app.post("/api/auth/register", response_model=UserPublic)
async def register(body: UserInRegister):
    col = get_users_collection()

    # Kiểm tra email đã tồn tại
    existing = await col.find_one({"email": body.email})
    if existing:
        raise HTTPException(
            status_code=409,
            detail="Email này đã được đăng ký, vui lòng dùng email khác."
        )

    # Tạo document mới
    new_user = {
        "name": body.name,
        "email": body.email,
        "password_hash": hash_password(body.password),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "role": "user",
    }

    result = await col.insert_one(new_user)
    user_id = str(result.inserted_id)

    return UserPublic(id=user_id, name=body.name, email=body.email, role="user")


@app.post("/api/auth/login", response_model=UserPublic)
async def login(body: UserInLogin):
    col = get_users_collection()

    user = await col.find_one({"email": body.email})
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(
            status_code=401,
            detail="Email hoặc mật khẩu không đúng."
        )

    return UserPublic(
        id=str(user["_id"]),
        name=user["name"],
        email=user["email"],
        role=user.get("role", "user"),
    )


@app.get("/api/admin/users")
async def get_all_users(admin_id: str):
    col = get_users_collection()
    
    # Check quyền admin
    admin = await col.find_one({"_id": ObjectId(admin_id)})
    if not admin or admin.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Không có quyền truy cập.")
        
    users_cursor = col.find({}, {"password_hash": 0})
    users = await users_cursor.to_list(length=1000)
    return [
        {
            "id": str(u["_id"]),
            "name": u.get("name"),
            "email": u.get("email"),
            "role": u.get("role", "user")
        }
        for u in users
    ]


@app.post("/api/admin/set_role")
async def set_role(body: RoleUpdate):
    col = get_users_collection()
    
    # Check quyền admin
    admin = await col.find_one({"_id": ObjectId(body.admin_id)})
    if not admin or admin.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Không có quyền truy cập.")
        
    # Cập nhật role
    result = await col.update_one(
        {"email": body.target_email},
        {"$set": {"role": body.new_role}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy người dùng này.")
        
    return {"status": "success"}


@app.get("/api/health")
async def health():
    """Kiểm tra trạng thái server và MongoDB."""
    try:
        await mongo_client.admin.command("ping")
        return {"status": "ok", "database": "MongoDB connected"}
    except Exception as e:
        return {"status": "error", "database": str(e)}
