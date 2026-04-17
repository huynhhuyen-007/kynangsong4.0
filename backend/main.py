from __future__ import annotations

import certifi
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Optional

import os
import shutil
from bson import ObjectId
from fastapi import FastAPI, HTTPException, UploadFile, File, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field

import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv(override=True)

# Setup Gemini AI
genai_api_key = os.environ.get("GEMINI_API_KEY", "YOUR_NEW_API_KEY_HERE")
genai.configure(api_key=genai_api_key)

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
    avatar_url: Optional[str] = None


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
    # tlsCAFile=certifi.where() cung cấp CA bundle mới nhất, tương thích Python 3.13
    mongo_client = AsyncIOMotorClient(
        MONGO_URL,
        tls=True,
        tlsCAFile=certifi.where(),
    )
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

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={"detail": "Lỗi định dạng dữ liệu (có thể do nhập sai khoảng trắng/Email): " + str(exc.errors()[0]['msg'])},
    )

os.makedirs("static/avatars", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

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
            "role": u.get("role", "user"),
            "avatar_url": u.get("avatar_url"),
            "created_at": u.get("created_at", ""),
        }
        for u in users
    ]


@app.delete("/api/admin/users/{user_id}")
async def delete_user(user_id: str, admin_id: str):
    """Admin xóa tài khoản người dùng (không thể xóa chính mình hoặc admin khác)."""
    await _check_admin(admin_id)
    if user_id == admin_id:
        raise HTTPException(status_code=400, detail="Không thể tự xóa tài khoản của mình.")
    col = get_users_collection()
    try:
        target = await col.find_one({"_id": ObjectId(user_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="user_id không hợp lệ.")
    if not target:
        raise HTTPException(status_code=404, detail="Không tìm thấy người dùng.")
    if target.get("role") == "admin":
        raise HTTPException(status_code=403, detail="Không thể xóa tài khoản admin khác.")
    await col.delete_one({"_id": ObjectId(user_id)})
    # Xóa toàn bộ bài đăng và comment của user đó
    await mongo_client[DB_NAME]["posts"].delete_many({"user_id": user_id})
    await mongo_client[DB_NAME]["comments"].delete_many({"user_id": user_id})
    return {"status": "deleted"}


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




# ── Community & CMS Pydantic Models ──────────────────────────────────────────
class LikeRequest(BaseModel):
    user_id: str

class ReportRequest(BaseModel):
    user_id: str

class PostCreate(BaseModel):
    user_id: str
    user_name: str
    content: str = Field(..., min_length=1, max_length=2000)
    topic: str = "Chung"

class CommentCreate(BaseModel):
    user_id: str
    user_name: str
    content: str = Field(..., min_length=1, max_length=500)

class SkillUpsert(BaseModel):
    admin_id: str
    title: str
    category: str = "Kỹ năng chung"
    description: str
    image_url: str = ""
    content: str
    duration_minutes: int = 5

class NewsUpsert(BaseModel):
    admin_id: str
    title: str
    summary: str
    content: str
    image_url: str = ""
    author: str = "Admin"

class FunUpsert(BaseModel):
    admin_id: str
    title: str
    type: str = "tip"
    media_url: str = ""
    content: str


# ── Helper ────────────────────────────────────────────────────────────────────
def _serialize_post(p: dict) -> dict:
    pid = p.get("_id")
    return {
        "id": str(pid) if pid else p.get("id", ""),
        "user_id": p.get("user_id", ""),
        "user_name": p.get("user_name", ""),
        "content": p.get("content", ""),
        "topic": p.get("topic", "Chung"),
        "likes": p.get("likes", []),
        "likes_count": p.get("likes_count", 0),
        "comments_count": p.get("comments_count", 0),
        "reported_by": p.get("reported_by", []),
        "created_at": p.get("created_at", ""),
        "is_pinned": p.get("is_pinned", False),
        "is_hidden": p.get("is_hidden", False),
    }

async def _check_admin(admin_id: str):
    col = mongo_client[DB_NAME]["users"]
    try:
        admin = await col.find_one({"_id": ObjectId(admin_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="admin_id không hợp lệ")
    if not admin or admin.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Không có quyền truy cập.")


# ── Community API ─────────────────────────────────────────────────────────────
@app.get("/api/community/posts")
async def get_posts(sort: str = "new"):
    col = mongo_client[DB_NAME]["posts"]
    sort_field = "likes_count" if sort == "hot" else "created_at"
    cursor = col.find({"is_hidden": {"$ne": True}}).sort(sort_field, -1)
    posts = await cursor.to_list(length=200)
    return [_serialize_post(p) for p in posts]

@app.post("/api/community/posts")
async def create_post(body: PostCreate):
    col = mongo_client[DB_NAME]["posts"]
    doc = {
        "user_id": body.user_id,
        "user_name": body.user_name,
        "content": body.content,
        "topic": body.topic,
        "likes": [],
        "likes_count": 0,
        "comments_count": 0,
        "reported_by": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_hidden": False,
        "is_pinned": False,
    }
    result = await col.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize_post(doc)

@app.post("/api/community/posts/{post_id}/like")
async def toggle_like(post_id: str, body: LikeRequest):
    col = mongo_client[DB_NAME]["posts"]
    post = await col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Bài đăng không tồn tại")
    likes = post.get("likes", [])
    if body.user_id in likes:
        likes.remove(body.user_id)
    else:
        likes.append(body.user_id)
    await col.update_one(
        {"_id": ObjectId(post_id)},
        {"$set": {"likes": likes, "likes_count": len(likes)}}
    )
    return {"liked": body.user_id in likes, "likes_count": len(likes)}

@app.post("/api/community/posts/{post_id}/report")
async def report_post(post_id: str, body: ReportRequest):
    col = mongo_client[DB_NAME]["posts"]
    post = await col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Bài đăng không tồn tại")
    reported = post.get("reported_by", [])
    if body.user_id not in reported:
        reported.append(body.user_id)
        await col.update_one({"_id": ObjectId(post_id)}, {"$set": {"reported_by": reported}})
    return {"status": "reported"}

@app.get("/api/community/posts/{post_id}/comments")
async def get_comments(post_id: str):
    col = mongo_client[DB_NAME]["comments"]
    cursor = col.find({"post_id": post_id}).sort("created_at", 1)
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

@app.post("/api/community/posts/{post_id}/comments")
async def add_comment(post_id: str, body: CommentCreate):
    posts_col = mongo_client[DB_NAME]["posts"]
    comments_col = mongo_client[DB_NAME]["comments"]
    
    try:
        obj_id = ObjectId(post_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Mã bài đăng không hợp lệ (không phải dạng chuẩn)")
        
    post = await posts_col.find_one({"_id": obj_id})
    if not post:
        raise HTTPException(status_code=404, detail="Bài đăng không tồn tại")
    doc = {
        "post_id": post_id,
        "user_id": body.user_id,
        "user_name": body.user_name,
        "content": body.content,
        "reported_by": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await comments_col.insert_one(doc)
    await posts_col.update_one({"_id": ObjectId(post_id)}, {"$inc": {"comments_count": 1}})
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}

@app.post("/api/community/comments/{comment_id}/report")
async def report_comment(comment_id: str, body: ReportRequest):
    col = mongo_client[DB_NAME]["comments"]
    comment = await col.find_one({"_id": ObjectId(comment_id)})
    if not comment:
        raise HTTPException(status_code=404, detail="Bình luận không tồn tại")
    reported = comment.get("reported_by", [])
    if body.user_id not in reported:
        reported.append(body.user_id)
        await col.update_one({"_id": ObjectId(comment_id)}, {"$set": {"reported_by": reported}})
    return {"status": "reported"}

@app.delete("/api/community/posts/{post_id}")
async def delete_post(post_id: str, admin_id: str):
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["posts"]
    await col.delete_one({"_id": ObjectId(post_id)})
    # Also delete comments of this post
    await mongo_client[DB_NAME]["comments"].delete_many({"post_id": post_id})
    return {"status": "deleted"}

@app.get("/api/admin/community/posts")
async def admin_get_posts(admin_id: str):
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["posts"]
    cursor = col.find().sort("created_at", -1)
    posts = await cursor.to_list(length=500)
    return [_serialize_post(p) for p in posts]

@app.post("/api/admin/community/posts/{post_id}/toggle_hide")
async def toggle_hide_post(post_id: str, admin_id: str):
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["posts"]
    post = await col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài đăng")
    new_hidden = not post.get("is_hidden", False)
    await col.update_one({"_id": ObjectId(post_id)}, {"$set": {"is_hidden": new_hidden}})
    return {"is_hidden": new_hidden}


# ── Admin Community — Comments ─────────────────────────────────────────────
@app.get("/api/admin/community/comments")
async def admin_get_all_comments(admin_id: str):
    """Lấy toàn bộ comments (có thông tin bài viết) cho admin moderation."""
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["comments"]
    cursor = col.find().sort("created_at", -1)
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


@app.delete("/api/admin/community/comments/{comment_id}")
async def admin_delete_comment(comment_id: str, admin_id: str):
    """Admin xóa một comment."""
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["comments"]
    try:
        comment = await col.find_one({"_id": ObjectId(comment_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="comment_id không hợp lệ")
    if not comment:
        raise HTTPException(status_code=404, detail="Không tìm thấy bình luận")
    await col.delete_one({"_id": ObjectId(comment_id)})
    # Giảm comments_count của bài viết
    post_id = comment.get("post_id")
    if post_id:
        await mongo_client[DB_NAME]["posts"].update_one(
            {"_id": ObjectId(post_id)}, {"$inc": {"comments_count": -1}}
        )
    return {"status": "deleted"}


# ── Admin Stats ───────────────────────────────────────────────────────────────
@app.get("/api/admin/stats")
async def get_admin_stats(admin_id: str):
    """Trả về thống kê tổng quan hệ thống cho admin dashboard."""
    await _check_admin(admin_id)
    db = mongo_client[DB_NAME]

    total_users   = await db.users.count_documents({})
    total_skills  = await db.skills.count_documents({})
    total_news    = await db.news.count_documents({})
    total_posts   = await db.posts.count_documents({})
    hidden_posts  = await db.posts.count_documents({"is_hidden": True})
    # Bài có ít nhất 1 báo cáo
    reported_posts = await db.posts.count_documents(
        {"reported_by": {"$exists": True, "$not": {"$size": 0}}}
    )

    return {
        "total_users":    total_users,
        "total_skills":   total_skills,
        "total_news":     total_news,
        "total_posts":    total_posts,
        "hidden_posts":   hidden_posts,
        "reported_posts": reported_posts,
    }


# ── Admin Upload — Image ──────────────────────────────────────────────────────
os.makedirs("static/skills", exist_ok=True)

@app.post("/api/admin/upload/image")
async def admin_upload_image(admin_id: str, file: UploadFile = File(...)):
    """Upload media (ảnh/video) cho kỹ năng/tin tức. Giới hạn 50MB."""
    await _check_admin(admin_id)
    MAX_SIZE = 50 * 1024 * 1024 # 50MB
    content = await file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(status_code=413, detail="File quá lớn, tối đa 50MB.")
    allowed_ext = {"jpg", "jpeg", "png", "webp", "gif", "mp4", "mov", "avi"}
    ext = (file.filename or "").rsplit(".", 1)[-1].lower()
    if ext not in allowed_ext:
        raise HTTPException(status_code=415, detail="Định dạng không hợp lệ. Dùng: jpg, png, webp, mp4, mov, avi.")
    filename = f"skill_{int(datetime.now(timezone.utc).timestamp())}_{admin_id[:8]}.{ext}"
    filepath = f"static/skills/{filename}"
    with open(filepath, "wb") as buffer:
        buffer.write(content)
    return {"image_url": f"/static/skills/{filename}"}


# ── Admin Skills — Categories ─────────────────────────────────────────────────
@app.get("/api/admin/skills/categories")
async def admin_get_skill_categories(admin_id: str):
    """Trả về danh sách các danh mục kỹ năng có trong hệ thống."""
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["skills"]
    categories = await col.distinct("category")
    result = []
    for cat in sorted(categories):
        count = await col.count_documents({"category": cat})
        result.append({"name": cat, "count": count})
    return result


# ── Admin CMS — Skills ────────────────────────────────────────────────────────
@app.post("/api/admin/skills")
async def create_skill(body: SkillUpsert):
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["skills"]
    doc = {
        "title": body.title, "category": body.category,
        "description": body.description, "image_url": body.image_url,
        "content": body.content, "duration_minutes": body.duration_minutes,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await col.insert_one(doc)
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}

@app.put("/api/admin/skills/{skill_id}")
async def update_skill(skill_id: str, body: SkillUpsert):
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["skills"]
    result = await col.update_one({"_id": ObjectId(skill_id)}, {"$set": {
        "title": body.title, "category": body.category,
        "description": body.description, "image_url": body.image_url,
        "content": body.content, "duration_minutes": body.duration_minutes,
    }})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy kỹ năng")
    return {"status": "updated"}

@app.delete("/api/admin/skills/{skill_id}")
async def delete_skill(skill_id: str, admin_id: str):
    await _check_admin(admin_id)
    await mongo_client[DB_NAME]["skills"].delete_one({"_id": ObjectId(skill_id)})
    return {"status": "deleted"}


# ── Admin CMS — News ──────────────────────────────────────────────────────────
@app.post("/api/admin/news")
async def create_news(body: NewsUpsert):
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["news"]
    doc = {
        "title": body.title, "summary": body.summary, "content": body.content,
        "image_url": body.image_url, "author": body.author,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await col.insert_one(doc)
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}

@app.put("/api/admin/news/{news_id}")
async def update_news(news_id: str, body: NewsUpsert):
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["news"]
    result = await col.update_one({"_id": ObjectId(news_id)}, {"$set": {
        "title": body.title, "summary": body.summary, "content": body.content,
        "image_url": body.image_url, "author": body.author,
    }})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy tin tức")
    return {"status": "updated"}

@app.delete("/api/admin/news/{news_id}")
async def delete_news(news_id: str, admin_id: str):
    await _check_admin(admin_id)
    await mongo_client[DB_NAME]["news"].delete_one({"_id": ObjectId(news_id)})
    return {"status": "deleted"}


# ── Admin CMS — Fun ───────────────────────────────────────────────────────────
@app.post("/api/admin/fun")
async def create_fun(body: FunUpsert):
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["fun"]
    doc = {
        "title": body.title, "type": body.type,
        "media_url": body.media_url, "content": body.content,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await col.insert_one(doc)
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}

@app.put("/api/admin/fun/{fun_id}")
async def update_fun(fun_id: str, body: FunUpsert):
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["fun"]
    result = await col.update_one({"_id": ObjectId(fun_id)}, {"$set": {
        "title": body.title, "type": body.type,
        "media_url": body.media_url, "content": body.content,
    }})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy nội dung")
    return {"status": "updated"}

@app.delete("/api/admin/fun/{fun_id}")
async def delete_fun(fun_id: str, admin_id: str):
    await _check_admin(admin_id)
    await mongo_client[DB_NAME]["fun"].delete_one({"_id": ObjectId(fun_id)})
    return {"status": "deleted"}

# ── AI Copilot API ────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    query: str
    user_id: str

@app.post("/api/ai/chat")
async def ai_chat(body: ChatRequest):
    prompt = f"""
Bạn là AI Life Skill Copilot - Trợ lý kỹ năng sống thông minh dành cho sinh viên Việt Nam.
Yêu cầu:
- NẾU câu hỏi KHÔNG LIÊN QUAN đến kỹ năng sống, học tập, môi trường làm việc hay tâm lý, BẮT BUỘC trả lời đúng 1 câu: "Tôi chỉ hỗ trợ các nội dung học tập có trong ứng dụng." (Closed-domain RAG). Không giải thích thêm.
- Nếu liên quan, trả lời ngắn gọn, rõ ràng, thực tiễn.
- Luôn phải Format bằng Markdown chính xác theo cấu trúc sau (không thay đổi Icon):
✅ **Tình huống:** [Phân tích ngắn 1 dòng]
⚠️ **Điều cần tránh:** [Lưu ý những sai lầm]
📌 **Các bước xử lý:**
- [Bước 1]
- ...
💡 **Lời khuyên thêm:** [Tip hay]

Câu hỏi của người dùng: {body.query}
"""
    try:
        model = genai.GenerativeModel('gemini-2.5-flash-lite')
        response = await model.generate_content_async(prompt)
        answer = response.text
        
        # Simple logical mapping
        query_lower = body.query.lower()
        search_keywords = []
        if any(w in query_lower for w in ["cháy", "lửa", "hỏa hoạn"]):
            search_keywords.extend(["cháy", "hỏa hoạn", "sơ cứu"])
        elif any(w in query_lower for w in ["máu", "cấp cứu", "thương", "ngất", "sơ cứu"]):
            search_keywords.extend(["sơ cứu", "máu", "ythương"])
        elif any(w in query_lower for w in ["tiền", "tài chính", "ngân hàng", "lừa đảo", "tiết kiệm", "chi tiêu"]):
            search_keywords.extend(["tài chính", "ngân hàng", "lừa đảo"])
        elif any(w in query_lower for w in ["giao tiếp", "thuyết trình", "căng thẳng", "stress", "tự tin", "đám đông"]):
            search_keywords.extend(["giao tiếp", "thuyết trình", "tự tin"])
        else:
            search_keywords.extend(query_lower.split()[:3]) # Fallback words
            
        related_skills = []
        if search_keywords:
            skills_col = mongo_client[DB_NAME]["skills"]
            regex_pattern = "|".join([k for k in search_keywords if len(k) > 2])
            if regex_pattern:
                cursor = skills_col.find({
                    "$or": [
                        {"title": {"$regex": regex_pattern, "$options": "i"}},
                        {"description": {"$regex": regex_pattern, "$options": "i"}}
                    ]
                }).limit(2)
                skills = await cursor.to_list(length=2)
                for s in skills:
                    related_skills.append({
                        "id": str(s["_id"]),
                        "title": s.get("title"),
                        "image_url": s.get("image_url"),
                        "category": s.get("category"),
                    })
        
        return {"answer": answer, "related_skills": related_skills}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ── PHASE 2: Exam System API ──────────────────────────────────────────────────
# Pydantic Models

class ExamSubmit(BaseModel):
    user_id: str
    round_id: int
    answers: list[dict]  # [{"question_id": "...", "selected": 0}, ...]


class ProgressUpdate(BaseModel):
    user_id: str
    round_id: int


# ─── Helper: Lấy / tạo mới UserExamProgress ───────────────────────────────────
async def _get_or_create_progress(user_id: str) -> dict:
    col = mongo_client[DB_NAME]["user_exam_progress"]
    doc = await col.find_one({"user_id": user_id})
    if not doc:
        doc = {
            "user_id": user_id,
            "current_round": 1,
            "total_exam_points": 0,
            "skill_stats": {
                "communication": 0,
                "emotion": 0,
                "finance": 0,
                "critical_thinking": 0,
                "teamwork": 0,
                "health": 0,
            },
            "completed_rounds": [],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        result = await col.insert_one(doc)
        doc["_id"] = result.inserted_id
    return doc


# ─── API: Lấy câu hỏi theo vòng ──────────────────────────────────────────────
@app.get("/api/exam/questions/{round_id}")
async def get_exam_questions(round_id: int):
    """Lấy ngẫu nhiên 5 câu hỏi thuộc vòng này (theo round_id)."""
    col = mongo_client[DB_NAME]["questions"]
    cursor = col.find({"round_id": round_id})
    questions = await cursor.to_list(length=100)

    if not questions:
        raise HTTPException(
            status_code=404,
            detail=f"Chưa có câu hỏi cho vòng {round_id}. Hãy seed data trước."
        )

    import random
    sampled = random.sample(questions, min(5, len(questions)))

    return [
        {
            "id": str(q["_id"]),
            "content": q.get("content", ""),
            "options": q.get("options", []),
            "skill_tag": q.get("skill_tag", ""),
            # KHÔNG trả về correct_answer để tránh gian lận
        }
        for q in sampled
    ]


# ─── API: Nộp bài & chấm điểm ────────────────────────────────────────────────
@app.post("/api/exam/submit")
async def submit_exam(body: ExamSubmit):
    """
    Chấm bài thi:
    - Kiểm tra đáp án, tính điểm theo câu đúng
    - Cập nhật skill_stats theo skill_tag của từng câu sai/đúng
    - Nâng current_round nếu đạt ≥ 60% (3/5 câu)
    - Trả về kết quả chi tiết cho Flutter hiển thị
    """
    q_col = mongo_client[DB_NAME]["questions"]
    progress_col = mongo_client[DB_NAME]["user_exam_progress"]

    # Lấy thông tin câu hỏi từ DB
    results = []
    correct_count = 0
    skill_delta: dict[str, int] = {}  # skill_tag -> điểm tích lũy

    for ans in body.answers:
        try:
            q = await q_col.find_one({"_id": ObjectId(ans["question_id"])})
        except Exception:
            continue
        if not q:
            continue

        is_correct = ans.get("selected") == q.get("correct_answer")
        skill_tag = q.get("skill_tag", "communication")

        if is_correct:
            correct_count += 1
            skill_delta[skill_tag] = skill_delta.get(skill_tag, 0) + 10
        else:
            skill_delta[skill_tag] = skill_delta.get(skill_tag, 0) - 5

        results.append({
            "question_id": ans["question_id"],
            "content": q.get("content", ""),
            "selected": ans.get("selected"),
            "correct_answer": q.get("correct_answer"),
            "is_correct": is_correct,
            "skill_tag": skill_tag,
            "explanation": q.get("explanation", ""),
        })

    total_questions = len(results)
    passed = correct_count >= max(1, total_questions * 0.6)  # ≥ 60% để vượt vòng
    points_earned = correct_count * 20  # 20 điểm / câu đúng

    # ── Cập nhật tiến độ user ──
    progress = await _get_or_create_progress(body.user_id)
    current_round = progress.get("current_round", 1)
    completed_rounds = progress.get("completed_rounds", [])

    # Cập nhật skill_stats
    new_skill_stats = dict(progress.get("skill_stats", {}))
    for tag, delta in skill_delta.items():
        new_skill_stats[tag] = max(0, new_skill_stats.get(tag, 0) + delta)

    # Nâng vòng nếu pass và chưa vượt vòng này
    if passed and body.round_id not in completed_rounds:
        completed_rounds.append(body.round_id)
        new_round = max(current_round, body.round_id + 1)
    else:
        new_round = current_round

    await progress_col.update_one(
        {"user_id": body.user_id},
        {
            "$set": {
                "current_round": new_round,
                "skill_stats": new_skill_stats,
                "completed_rounds": completed_rounds,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            },
            "$inc": {"total_exam_points": points_earned},
        },
        upsert=True,
    )

    return {
        "passed": passed,
        "correct_count": correct_count,
        "total_questions": total_questions,
        "points_earned": points_earned,
        "new_round": new_round,
        "skill_stats": new_skill_stats,
        "results": results,
    }


# ─── API: Lấy tiến độ user trên Map ──────────────────────────────────────────
@app.get("/api/exam/progress/{user_id}")
async def get_exam_progress(user_id: str):
    """Lấy current_round, skill_stats, total_points của user để hiển thị Map."""
    progress = await _get_or_create_progress(user_id)
    return {
        "current_round": progress.get("current_round", 1),
        "total_exam_points": progress.get("total_exam_points", 0),
        "skill_stats": progress.get("skill_stats", {}),
        "completed_rounds": progress.get("completed_rounds", []),
    }


# ─── API: Admin seed câu hỏi mẫu ─────────────────────────────────────────────
class QuestionCreate(BaseModel):
    admin_id: str
    round_id: int
    content: str
    options: list[str]          # 4 đáp án, ví dụ ["A. ...", "B. ...", "C. ...", "D. ..."]
    correct_answer: int          # index 0-3
    skill_tag: str               # "communication" | "emotion" | "finance" | ...
    explanation: str = ""


@app.post("/api/admin/exam/questions")
async def create_question(body: QuestionCreate):
    """Admin thêm câu hỏi mới vào ngân hàng đề."""
    await _check_admin(body.admin_id)
    col = mongo_client[DB_NAME]["questions"]
    doc = {
        "round_id": body.round_id,
        "content": body.content,
        "options": body.options,
        "correct_answer": body.correct_answer,
        "skill_tag": body.skill_tag,
        "explanation": body.explanation,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await col.insert_one(doc)
    return {"id": str(result.inserted_id), **doc}


@app.get("/api/admin/exam/questions")
async def list_all_questions(admin_id: str):
    """Admin xem toàn bộ ngân hàng đề."""
    await _check_admin(admin_id)
    col = mongo_client[DB_NAME]["questions"]
    cursor = col.find().sort("round_id", 1)
    questions = await cursor.to_list(length=1000)
    return [
        {
            "id": str(q["_id"]),
            "round_id": q.get("round_id"),
            "content": q.get("content", ""),
            "options": q.get("options", []),
            "correct_answer": q.get("correct_answer"),
            "skill_tag": q.get("skill_tag", ""),
            "explanation": q.get("explanation", ""),
        }
        for q in questions
    ]


# ── PHASE 3: AI Personalized Learning Path ────────────────────────────────────

# Tên kỹ năng tiếng Việt để AI đọc hiểu
_SKILL_TAG_VI = {
    "communication":     "Kỹ năng Giao Tiếp",
    "emotion":           "Quản lý Cảm Xúc",
    "finance":           "Quản lý Tài Chính",
    "critical_thinking": "Tư Duy Phản Biện & Quản Lý Thời Gian",
    "teamwork":          "Làm Việc Nhóm",
    "health":            "Sức Khỏe & Thể Chất",
}

# Map label → vòng học tương ứng để AI gợi ý ôn lại
_SKILL_TAG_ROUND = {
    "communication":     [1, 2],
    "emotion":           [2, 3],
    "finance":           [9],
    "critical_thinking": [4, 5],
    "teamwork":          [7],
    "health":            [10],
}


class RecommendRequest(BaseModel):
    user_id: str
    round_id: int           # Vòng vừa thi xong
    correct_count: int
    total_questions: int
    skill_stats: dict       # Kết quả skill_stats hiện tại (sau cập nhật)
    passed: bool


@app.post("/api/ai/recommend-path")
async def ai_recommend_path(body: RecommendRequest):
    """
    Phase 3: AI Gemini phân tích kết quả thi cụ thể của user và đưa ra:
    - Nhận xét điểm mạnh / yếu theo skill_tag
    - Gợi ý vòng tiếp theo / ôn lại
    - Lời động viên cá nhân hóa
    """
    # ── Xây dựng bảng phân tích skill ──
    skill_lines = []
    weak_skills = []
    strong_skills = []

    for tag, score in body.skill_stats.items():
        vi_name = _SKILL_TAG_VI.get(tag, tag)
        score_int = int(score)
        if score_int > 0:
            skill_lines.append(f"  - {vi_name}: {score_int} điểm")
            if score_int >= 20:
                strong_skills.append(vi_name)
            elif score_int < 10:
                weak_skills.append(vi_name)

    skill_summary = "\n".join(skill_lines) if skill_lines else "  - Chưa có dữ liệu"
    weak_str = ", ".join(weak_skills) if weak_skills else "không có"
    strong_str = ", ".join(strong_skills) if strong_skills else "đang phát triển"

    status = "PASSED - Vượt vòng thành công" if body.passed else "FAILED - Chưa đạt yêu cầu"
    accuracy = round(body.correct_count / max(body.total_questions, 1) * 100)

    prompt = f"""Bạn là AI Mentor kỹ năng sống thông minh tên "Owl" (Cú Học Thuật) trong ứng dụng giáo dục Kỹ Năng Sống 4.0.

DỮ LIỆU HỌC VIÊN vừa hoàn thành Vòng {body.round_id}:
- Kết quả: {status}
- Điểm chính xác: {body.correct_count}/{body.total_questions} câu ({accuracy}%)
- Điểm mạnh: {strong_str}
- Điểm cần cải thiện: {weak_str}
- Bảng điểm kỹ năng tích lũy:
{skill_summary}

NHIỆM VỤ: Viết phân tích ngắn (3-4 câu) theo đúng format sau. KHÔNG thêm bất kỳ text nào ngoài format:

🦉 **Nhận xét:** [1 câu nhận xét thẳng thắn về kết quả vừa thi - có dữ liệu cụ thể]
💪 **Điểm mạnh:** [1 câu khen ngợi kỹ năng tốt nhất]
🎯 **Cần cải thiện:** [1 câu chỉ ra kỹ năng yếu nhất và lý do cần luyện]
🚀 **Gợi ý tiếp theo:** [1 câu cụ thể về vòng nên tập trung hoặc ôn lại]

Giọng điệu: Thân thiện như người mentor, động viên nhưng thực tế. Dùng tiếng Việt tự nhiên."""

    try:
        model = genai.GenerativeModel('gemini-2.5-flash-lite')
        response = await model.generate_content_async(prompt)
        advice = response.text.strip()

        # Ghi nhận vào lịch sử AI (để Copilot biết context)
        history_col = mongo_client[DB_NAME]["ai_recommendations"]
        await history_col.insert_one({
            "user_id": body.user_id,
            "round_id": body.round_id,
            "passed": body.passed,
            "accuracy": accuracy,
            "skill_stats": body.skill_stats,
            "ai_advice": advice,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })

        return {
            "advice": advice,
            "weak_skills": weak_skills,
            "strong_skills": strong_skills,
            "accuracy": accuracy,
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ── Nâng cấp AI Chat: Context-Aware với tiến độ học ─────────────────────────
class ContextChatRequest(BaseModel):
    query: str
    user_id: str
    include_progress: bool = True   # Có đưa skill_stats vào context không


@app.post("/api/ai/context-chat")
async def ai_context_chat(body: ContextChatRequest):
    """
    Phase 3: AI Chat nâng cao — tự động load skill_stats và lịch sử gần nhất
    để trả lời cá nhân hóa hơn.
    """
    context_block = ""

    if body.include_progress:
        try:
            # Load exam progress
            progress = await _get_or_create_progress(body.user_id)
            skill_stats = progress.get("skill_stats", {})
            current_round = progress.get("current_round", 1)
            total_points = progress.get("total_exam_points", 0)

            # Tìm kỹ năng yếu nhất (điểm thấp nhất trong số có dữ liệu)
            active_skills = {k: v for k, v in skill_stats.items() if v > 0}
            if active_skills:
                weakest_tag = min(active_skills, key=lambda k: active_skills[k])
                weakest_name = _SKILL_TAG_VI.get(weakest_tag, weakest_tag)
            else:
                weakest_name = "chưa xác định"

            # Load lời khuyên AI gần nhất
            hist_col = mongo_client[DB_NAME]["ai_recommendations"]
            last_rec = await hist_col.find_one(
                {"user_id": body.user_id},
                sort=[("created_at", -1)]
            )
            last_advice_summary = ""
            if last_rec:
                last_advice_summary = (
                    f"\nLần thi gần nhất: Vòng {last_rec.get('round_id', '?')}, "
                    f"đạt {last_rec.get('accuracy', 0)}%."
                )

            skill_desc_parts = []
            for tag, score in skill_stats.items():
                if score > 0:
                    skill_desc_parts.append(f"{_SKILL_TAG_VI.get(tag, tag)}: {int(score)}đ")

            skill_desc = ", ".join(skill_desc_parts) if skill_desc_parts else "chưa có dữ liệu thi"

            context_block = f"""
[THÔNG TIN HỌC VIÊN - Dùng để cá nhân hóa câu trả lời]:
- Đang ở Vòng {current_round} trên bản đồ kỹ năng (tổng 16 vòng)
- Tổng điểm tích lũy: {total_points} XP
- Bảng kỹ năng: {skill_desc}
- Kỹ năng cần ưu tiên cải thiện: {weakest_name}{last_advice_summary}
[Hãy tự nhiên đề cập đến dữ liệu này nếu phù hợp, không đọc nguyên văn]
"""
        except Exception:
            pass  # Nếu lỗi load progress, vẫn tiếp tục chat bình thường

    prompt = f"""Bạn là AI Life Skill Copilot "Owl" - Trợ lý kỹ năng sống thông minh dành cho sinh viên Việt Nam.
{context_block}
Yêu cầu trả lời:
- NẾU câu hỏi KHÔNG LIÊN QUAN đến kỹ năng sống, tâm lý, học tập, BẮT BUỘC trả lời đúng 1 câu: "Tôi chỉ hỗ trợ các nội dung học tập có trong ứng dụng." (Closed-domain RAG).
- Nếu liên quan: Ngắn gọn, rõ ràng, thực tiễn (không quá 200 từ) và Cá nhân hóa theo dữ liệu học viên.
- Format Markdown chính xác:
✅ **Tình huống:** [Phân tích ngắn 1 dòng]
⚠️ **Điều cần tránh:** [Lưu ý những sai lầm]
📌 **Các bước xử lý:**
- [Bước 1]
- ...
💡 **Lời khuyên thêm:** [Tip hay, nếu liên quan đến kỹ năng đang yếu của user thì đề cập]

Câu hỏi: {body.query}"""

    try:
        model = genai.GenerativeModel('gemini-2.5-flash-lite')
        response = await model.generate_content_async(prompt)
        answer = response.text

        # Tìm skill liên quan trong DB
        query_lower = body.query.lower()
        search_keywords = []
        if any(w in query_lower for w in ["cháy", "lửa", "hỏa hoạn"]):
            search_keywords.extend(["cháy", "hỏa hoạn", "sơ cứu"])
        elif any(w in query_lower for w in ["máu", "cấp cứu", "thương", "ngất", "sơ cứu"]):
            search_keywords.extend(["sơ cứu", "máu"])
        elif any(w in query_lower for w in ["tiền", "tài chính", "ngân hàng", "lừa đảo", "tiết kiệm"]):
            search_keywords.extend(["tài chính", "ngân hàng"])
        elif any(w in query_lower for w in ["giao tiếp", "thuyết trình", "căng thẳng", "stress", "tự tin"]):
            search_keywords.extend(["giao tiếp", "thuyết trình"])
        else:
            search_keywords.extend(query_lower.split()[:3])

        related_skills = []
        if search_keywords:
            skills_col = mongo_client[DB_NAME]["skills"]
            regex_pattern = "|".join([k for k in search_keywords if len(k) > 2])
            if regex_pattern:
                cursor = skills_col.find({
                    "$or": [
                        {"title": {"$regex": regex_pattern, "$options": "i"}},
                        {"description": {"$regex": regex_pattern, "$options": "i"}}
                    ]
                }).limit(2)
                skills = await cursor.to_list(length=2)
                for s in skills:
                    related_skills.append({
                        "id": str(s["_id"]),
                        "title": s.get("title"),
                        "image_url": s.get("image_url"),
                        "category": s.get("category"),
                    })

        return {"answer": answer, "related_skills": related_skills}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ── PHASE 4: SKILL PAGE LEARNING FLOW (SCORM & RAG) ─────────────────────────

class ProgressUpdate(BaseModel):
    user_id: str
    lesson_id: str
    progress: float  # 10% -> 10.0, 50% -> 50.0, 100% -> 100.0
    status: str      # "in_progress", "completed"
    score: Optional[int] = 0
    time_spent: Optional[int] = 0



class QuizSubmit(BaseModel):
    user_id: str
    lesson_id: str
    answers: list[dict]
    

@app.get("/api/ai/recommendation/{user_id}")
async def get_ai_recommendation(user_id: str):
    """Explainable AI Recommendation"""
    try:
        # Load progress đã hoàn thành
        prog_col = mongo_client[DB_NAME]["learning_progress"]
        cursor = prog_col.find({"user_id": user_id, "status": "completed"})
        completed_lessons = await cursor.to_list(length=100)
        
        lesson_ids = [ls["lesson_id"] for ls in completed_lessons]
        
        history_text = "Kỹ năng cần ôn: "
        if lesson_ids:
            # Lấy title từ lesson
            less_col = mongo_client[DB_NAME]["lessons"]
            # Convert str ids to ObjectIds
            obj_ids = []
            for lid in lesson_ids:
                try:
                    obj_ids.append(ObjectId(lid))
                except:
                    pass
            cursor_lessons = less_col.find({"_id": {"$in": obj_ids}})
            lessons_info = await cursor_lessons.to_list(length=100)
            learned_titles = [l.get("title", "") for l in lessons_info]
            if learned_titles:
                history_text = "Học viên này vừa hoàn thành chuỗi bài: " + ", ".join(learned_titles)
            else:
                history_text = "Học viên này có tương tác nhưng chưa lưu vết tên kỹ năng rõ ràng."
        else:
            history_text = "Học viên này là người mới, chưa hoàn thành kỹ năng nào."
            
        prompt = f"""
Bạn là một Mentor AI tên Owl của ứng dụng Kỹ Năng Sống 4.0.
Nhiệm vụ của bạn là đưa ra Gợi ý bài học cá nhân hóa cho học viên (Explainable AI Recommendation).
Lịch sử người dùng: {history_text}

Hãy đưa ra 1 kỹ năng hoặc bài học quan trọng nhất người dùng nên học trong ứng dụng Kỹ Năng Sống tiếp theo.
Giải thích logic theo mô hình "Explainable AI" dựa trên những gì họ đã học (hoặc chưa học). Ví dụ: Đã học giao tiếp cơ bản thì gợi ý Giao tiếp đám đông.
Lưu ý:
- Trình bày dạng Markdown với 2 dòng duy nhất, có Icon y hệt như sau:
🎯 **Đề Xuất**: [Tên Kỹ năng]
💡 **Lý do**: [Giải thích thuyết phục 1 dòng tại sao đề xuất kỹ năng này dựa vào dữ liệu trên]
"""
        model = genai.GenerativeModel('gemini-2.5-flash-lite')
        response = await model.generate_content_async(prompt)
        advice = response.text.strip()
        return {"recommendation_text": advice}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ── REGISTER EXTRACTED ROUTERS ──────────────────────────────────────────────
from routers.auth_router import router as auth_router
from routers.news_router import router as news_router
from routers.lesson_router import router as lesson_router

app.include_router(auth_router)
app.include_router(news_router)
app.include_router(lesson_router)
