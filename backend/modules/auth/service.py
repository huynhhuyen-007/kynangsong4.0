from datetime import datetime, timezone

import shutil
from bson import ObjectId
from fastapi import HTTPException, UploadFile

from core.database import get_db
from core.security import hash_password, verify_password
from .schemas import UserInRegister, UserInLogin, UserPublic


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


async def login_user(body: UserInLogin) -> UserPublic:
    db = get_db()
    user = await db.users.find_one({"email": body.email})
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Email hoặc mật khẩu không đúng.")
    return UserPublic(
        id=str(user["_id"]),
        name=user["name"],
        email=user["email"],
        role=user.get("role", "user"),
        avatar_url=user.get("avatar_url"),
    )


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
