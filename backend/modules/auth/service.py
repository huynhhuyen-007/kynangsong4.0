from collections import defaultdict
from datetime import datetime, timezone, timedelta
import secrets
import shutil

from bson import ObjectId
from fastapi import HTTPException, UploadFile

from core.database import get_db
from core.security import hash_password, verify_password
from .schemas import UserInRegister, UserInLogin, UserPublic, ForgotPasswordRequest, ResetPasswordRequest


# ── Rate Limiting ─────────────────────────────────────────────────────────────
_login_attempts: dict[str, list[datetime]] = defaultdict(list)
_RATE_LIMIT = 5          # so lan toi da
_RATE_WINDOW = 300       # giay (5 phut)


def _check_rate_limit(email: str) -> None:
    """Kiem tra rate limit: qua 5 lan trong 5 phut -> 429."""
    now = datetime.now(timezone.utc)
    recent = [t for t in _login_attempts[email]
              if (now - t).total_seconds() < _RATE_WINDOW]
    _login_attempts[email] = recent
    if len(recent) >= _RATE_LIMIT:
        raise HTTPException(
            status_code=429,
            detail=f"Quá nhiều lần thử. Vui lòng thử lại sau {_RATE_WINDOW // 60} phút."
        )


# ── Register ──────────────────────────────────────────────────────────────────
async def register_user(body: UserInRegister) -> UserPublic:
    db = get_db()
    existing = await db.users.find_one({"email": body.email})
    if existing:
        raise HTTPException(status_code=409, detail="Email này đã được đăng ký, vui lòng dùng email khác.")
    new_user = {
        "name": body.name,
        "email": body.email,
        "password_hash": hash_password(body.password),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "role": "user",
    }
    result = await db.users.insert_one(new_user)
    return UserPublic(id=str(result.inserted_id), name=body.name, email=body.email, role="user")


# ── Login ─────────────────────────────────────────────────────────────────────
async def login_user(body: UserInLogin) -> UserPublic:
    _check_rate_limit(body.email)
    _login_attempts[body.email].append(datetime.now(timezone.utc))
    db = get_db()
    user = await db.users.find_one({"email": body.email})
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Email hoặc mật khẩu không đúng.")
    # Reset attempts khi login thanh cong
    _login_attempts.pop(body.email, None)
    return UserPublic(
        id=str(user["_id"]),
        name=user["name"],
        email=user["email"],
        role=user.get("role", "user"),
        avatar_url=user.get("avatar_url"),
    )


# ── Forgot Password ───────────────────────────────────────────────────────────
async def forgot_password(body: ForgotPasswordRequest) -> dict:
    db = get_db()
    user = await db.users.find_one({"email": body.email})
    # Luon tra 200 de khong leak thong tin email ton tai
    if not user:
        return {"status": "sent", "demo_token": None}
    # Tao token 6 chu so (demo mode)
    token = str(secrets.randbelow(900000) + 100000)  # 100000-999999
    expire_at = (datetime.now(timezone.utc) + timedelta(minutes=15)).isoformat()
    # Luu token vao DB
    await db.users.update_one(
        {"email": body.email},
        {"$set": {"reset_token": token, "reset_token_expire": expire_at}}
    )
    # Demo mode: tra ve token thang (khong gui email that)
    return {"status": "sent", "demo_token": token}


# ── Reset Password ────────────────────────────────────────────────────────────
async def reset_password(body: ResetPasswordRequest) -> dict:
    db = get_db()
    now = datetime.now(timezone.utc).isoformat()
    user = await db.users.find_one({
        "reset_token": body.token,
        "reset_token_expire": {"$gt": now},
    })
    if not user:
        raise HTTPException(status_code=400, detail="Mã xác nhận không hợp lệ hoặc đã hết hạn.")
    await db.users.update_one(
        {"_id": user["_id"]},
        {
            "$set": {"password_hash": hash_password(body.new_password)},
            "$unset": {"reset_token": "", "reset_token_expire": ""},
        }
    )
    return {"status": "success"}


# ── Upload Avatar ─────────────────────────────────────────────────────────────
async def upload_avatar(user_id: str, file: UploadFile) -> dict:
    db = get_db()
    try:
        user = await db.users.find_one({"_id": ObjectId(user_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="user_id không hợp lệ.")
    if not user:
        raise HTTPException(status_code=404, detail="Người dùng không tồn tại.")
    ext = (file.filename or "jpg").split(".")[-1]
    filename = f"{user_id}_{int(datetime.now(timezone.utc).timestamp())}.{ext}"
    filepath = f"static/avatars/{filename}"
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    avatar_url = f"/static/avatars/{filename}"
    await db.users.update_one({"_id": ObjectId(user_id)}, {"$set": {"avatar_url": avatar_url}})
    return {"avatar_url": avatar_url}

