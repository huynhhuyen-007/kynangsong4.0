from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException

from core.database import get_db
from .schemas import PostCreate, CommentCreate, LikeRequest, ReportRequest


def _serialize_post(p: dict) -> dict:
    pid = p.get("_id")
    return {
        "id": str(pid) if pid else p.get("id", ""),
        "user_id": p.get("user_id", ""),
        "user_name": p.get("user_name", ""),
        "content": p.get("content", ""),
        "topic": p.get("topic", "Chung"),
        "image_url": p.get("image_url"),          # <-- NEW
        "likes": p.get("likes", []),
        "likes_count": p.get("likes_count", 0),
        "comments_count": p.get("comments_count", 0),
        "reported_by": p.get("reported_by", []),
        "created_at": p.get("created_at", ""),
        "is_pinned": p.get("is_pinned", False),
        "is_hidden": p.get("is_hidden", False),
    }


async def get_posts(sort: str = "new") -> list:
    db = get_db()
    sort_field = "likes_count" if sort == "hot" else "created_at"
    cursor = db.posts.find({"is_hidden": {"$ne": True}}).sort(sort_field, -1)
    posts = await cursor.to_list(length=200)
    return [_serialize_post(p) for p in posts]


async def create_post(body: PostCreate) -> dict:
    db = get_db()
    doc = {
        "user_id": body.user_id,
        "user_name": body.user_name,
        "content": body.content,
        "topic": body.topic,
        "image_url": body.image_url,               # <-- NEW
        "likes": [],
        "likes_count": 0,
        "comments_count": 0,
        "reported_by": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_hidden": False,
        "is_pinned": False,
    }
    result = await db.posts.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize_post(doc)


async def toggle_like(post_id: str, body: LikeRequest) -> dict:
    db = get_db()
    post = await db.posts.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Bài đăng không tồn tại.")
    likes = list(post.get("likes", []))
    if body.user_id in likes:
        likes.remove(body.user_id)
    else:
        likes.append(body.user_id)
    await db.posts.update_one(
        {"_id": ObjectId(post_id)},
        {"$set": {"likes": likes, "likes_count": len(likes)}}
    )
    return {"liked": body.user_id in likes, "likes_count": len(likes)}


async def report_post(post_id: str, body: ReportRequest) -> dict:
    db = get_db()
    post = await db.posts.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Bài đăng không tồn tại.")
    reported = list(post.get("reported_by", []))
    if body.user_id not in reported:
        reported.append(body.user_id)
        await db.posts.update_one({"_id": ObjectId(post_id)}, {"$set": {"reported_by": reported}})
    return {"status": "reported"}


async def delete_post(post_id: str) -> dict:
    db = get_db()
    await db.posts.delete_one({"_id": ObjectId(post_id)})
    await db.comments.delete_many({"post_id": post_id})
    return {"status": "deleted"}


async def get_comments(post_id: str) -> list:
    db = get_db()
    cursor = db.comments.find({"post_id": post_id}).sort("created_at", 1)
    comments = await cursor.to_list(length=500)
    return [
        {
            "id": str(c["_id"]),
            "user_id": c.get("user_id", ""),
            "user_name": c.get("user_name", ""),
            "content": c.get("content", ""),
            "reported_by": c.get("reported_by", []),
            "created_at": c.get("created_at", ""),
        }
        for c in comments
    ]


async def add_comment(post_id: str, body: CommentCreate) -> dict:
    db = get_db()
    try:
        obj_id = ObjectId(post_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Mã bài đăng không hợp lệ.")
    post = await db.posts.find_one({"_id": obj_id})
    if not post:
        raise HTTPException(status_code=404, detail="Bài đăng không tồn tại.")
    doc = {
        "post_id": post_id,
        "user_id": body.user_id,
        "user_name": body.user_name,
        "content": body.content,
        "reported_by": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await db.comments.insert_one(doc)
    await db.posts.update_one({"_id": obj_id}, {"$inc": {"comments_count": 1}})
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}


async def report_comment(comment_id: str, body: ReportRequest) -> dict:
    db = get_db()
    comment = await db.comments.find_one({"_id": ObjectId(comment_id)})
    if not comment:
        raise HTTPException(status_code=404, detail="Bình luận không tồn tại.")
    reported = list(comment.get("reported_by", []))
    if body.user_id not in reported:
        reported.append(body.user_id)
        await db.comments.update_one({"_id": ObjectId(comment_id)}, {"$set": {"reported_by": reported}})
    return {"status": "reported"}
