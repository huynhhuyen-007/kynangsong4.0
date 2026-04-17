from fastapi import APIRouter, HTTPException, UploadFile, File
from datetime import datetime, timezone
from bson import ObjectId
import shutil

import main

router = APIRouter()

@router.post("/api/auth/register", response_model=main.UserPublic)
async def register(body: main.UserInRegister):
    col = main.get_users_collection()

    existing = await col.find_one({"email": body.email})
    if existing:
        raise HTTPException(
            status_code=409,
            detail="Email này đã được đăng ký, vui lòng dùng email khác."
        )

    new_user = {
        "name": body.name,
        "email": body.email,
        "password_hash": main.hash_password(body.password),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "role": "user",
    }

    result = await col.insert_one(new_user)
    user_id = str(result.inserted_id)

    return main.UserPublic(id=user_id, name=body.name, email=body.email, role="user", avatar_url=None)


@router.post("/api/auth/login", response_model=main.UserPublic)
async def login(body: main.UserInLogin):
    col = main.get_users_collection()

    user = await col.find_one({"email": body.email})
    if not user or not main.verify_password(body.password, user["password_hash"]):
        raise HTTPException(
            status_code=401,
            detail="Email hoặc mật khẩu không đúng."
        )

    return main.UserPublic(
        id=str(user["_id"]),
        name=user["name"],
        email=user["email"],
        role=user.get("role", "user"),
        avatar_url=user.get("avatar_url"),
    )

@router.post("/api/users/{user_id}/avatar")
async def upload_avatar(user_id: str, file: UploadFile = File(...)):
    col = main.get_users_collection()
    user = await col.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="Người dùng không tồn tại")
        
    ext = file.filename.split(".")[-1]
    filename = f"{user_id}_{int(datetime.now(timezone.utc).timestamp())}.{ext}"
    filepath = f"static/avatars/{filename}"
    
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    avatar_url = f"/static/avatars/{filename}"
    await col.update_one({"_id": ObjectId(user_id)}, {"$set": {"avatar_url": avatar_url}})
    return {"avatar_url": avatar_url}
