from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException, UploadFile

from core.config import settings
from core.database import get_db
from modules.skill.schemas import SkillUpsert
from modules.news.schemas import NewsUpsert
from .schemas import RoleUpdate, FunUpsert


async def check_admin(admin_id: str) -> None:
    """Kiểm tra quyền admin. Raise 403 nếu không có quyền."""
    db = get_db()
    try:
        admin = await db.users.find_one({"_id": ObjectId(admin_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="admin_id không hợp lệ.")
    if not admin or admin.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Không có quyền truy cập.")


async def get_all_users(admin_id: str) -> list:
    await check_admin(admin_id)
    db = get_db()
    cursor = db.users.find({}, {"password_hash": 0})
    users = await cursor.to_list(length=1000)
    return [
        {
            "id": str(u["_id"]),
            "name": u.get("name"),
            "email": u.get("email"),
            "role": u.get("role", "user"),
            "avatar_url": u.get("avatar_url"),
            "created_at": u.get("created_at", ""),
        }
        for u in users
    ]


async def delete_user(user_id: str, admin_id: str) -> dict:
    await check_admin(admin_id)
    if user_id == admin_id:
        raise HTTPException(status_code=400, detail="Không thể tự xóa tài khoản của mình.")
    db = get_db()
    try:
        target = await db.users.find_one({"_id": ObjectId(user_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="user_id không hợp lệ.")
    if not target:
        raise HTTPException(status_code=404, detail="Không tìm thấy người dùng.")
    if target.get("role") == "admin":
        raise HTTPException(status_code=403, detail="Không thể xóa tài khoản admin khác.")
    await db.users.delete_one({"_id": ObjectId(user_id)})
    await db.posts.delete_many({"user_id": user_id})
    await db.comments.delete_many({"user_id": user_id})
    return {"status": "deleted"}


async def set_role(body: RoleUpdate) -> dict:
    await check_admin(body.admin_id)
    db = get_db()
    result = await db.users.update_one(
        {"email": body.target_email},
        {"$set": {"role": body.new_role}}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy người dùng này.")
    return {"status": "success"}


async def get_stats(admin_id: str) -> dict:
    await check_admin(admin_id)
    db = get_db()
    return {
        "total_users": await db.users.count_documents({}),
        "total_skills": await db.skills.count_documents({}),
        "total_news": await db.news.count_documents({}),
        "total_posts": await db.posts.count_documents({}),
        "hidden_posts": await db.posts.count_documents({"is_hidden": True}),
        "reported_posts": await db.posts.count_documents(
            {"reported_by": {"$exists": True, "$not": {"$size": 0}}}
        ),
    }


async def upload_media(admin_id: str, file: UploadFile) -> dict:
    await check_admin(admin_id)
    content = await file.read()
    if len(content) > settings.MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail=f"File quá lớn, tối đa {settings.MAX_UPLOAD_BYTES // (1024*1024)}MB.")
    allowed_ext = {"jpg", "jpeg", "png", "webp", "gif", "mp4", "mov", "avi"}
    ext = (file.filename or "").rsplit(".", 1)[-1].lower()
    if ext not in allowed_ext:
        raise HTTPException(status_code=415, detail="Định dạng không hợp lệ.")
    filename = f"skill_{int(datetime.now(timezone.utc).timestamp())}_{admin_id[:8]}.{ext}"
    filepath = f"static/skills/{filename}"
    with open(filepath, "wb") as buffer:
        buffer.write(content)
    return {"image_url": f"/static/skills/{filename}"}


async def get_admin_posts(admin_id: str) -> list:
    await check_admin(admin_id)
    db = get_db()
    cursor = db.posts.find().sort("created_at", -1)
    posts = await cursor.to_list(length=500)
    return [
        {
            "id": str(p["_id"]),
            "user_id": p.get("user_id", ""),
            "user_name": p.get("user_name", ""),
            "content": p.get("content", ""),
            "topic": p.get("topic", "Chung"),
            "likes_count": p.get("likes_count", 0),
            "comments_count": p.get("comments_count", 0),
            "reported_by": p.get("reported_by", []),
            "created_at": p.get("created_at", ""),
            "is_pinned": p.get("is_pinned", False),
            "is_hidden": p.get("is_hidden", False),
        }
        for p in posts
    ]


async def toggle_hide_post(post_id: str, admin_id: str) -> dict:
    await check_admin(admin_id)
    db = get_db()
    post = await db.posts.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài đăng.")
    new_hidden = not post.get("is_hidden", False)
    await db.posts.update_one({"_id": ObjectId(post_id)}, {"$set": {"is_hidden": new_hidden}})
    return {"is_hidden": new_hidden}


async def get_all_comments(admin_id: str) -> list:
    await check_admin(admin_id)
    db = get_db()
    cursor = db.comments.find().sort("created_at", -1)
    comments = await cursor.to_list(length=1000)
    return [
        {
            "id": str(c["_id"]),
            "post_id": c.get("post_id", ""),
            "user_id": c.get("user_id", ""),
            "user_name": c.get("user_name", ""),
            "content": c.get("content", ""),
            "reported_by": c.get("reported_by", []),
            "report_count": len(c.get("reported_by", [])),
            "created_at": c.get("created_at", ""),
        }
        for c in comments
    ]


async def delete_comment(comment_id: str, admin_id: str) -> dict:
    await check_admin(admin_id)
    db = get_db()
    try:
        comment = await db.comments.find_one({"_id": ObjectId(comment_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="comment_id không hợp lệ.")
    if not comment:
        raise HTTPException(status_code=404, detail="Không tìm thấy bình luận.")
    await db.comments.delete_one({"_id": ObjectId(comment_id)})
    post_id = comment.get("post_id")
    if post_id:
        await db.posts.update_one({"_id": ObjectId(post_id)}, {"$inc": {"comments_count": -1}})
    return {"status": "deleted"}


async def get_skill_categories_admin(admin_id: str) -> list:
    await check_admin(admin_id)
    db = get_db()
    categories = await db.skills.distinct("category")
    result = []
    for cat in sorted(categories):
        count = await db.skills.count_documents({"category": cat})
        result.append({"name": cat, "count": count})
    return result


# ── Admin CMS — Fun content ───────────────────────────────────────────────────

async def create_fun(body: FunUpsert) -> dict:
    await check_admin(body.admin_id)
    db = get_db()
    doc = {
        "title": body.title, "type": body.type,
        "media_url": body.media_url, "content": body.content,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await db.fun.insert_one(doc)
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}


async def update_fun(fun_id: str, body: FunUpsert) -> dict:
    await check_admin(body.admin_id)
    db = get_db()
    result = await db.fun.update_one(
        {"_id": ObjectId(fun_id)},
        {"$set": {"title": body.title, "type": body.type,
                  "media_url": body.media_url, "content": body.content}}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy nội dung.")
    return {"status": "updated"}


async def delete_fun(fun_id: str, admin_id: str) -> dict:
    await check_admin(admin_id)
    db = get_db()
    await db.fun.delete_one({"_id": ObjectId(fun_id)})
    return {"status": "deleted"}
